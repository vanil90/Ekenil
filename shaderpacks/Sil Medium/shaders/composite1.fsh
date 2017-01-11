#version 120
#extension GL_ARB_shader_texture_lod : enable
/* DRAWBUFFERS:1 */
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

/*--------------------
//ADJUSTABLE VARIABLES//
---------------------*/

#define Shadows								//Enable or disable shadows
#define ColoredShadows						//Enable or disable colored shadows
const int shadowMapResolution = 1024;		//Shadows resolution. [512 1024 2048 3072 4096 8192]
const float shadowDistance = 90;			//Draw distance of shadows.[60 90 120 150 180 210]

//#define SSDO								//Ambient Occlusion, makes lighting more realistic. High performance impact.

//#define Celshading						//Cel shades everything, making it look somewhat like Borderlands. Zero performance impact.
	#define BORDER 1.0

//#define Whiteworld						//Makes the ground white, screenshot -> https://i.imgur.com/xziUB8O.png

#define Moonlight 0.009						//[0.0015 0.003 0.006 0.009 0.012 0.015 0.018]

#define Bloom								//Adjust brightness of emissive blocks depending on bloom state
/*---------------------------
//END OF ADJUSTABLE VARIABLES//
----------------------------*/	

//Constants
const bool 	shadowHardwareFiltering0 = true;
const float	sunPathRotation	= -40.0f;
#define SHADOW_MAP_BIAS 0.80
/*--------------------------------*/

varying vec2 texcoord;
varying vec3 sunVec;
varying vec3 upVec;
varying vec3 sunlight;

varying float tr;
varying float sunVisibility;
varying float moonVisibility;
varying float handItemLight;

uniform sampler2D depthtex1;
uniform sampler2D gcolor;
uniform sampler2D gdepth;
uniform sampler2D gnormal;
uniform sampler2D composite;

uniform sampler2DShadow shadow;
uniform sampler2D shadowtex1; 
uniform sampler2D shadowcolor0;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform int isEyeInWater;
uniform int worldTime;
uniform float aspectRatio;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform float near;
uniform float far;
float comp = 1.0-near/far/far;

uniform ivec2 eyeBrightness;
float getlight = (eyeBrightness.y / 255.0);

//for shadows and ambient occlusion
const vec2 check_offsets[25] = vec2[25](vec2(-0.4894566f,-0.3586783f),
									vec2(-0.1717194f,0.6272162f),
									vec2(-0.4709477f,-0.01774091f),
									vec2(-0.9910634f,0.03831699f),
									vec2(-0.2101292f,0.2034733f),
									vec2(-0.7889516f,-0.5671548f),
									vec2(-0.1037751f,-0.1583221f),
									vec2(-0.5728408f,0.3416965f),
									vec2(-0.1863332f,0.5697952f),
									vec2(0.3561834f,0.007138769f),
									vec2(0.2868255f,-0.5463203f),
									vec2(-0.4640967f,-0.8804076f),
									vec2(0.1969438f,0.6236954f),
									vec2(0.6999109f,0.6357007f),
									vec2(-0.3462536f,0.8966291f),
									vec2(0.172607f,0.2832828f),
									vec2(0.4149241f,0.8816f),
									vec2(0.136898f,-0.9716249f),
									vec2(-0.6272043f,0.6721309f),
									vec2(-0.8974028f,0.4271871f),
									vec2(0.5551881f,0.324069f),
									vec2(0.9487136f,0.2605085f),
									vec2(0.7140148f,-0.312601f),
									vec2(0.0440252f,0.9363738f),
									vec2(0.620311f,-0.6673451f)
									);

vec3 decode (vec2 enc){
    vec2 fenc = enc*4-2;
    float f = dot(fenc,fenc);
    float g = sqrt(1-f/4.0);
    vec3 n;
    n.xy = fenc*g;
    n.z = 1-f/2;
    return n;
}

//Colors
vec3 YCoCg2RGB(vec3 c){
	c.y-=0.5;
	c.z-=0.5;
	return vec3(c.r+c.g-c.b, c.r + c.b, c.r - c.g - c.b);
}

#ifdef Celshading
float pw = 1.0/ viewWidth;
float ph = 1.0/ viewHeight;

float edepth(vec2 coord) {
	return texture2D(depthtex1,coord).z;
}

vec3 celshade(vec3 clrr) {
	//edge detect
	float d = edepth(texcoord.xy);
	float dtresh = 1/(far-near)/5000.0;
	vec4 dc = vec4(d);
	vec4 sa;
	vec4 sb;
	sa.x = edepth(texcoord.xy + vec2(-pw,-ph));
	sa.y = edepth(texcoord.xy + vec2(pw,-ph));
	sa.z = edepth(texcoord.xy + vec2(-pw,0.0));
	sa.w = edepth(texcoord.xy + vec2(0.0,ph));

	//opposite side samples
	sb.x = edepth(texcoord.xy + vec2(pw,ph));
	sb.y = edepth(texcoord.xy + vec2(-pw,ph));
	sb.z = edepth(texcoord.xy + vec2(pw,0.0));
	sb.w = edepth(texcoord.xy + vec2(0.0,-ph));

	vec4 dd = abs(2.0* dc - sa*BORDER - sb*BORDER) - dtresh;
	dd = vec4(step(dd.x,0.0),step(dd.y,0.0),step(dd.z,0.0),step(dd.w,0.0));

	float e = clamp(dot(dd,vec4(0.25f)),0.0,1.0);
	return clrr*e;
}
#endif

#ifdef SSDO
//modified version of Yuriy O'Donnell's SSDO (License MIT -> https://github.com/kayru/dssdo)
vec4 makeSSDO(vec2 tex, vec3 fragpos){
	vec3 normal = decode(texture2DLod(gdepth,tex,0).xy);

	vec4 occlusion_sh2 = vec4(0.0);

	float radius = 0.03 / (fragpos.z);
	const float attenuation_angle_threshold = 0.2;
	const int num_samples = 25;	
	const float sh2_weight_l0 = 0.5*sqrt(0.31847133758);
	const vec3 sh2_weight_l1 = vec3(0.5)*sqrt(0.95541401273);
	const vec4 sh2_weight = vec4(sh2_weight_l1, sh2_weight_l0) / num_samples;

	for( int i=0; i<num_samples; ++i ){
	    vec2 texOffset = pow(length((check_offsets[i].xy)),0.5)*radius*vec2(1.0,aspectRatio)*normalize(check_offsets[i].xy);
		vec2 sample_tex = tex + texOffset;

		vec4 t0 = gbufferProjectionInverse*vec4(vec3(sample_tex,texture2D(depthtex1,sample_tex).x)*2.0-1.0,1.0);
		t0 /= t0.w;

		vec3 center_to_sample = t0.rgb - fragpos.rgb;

		float dist = length(center_to_sample);

		vec3 center_to_sample_normalized = center_to_sample / dist;
		float attenuation = 1.0-clamp(dist/6.0,0.0,1.0);
		float dp = dot(normal, center_to_sample_normalized);

		attenuation = sqrt(max(dp,0.0))*attenuation*attenuation * step(attenuation_angle_threshold, dp);
		occlusion_sh2 += attenuation * sh2_weight*vec4(center_to_sample_normalized,1);
	}
	return occlusion_sh2;
}
#endif

/* If you reached this line, then you're probably about to break the agreement which you accepted by downloading Sildur's shaders!
So stop your doing and ask Sildur before copying anything which would break the agreement, unless you're Chocapic then go ahead ;)
--------------------------------------------------------------------------------------------------------------------------------*/ 

void main() {

//sample half-resolution buffer with correct texture coordinates
vec4 hr = pow(texture2D(composite,(floor(gl_FragCoord.xy/2.)*2+1.0)/vec2(viewWidth,viewHeight)/2.0),vec4(2.2,2.2,2.2,1.0))*vec4(257.,257,257,1.0);

//Colors
vec4 albedo = texture2D(gcolor,texcoord);
vec3 color = vec3(albedo.rg,0.0);
/*---------------------------------*/

//Get materials
float Depth = texture2D(depthtex1, texcoord).x;
vec4 fragpos = gbufferProjectionInverse * (vec4(texcoord,Depth,1.0) * 2.0 - 1.0);
	fragpos /= fragpos.w;
	
bool land = !(dot(albedo.rgb,vec3(1.0))<0.00000000001 || (Depth > comp));
bool translucent = albedo.b > 0.69 && albedo.b < 0.71;
bool emissive = albedo.b > 0.59 && albedo.b < 0.61;

vec3 normal = texture2DLod(gnormal,texcoord,0).xyz;
bool iswater = normal.z < 0.2499 && dot(normal,normal) > 0.0;
bool isice = normal.z > 0.2499 && normal.z < 0.4999 && dot(normal,normal) > 0.0;
bool isnsun = (iswater||isice) || ((!iswater||!isice) && isEyeInWater == 1);
/*-------------------------------------------------------------------------------*/

if (land && dot(albedo.rgb,vec3(1.0))>0.00000000001){
//Fix colors and textures
vec2 a0 = texture2D(gcolor,texcoord + vec2(1.0/viewWidth,0.0)).rg;
vec2 a1 = texture2D(gcolor,texcoord - vec2(1.0/viewWidth,0.0)).rg;
vec2 a2 = texture2D(gcolor,texcoord + vec2(0.0,1.0/viewHeight)).rg;
vec2 a3 = texture2D(gcolor,texcoord - vec2(0.0,1.0/viewHeight)).rg;
vec4 lumas = vec4(a0.x,a1.x,a2.x,a3.x);
vec4 chromas = vec4(a0.y,a1.y,a2.y,a3.y);

const vec4 THRESH = vec4(0.11764705882);

vec4 w = 1.0-step(THRESH, abs(lumas - color.x));
float W = dot(w,vec4(1.0));

w.x = (W==0.0)? 1.0:w.x;  W = (W==0.0)? 1.0:W;

bool pattern = (mod(gl_FragCoord.x,2.0)==mod(gl_FragCoord.y,2.0));
color.b = dot(w,chromas)/W;
color.rgb = (pattern)?color.rbg:color.rgb;
color.rgb = YCoCg2RGB(color.rgb);

color = pow(color,vec3(2.2));
/*------------------------------*/

#ifdef Whiteworld
	color += vec3(1.5);
#endif

#ifdef Celshading
	color = celshade(color);
#endif

#ifdef SSDO
	if (!isnsun && !translucent){
	vec4 occlusion = makeSSDO(texcoord, fragpos.xyz);
	float ao_power = pow(1.0-occlusion.a/0.48872640933, 2.5);
	color *= ao_power;
	}
#endif
	
	//Emissive blocks lighting and colors
	float mfp = min(1-clamp(length(fragpos.xyz),0.0,1000.0)/1.5,0.85);		
	float handHeldLight = 40.0;
	if (isnsun && getlight > 0.1)handHeldLight -= 35.0;
	handHeldLight = (1.0/pow((1-mfp)*16.0,2.0))*handHeldLight*handItemLight;
	
	float torch_lightmap = texture2D(gdepth,texcoord).z;
	torch_lightmap 		= 6.4 - min(torch_lightmap * 6.16,5.6);
	torch_lightmap 		= 0.1 / torch_lightmap / torch_lightmap - 0.002595;
	#ifdef Bloom
	float emitted 		= float(emissive) * (clamp(length(color)*80.0*torch_lightmap, 0.0, 8.8));
	#else
	float emitted 		= float(emissive) * (clamp(length(color), 0.0, 8.8));
	#endif
	vec3 emissiveLightColor = vec3(2.0, 0.5, 0.1)*(emitted + torch_lightmap+handHeldLight)*2.05;
	/*--------------------------------------------------------------------------------------------------------------------------------*/

	//Lighting and colors
	vec2 visibility = vec2(sunVisibility,moonVisibility);

	float skyL = max(texture2D(gdepth,texcoord).w-2./16.0,0.0)*1.14285714286;
	float SkyL2 = skyL*skyL;
	float skyc2 = mix(1.0,SkyL2,skyL);

	vec3 normalT = decode(texture2D(gdepth,texcoord).xy);	
	float NdotL = dot(normalT,sunVec);
	float NdotU = dot(normalT,upVec);
	
	vec4 bounced = vec4(NdotL,NdotL,NdotL,NdotU) * vec4(-0.15*skyL*skyL,0.34,0.7,0.14) + vec4(0.6,0.66,0.7,0.23);
	bounced *= vec4(skyc2,skyc2,visibility.x-tr*visibility.x,0.8);

	vec3 sun_ambient = bounced.w * (vec3(0.08, 0.35, 1.0)+rainStrength*vec3(0.05,-0.2,-0.8))*2.4+ 1.45*sunlight*(sqrt(bounced.w)*bounced.x*2.4 + bounced.z)*(1.0-rainStrength*0.98);
	const vec3 moonlight = vec3(0.4, 0.72, 1.3) * Moonlight;
	vec3 moon_ambient = (moonlight*0.7 + moonlight*bounced.y)*(1.0-rainStrength*0.95)*4.0;

	vec3 LightC = mix(sunlight,moonlight,moonVisibility)*tr*(1.0-rainStrength*0.99);
	vec3 amb1 = (sun_ambient*visibility.x + moon_ambient*visibility.y)*SkyL2*(0.03+tr*0.17)*0.65;
	vec3 ambientC =  amb1 + emissiveLightColor + vec3(0.002,0.002,0.002)*min(skyL+6.0/16.0,9.0/16.0)*normalize(amb1+0.0001)*2.0;
	/*-------------------------------------------------------------------------------------------------------------------------------------------------------*/

#ifdef Shadows
NdotL = max((worldTime > 12700 && worldTime < 23250)? -NdotL : NdotL,0.0);
float diffuse = mix(1.0,2.0,pow(1-NdotL,5.0))*NdotL; //modified diffuse shading

if (translucent) diffuse = abs(dot(sunVec,upVec))*0.2+NdotL*0.2+0.6;

vec3 finalshading;
vec4 worldposition = gbufferModelViewInverse * fragpos;

if (diffuse > 0.00001){
	worldposition = shadowModelView * worldposition;
	worldposition = shadowProjection * worldposition;
	worldposition /= worldposition.w;
	vec2 pos = abs(worldposition.xy * 1.165);
	float distb = pow(pow(pos.x, 12.) + pow(pos.y, 12.), 0.083);
	float distortFactor = (1.0 - SHADOW_MAP_BIAS) + distb * SHADOW_MAP_BIAS;
	worldposition.xy /= distortFactor*0.97;

	if (max(abs(worldposition.x),abs(worldposition.y)) < 0.99) {
			float diffthresh = translucent? 0.00017 : distortFactor*distortFactor*(0.01*tan(acos(max(NdotL,0.0))) + 0.001)*0.15;
			worldposition = worldposition * vec4(0.5,0.5,0.2,0.5) + vec4(0.5,0.5,0.5,0.5);

		float shading = 0.0;
		float cshading = 0.0;
		for(int i = 0; i < 5; i++){
			vec2 offsetS = check_offsets[i];
			float w1 = dot(offsetS,offsetS);
			float weight = 1.0+sqrt(w1*(1.0+rainStrength*8.0));
			if(translucent)weight *= 8.3;
			vec3 shadowcoord = vec3(worldposition.st + offsetS/shadowMapResolution*(rainStrength*8.0+1.412), worldposition.z-diffthresh*weight*0.75);				

			shading += shadow2D(shadow, shadowcoord).x*diffuse*0.2;
		#ifdef ColoredShadows
			cshading += texture2D(shadowtex1, shadowcoord.st).x*0.2;		
		#endif
		}
	#ifdef ColoredShadows	
		vec4 shadowcolor = texture2D(shadowcolor0, worldposition.st);
		float depthcomparison = 1.0 - clamp((worldposition.z - cshading) * 2000.0, 0.0, 1.0); 
		finalshading = shadowcolor.a < 0.11? shadowcolor.rgb*depthcomparison*diffuse : vec3(shading);
	#else
		finalshading = vec3(shading);
	#endif
	}
}/*---------------------------------------------------------------------*/
#else
vec3 finalshading = vec3(0.5);
#endif

//Combine everything
color *= (finalshading*LightC*(isnsun?SkyL2*skyL:1.0)*2.08+ambientC*(isnsun?1.0/(SkyL2*skyL*0.5+0.5):1.0)*1.3)*0.63;
}

//Draw sky (color)
if (!land)color = hr.rgb;
/*-------------------------*/

	color = pow(color/257.0,vec3(0.454));

	gl_FragData[0] = vec4(color, hr.a);
}
