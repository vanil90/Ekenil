#version 120
/*
                            _____ _____ ___________
                           /  ___|_   _|  _  | ___ \
                           \ `--.  | | | | | | |_/ /
                            `--. \ | | | | | |  __/
                           /\__/ / | | \ \_/ / |
                           \____/  \_/  \___/\_|
This code is from Chocapic13' shaders v6.2, modified, tweaked and changed by Sildur for vibrant shaders v1.15 and newer.
						Before editing anything here make sure you've
						read The agreement, which you accepted by downloading
						my shaderpack. The agreement can be found here:
			http://www.minecraftforum.net/topic/1953873-164-172-sildurs-shaders-pcmacintel/

*/

#define Waving_Water

varying vec4 color;
varying vec2 texcoord;
varying vec2 lmcoord;

varying vec4 ambientNdotL;
varying vec4 sunlightMat;
varying vec4 transparentBlocks;

varying vec3 normal;
varying mat3 tbnMatrix;

attribute vec4 mc_Entity;
attribute vec4 at_tangent;                      //xyz = tangent vector, w = handedness, added in 1.7.10

uniform vec3 cameraPosition;
uniform vec3 sunPosition;
uniform vec3 upPosition;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform int worldTime;
uniform float rainStrength;

uniform float frameTimeCounter;
const float PI = 3.1415927;

const vec3 ToD[7] = vec3[7](  vec3(1.0,0.15,0.02),
								vec3(1.0,0.35,0.09),
								vec3(1.0,0.5,0.26),
								vec3(1.0,0.5,0.35),
								vec3(1.0,0.5,0.36),
								vec3(1.0,0.5,0.37),
								vec3(1.0,0.5,0.38));

void main() {

	normal = normalize(gl_NormalMatrix * normalize(gl_Normal));
	vec4 position = gl_ModelViewMatrix * gl_Vertex;
	position = gbufferModelViewInverse * position;
	vec3 worldpos = position.xyz + cameraPosition;

	ambientNdotL.a = 0.0; //iswater
	transparentBlocks.a = 0.0; //istransparent
	
	if(mc_Entity.x == 8.0 || mc_Entity.x == 9.0) {
		ambientNdotL.a = 1.0;
		
		#ifdef Waving_Water
		float fy = fract(worldpos.y + 0.001);
		float wave = 0.05 * sin(2 * PI * (frameTimeCounter*0.75 + worldpos.x /  7.0 + worldpos.z / 13.0))
				   + 0.05 * sin(2 * PI * (frameTimeCounter*0.6 + worldpos.x / 11.0 + worldpos.z /  5.0));
		position.y += clamp(wave, -fy, 1.0-fy)*0.6-0.01;
		#endif
	}

	if(mc_Entity.x == 79.0)ambientNdotL.a = 0.5;
	/*--------------------------------------------*/
	
	color = gl_Color;
	position = gbufferModelView * position;
	gl_Position = gl_ProjectionMatrix * position;

	texcoord = (gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	/*-----------------------------------------------------*/

	//reduced the sun color to a 7 array
	float hour = max(mod(worldTime/1000.0+2.0,24.0)-2.0,0.0);  //-0.1
	float cmpH = max(-abs(floor(hour)-6.0)+6.0,0.0); //12
	float cmpH1 = max(-abs(floor(hour)-5.0)+6.0,0.0); //1
	vec3 temp = ToD[int(cmpH)];
	vec3 temp2 = ToD[int(cmpH1)];

	//Colors
	vec3 sunlight = mix(temp,temp2,fract(hour));
	const vec3 rainC = vec3(0.01,0.01,0.01);
	sunlight = mix(sunlight,rainC*sunlight,rainStrength);

	vec3 sunVec = normalize(sunPosition);
	vec3 upVec = normalize(upPosition);

	vec2 visibility = vec2(dot(sunVec,upVec),dot(-sunVec,upVec));
	visibility = pow(clamp(visibility+0.15,0.0,0.15)/0.15,vec2(4.0));

	float NdotL = dot(normal,normalize(sunPosition));
	float NdotU = dot(normal,upVec);

	vec2 trCalc = min(abs(worldTime-vec2(23250.0,12700.0)),750.0);
	float tr = max(min(trCalc.x,trCalc.y)/375.0-1.0,0.0);

	float skyL = max(lmcoord.t-2./16.0,0.0)*1.14285714286;
	float SkyL2 = skyL*skyL;
	float skyc2 = mix(1.0,SkyL2,skyL);

	vec4 bounced = vec4(NdotL,NdotL,NdotL,NdotU) * vec4(-0.15*skyL*skyL,0.34,0.7,0.14) + vec4(0.6,0.66,0.7,0.23);
	bounced *= vec4(skyc2,skyc2,visibility.x-tr*visibility.x,0.8);

	vec3 sun_ambient = bounced.w * (vec3(0.08, 0.35, 1.0)+rainStrength*vec3(0.05,-0.2,-0.8))*2.4+ 1.45*sunlight*(sqrt(bounced.w)*bounced.x*2.4 + bounced.z)*(1.0-rainStrength*0.98);
	const vec3 moonlight = vec3(0.0002, 0.00036, 0.00075);
	vec3 moon_ambient = (moonlight*0.7 + moonlight*bounced.y)*(1.0-rainStrength*0.95)*4.0;

	vec3 LightC = mix(sunlight,moonlight,visibility.y)*tr*(1.0-rainStrength*0.99);
	vec3 amb1 = (sun_ambient*visibility.x + moon_ambient*visibility.y)*SkyL2*(0.03+tr*0.17)*0.65;
	
	ambientNdotL.rgb =  amb1 + vec3(0.002,0.002,0.002)*min(skyL+6/16.,9/16.)*normalize(amb1+0.0001)*2.0;
	if(mc_Entity.x == 165.0)ambientNdotL.rgb *= vec3(0.25, 1.25, 0.5)*min(skyL+6/16.,9/16.);	//fix slimeblocks color
	
	sunlight = mix(sunlight,moonlight*(1.0-rainStrength*0.9),visibility.y)*tr;
	sunlightMat = vec4(sunlight*0.9,0.0);
	/*--------------------------------------------------------------------------*/

	//Ice					  Stained Glass		 	 Stained Glass Plane	 Nether Portal		    Slimeblock
	if(mc_Entity.x == 79.0 || mc_Entity.x == 95.0 || mc_Entity.x == 160.0 || mc_Entity.x == 90.0 || mc_Entity.x == 165.0){
		ambientNdotL.rgb *= 1.75;	//normalize colors
		transparentBlocks.a = 1.0;
	}	
	
	vec3 tangent = normalize(gl_NormalMatrix * at_tangent.xyz);
	vec3 binormal = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);
	tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
					 tangent.y, binormal.y, normal.y,
					 tangent.z, binormal.z, normal.z);
}
