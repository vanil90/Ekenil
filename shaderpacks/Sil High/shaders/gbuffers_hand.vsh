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

varying vec4 texcoord;

varying vec4 color;
varying vec4 ambientNdotL;
varying vec4 sunlightMat;

varying vec3 normal;

uniform vec3 sunPosition;
uniform vec3 upPosition;

uniform int worldTime;
uniform float rainStrength;

varying float handItemLight;
uniform int heldItemId;

const vec3 ToD[7] = vec3[7](  vec3(0.58597,0.15,0.02),
								vec3(0.58597,0.35,0.09),
								vec3(0.58597,0.5,0.26),
								vec3(0.58597,0.5,0.35),
								vec3(0.58597,0.5,0.36),
								vec3(0.58597,0.5,0.37),
								vec3(0.58597,0.5,0.38));
								
/* If you reached this line, then you're probably about to break the agreement which you accepted by downloading Sildur's shaders!
So stop your doing and ask Sildur before copying anything which would break the agreement, unless you're Chocapic then go ahead ;)
--------------------------------------------------------------------------------------------------------------------------------*/ 

void main() {

	//Positioning
	color = gl_Color;
	gl_Position = ftransform();
	
	texcoord = vec4((gl_MultiTexCoord0).xy,(gl_TextureMatrix[1] * gl_MultiTexCoord1).xy);
	vec2 lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	/*-------------------------*/
	
	//reduced the sun color to a 7 array
	float hour = max(mod(worldTime/1000.0+2.0,24.0)-2.0,0.0);  //-0.1
	float cmpH = max(-abs(floor(hour)-6.0)+6.0,0.0); //12
	float cmpH1 = max(-abs(floor(hour)-5.0)+6.0,0.0); //1
	
	vec3 temp = ToD[int(cmpH)];
	vec3 temp2 = ToD[int(cmpH1)];
	
	vec3 sunlight = mix(temp,temp2,fract(hour));
	const vec3 rainC = vec3(0.01,0.01,0.01);
	sunlight = mix(sunlight,rainC*sunlight,rainStrength);
	/*----------------------------------------------------*/

	//Handheld Items casting light
	handItemLight = 0.0;
	if(heldItemId == 50.0						//Torch
	|| heldItemId == 10.0 						//flowing lava
	|| heldItemId == 11.0 						//still lava
	|| heldItemId == 51.0 						//fire
	|| heldItemId == 89.0 						//glowstone
	|| heldItemId == 91.0 						//jack o'lantern
	|| heldItemId == 138.0 						//beacon
	|| heldItemId == 169.0)handItemLight = 0.5; //sea lantern
	else if(heldItemId == 76.0					//active redstone torch
	|| heldItemId == 94.0 						//redstone repeater
	|| heldItemId == 327.0)handItemLight = 0.1; //lava bucket
	
	//Emissive blocks lighting
	float modlmap = 16.5-min(lmcoord.s*16.,14.5); 
	float torch_lightmap = 1.0/modlmap/modlmap-0.00390625;	
	vec3 emissiveLightColor = (vec3(1.68, 0.52, 0.22)*(torch_lightmap)*2.05)+handItemLight/20;	
	/*-------------------------------------------------------------------------------------*/
	
	//Sun/moon position
	vec3 sunVec = normalize(sunPosition);
	vec3 upVec = normalize(upPosition);

	vec2 visibility = vec2(dot(sunVec,upVec),dot(-sunVec,upVec));

	float NdotL = dot(normal,normalize(sunPosition));
	float NdotU = dot(normal,upVec);

	vec2 trCalc = min(abs(worldTime-vec2(23250.0,12700.0)),750.0);
	float tr = max(min(trCalc.x,trCalc.y)/375.0-1.0,0.0);
	visibility = pow(clamp(visibility+0.15,0.0,0.15)/0.15,vec2(4.0));
	/*-------------------------------------------------------------------*/
	
	//Lighting
	float skyL = max(lmcoord.t-2./16.0,0.0)*1.14285714286;	
	float SkyL2 = skyL*skyL;
	float skyc2 = mix(1.0,SkyL2,skyL);
	
	vec4 bounced = vec4(NdotL,NdotL,NdotL,NdotU) * vec4(-0.15*skyL*skyL,0.34,0.7,0.14) + vec4(0.6,0.66,0.7,0.23);
	bounced *= vec4(skyc2,skyc2,visibility.x-tr*visibility.x,0.8);
	
	vec3 sun_ambient = bounced.w * (vec3(0.08, 0.35, 1.0)+rainStrength*vec3(0.05,-0.2,-0.8))*2.4+ 1.45*sunlight*(sqrt(bounced.w)*bounced.x*2.4 + bounced.z)*(1.0-rainStrength*0.98);
	const vec3 moonlight = vec3(0.0002, 0.00036, 0.00075);
	vec3 moon_ambient = (moonlight*0.7 + moonlight*bounced.y)*(1.0-rainStrength*0.95)*4.0;
	
	vec3 amb1 = (sun_ambient*visibility.x + moon_ambient*visibility.y)*SkyL2*(0.03+tr*0.17)*0.65;
	ambientNdotL.rgb =  amb1 + emissiveLightColor + vec3(0.002,0.002,0.002)*min(skyL+6/16.,9/16.)*normalize(amb1+0.0001)*2.0;
	
	sunlightMat = vec4(vec3(1.0)*0.9,0.0);
	/*-------------------------------------------*/
	
	normal = normalize(gl_NormalMatrix * normalize(gl_Normal));

}