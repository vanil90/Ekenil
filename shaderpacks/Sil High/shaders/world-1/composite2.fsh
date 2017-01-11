#version 120
#extension GL_ARB_shader_texture_lod : enable
const bool gdepthMipmapEnabled = true;
/* DRAWBUFFERS:3 */
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

varying vec2 texcoord;

uniform sampler2D gdepth;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D gaux3;
uniform sampler2D gaux2;

uniform vec3 cameraPosition;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

uniform int worldTime;
uniform float rainStrength;

uniform float near;
uniform float far;
float comp = 1.0-near/far/far;

float tmult = mix(min(abs(worldTime-6000.0)/6000.0,1.0),1.0,rainStrength);

vec3 getcolor(vec2 coord, float lod){
	return pow(texture2DLod(gdepth, coord, lod).xyz,vec3(2.2))*257.0;
}

//Create fog
float getAirDensity (float h) {
	return (max((h),60.0))/10.;
}

float calcFog(vec3 fposition) {
	const float density = 150.0;

	vec3 worldpos = (gbufferModelViewInverse*vec4(fposition,1.0)).rgb+cameraPosition;
	float height = mix(getAirDensity(worldpos.y),6.,rainStrength*1.0);
	float d = length(fposition);

	return clamp(0.75/exp(-6.0/density)*exp(-getAirDensity(cameraPosition.y)/density) * (1.0-exp( -pow(d,2.712)*height/density/(6000.0-tmult*tmult*2000.0)/13.0*(1.0+rainStrength*1.0)))/height,0.0,1.0);
}/*---------------------------------*/

/* If you reached this line, then you're probably about to break the agreement which you accepted by downloading Sildur's shaders!
So stop your doing and ask Sildur before copying anything which would break the agreement, unless you're Chocapic then go ahead ;)
--------------------------------------------------------------------------------------------------------------------------------*/

void main() {

vec3 c = getcolor(texcoord, 0); 

//Depth and fragpos
float depth0 = texture2D(depthtex0, texcoord).x; //to prevent sky from breaking tranparent blocks
float depth1 = texture2D(depthtex1, texcoord).x;	
vec4 fragpos1 = gbufferProjectionInverse * (vec4(texcoord, depth1, 1.0) * 2.0 - 1.0);
fragpos1 /= fragpos1.w;
/*--------------------------------------------------------------------------------------------*/	
	
//Draw Fog
vec3 fogColor = vec3(0.5, 0.0, 0.0); //modified color for nether
float fogLand = calcFog(fragpos1.xyz);
c = mix(c, fogColor, fogLand);
/*-------------------------------*/

if (depth0 < comp){ //is land
	vec4 trp = texture2D(gaux3,texcoord.xy);
	bool transparency = dot(trp,trp) > 0.0;	
	
	if (transparency) {	
		//Draw transparency
		vec4 alpha = vec4(2.2,2.2,2.2,1.0);
		vec4 finalAc = pow(texture2D(gaux2,texcoord.xy), alpha);
		float alphaT = clamp(length(trp.rgb),0.0,1.0);
		vec4 rawAlbedo = pow(trp, alpha);

		c = mix(c,c*(rawAlbedo.rgb*0.9999+0.0001)*sqrt(3.0),alphaT)*(1.0-alphaT) + finalAc.rgb;
	}
}

	gl_FragData[0] = vec4(pow(c/257.0,vec3(0.454)), 1.0);
}