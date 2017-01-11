#version 120

#define MAX_COLOR_RANGE 48.0
const float ambientOcclusionLevel = 0.0;
/*
!! DO NOT REMOVE !!
This code is from CYBOXshaders
Read the terms of modification and sharing before changing something below please !
!! DO NOT REMOVE !!
*/

/*
Disable an effect by putting "//" before "#define" when there is no number after
You can tweak the numbers, the impact on the shaders is self-explained in the variable's name or in a comment
*/

//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES




//----------Shadows----------//
	const int shadowMapResolution = 10;	 //shadows resolution
	const float shadowDistance = 1.0;		//distance shadows are rendered
	#define SHADOW_DARKNESS 20.23		   //[0.10 0.15 0.23 0.30 0.40 0.50 0.60 0.80 1.0]
	//#define HQ_SHADOW_FILTER
      	  //#define SHADOW_FILTER
//----------End of Shadows----------//




//----------Lighting----------//
	#define DYNAMIC_HANDLIGHT
	#define SUNLIGHTAMOUNT 12.0				       //[1.0 3.0 6.0 8.0 10.0 12.0 14.0 16.0 18.0]
	#define TORCH_COLOR_LIGHTING  1.50,0.50,0.1	  //Torch Color RGB - Red, Green, Blue / vec3(3.0,0.50,0.1) is default
		#define TORCH_ATTEN 7.0				     //how much the torch light will be attenuated (decrease if you want the torches to cover a bigger area))/2.0 is default
		#define TORCH_INTENSITY 0.12			//torch light intensity /0.12 is default
		#define TORCH_MULT 1.6				   //Torch lightmap attenuation function, where x is torch light from minecraft lightmap  : ((x*mult)^atten)*intensity
	//Minecraft lightmap (used for sky)
	#define ATTENUATION 1.3
	#define MIN_LIGHT 0.0005
//----------End of Lighting----------//




//----------Sun----------//
//#define GODRAYS
		const float density = 1.0;
		const int NUM_SAMPLES = 7;			 //increase this for better quality at the cost of performance /7 is default
		const float grnoise = 1.0;			//amount of noise /1.0 is default
//----------End of Sun----------//




//----------Details----------//
#define SSAO
#ifdef SSAO
	const int nbdir = 6;            //qualtiy
const float sampledir = 6;         //quality
const float ssaorad = 1000000.0;  //strength
#endif
//#define CELSHADING
		#define BORDER 1.0
//----------End of Details----------//




//----------Extra----------//
	const float	sunPathRotation	= -40.0f;		//determines sun/moon rotation angle /-40.0 is default - 0.0 is normal rotation
//----------End of Extra----------//




//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES
const float 	wetnessHalflife 		= 70.0f;
const float 	drynessHalflife 		= 70.0f;

const bool 		shadowHardwareFiltering = true;
const float centerDepthHalflife = 2.3f;
const int 		noiseTextureResolution  = 1524;


#define SHADOW_MAP_BIAS 0.85

varying vec4 texcoord;

varying vec3 lightVector;
varying vec3 sunVec;
varying vec3 moonVec;
varying vec3 upVec;

varying vec3 sunlight;
varying vec3 moonlight;
varying vec3 ambient_color;

varying vec4 lightS;

varying float handItemLight;
varying float eyeAdapt;

varying float SdotU;
varying float MdotU;
varying float sunVisibility;
varying float moonVisibility;

uniform sampler2D gcolor;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D gnormal;
uniform sampler2DShadow shadow;
uniform sampler2D gaux1;
uniform sampler2D noisetex;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 upPosition;
uniform vec3 cameraPosition;

uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform float wetness;
uniform float centerDepthSmooth;
uniform float aspectRatio;
uniform float frameTimeCounter;
uniform ivec2 eyeBrightness;
uniform ivec2 eyeBrightnessSmooth;
uniform int isEyeInWater;
uniform int worldTime;
uniform int fogMode;

float timefract = worldTime;
float TimeSunrise  = ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0) + (1.0 - (clamp(timefract, 0.0, 4000.0)/4000.0));
float TimeNoon     = ((clamp(timefract, 0.0, 4000.0)) / 4000.0) - ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0);
float TimeSunset   = ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0) - ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0);
float TimeMidnight = ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0) - ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0);

float cdist(vec2 coord){
    return distance(coord,vec2(0.5))*2.0;
}

vec3 convertScreenSpaceToWorldSpace(vec2 co, float depth) {
    vec4 fragposition = gbufferProjectionInverse * vec4(vec3(co, depth) * 2.0 - 1.0, 1.0);
    fragposition /= fragposition.w;
    return fragposition.xyz;
}

vec3 convertCameraSpaceToScreenSpace(vec3 cameraSpace) {
    vec4 clipSpace = gbufferProjection * vec4(cameraSpace, 1.0);
    vec3 NDCSpace = clipSpace.xyz / clipSpace.w;
    vec3 screenSpace = 0.5 * NDCSpace + 0.5;
    return screenSpace;
}

float luma(vec3 color) {
	return dot(color,vec3(0.299, 0.587, 0.114));
}

float ld(float depth) {
    return (2.0 * near) / (far + near - depth * (far - near));
}

vec3 nvec3(vec4 pos) {
    return pos.xyz/pos.w;
}

vec4 nvec4(vec3 pos) {
    return vec4(pos.xyz, 1.0);
}

float edepth(vec2 coord) {
	return texture2D(depthtex0,coord).z;
}
vec2 newtc = texcoord.xy;
vec3 sky_color = normalize(vec3(0.1, 0.35, 1.0));

vec2 texel = vec2(1.0/viewWidth,1.0/viewHeight);

float pw = 1.0/ viewWidth;
float ph = 1.0/ viewHeight;

vec3 aux = texture2D(gaux1, texcoord.st).rgb;
vec3 normal = texture2D(gnormal, texcoord.st).rgb * 2.0f - 1.0f;

vec3 fragpos = vec3(texcoord.st, texture2D(depthtex0, texcoord.st).r);
float pixeldepth = texture2D(depthtex0,texcoord.xy).x;
float handlight = handItemLight;

float torch_lightmap = pow(max(aux.b,0.0)*TORCH_MULT,TORCH_ATTEN)*TORCH_INTENSITY;



//float torch_lightmap = (1.0-exp(-aux.b*light_jitter/TORCH_ATTEN))*TORCH_INTENSITY;

float sky_lightmap = pow(aux.r,ATTENUATION);

float iswet = wetness*pow(sky_lightmap,5.0)*sqrt(0.5+max(dot(normal,upVec),0.0));


//poisson distribution for shadow sampling
	const vec2 shadow_offsets[60] = vec2[60]  (  vec2( 0.0000, 0.2500 ),
									vec2( -0.2165, 0.1250 ),
									vec2( -0.2165, -0.1250 ),
									vec2( -0.0000, -0.2500 ),
									vec2( 0.2165, -0.1250 ),
									vec2( 0.2165, 0.1250 ),
									vec2( 0.0000, 0.5000 ),
									vec2( -0.2500, 0.4330 ),
									vec2( -0.4330, 0.2500 ),
									vec2( -0.5000, 0.0000 ),
									vec2( -0.4330, -0.2500 ),
									vec2( -0.2500, -0.4330 ),
									vec2( -0.0000, -0.5000 ),
									vec2( 0.2500, -0.4330 ),
									vec2( 0.4330, -0.2500 ),
									vec2( 0.5000, -0.0000 ),
									vec2( 0.4330, 0.2500 ),
									vec2( 0.2500, 0.4330 ),
									vec2( 0.0000, 0.7500 ),
									vec2( -0.2565, 0.7048 ),
									vec2( -0.4821, 0.5745 ),
									vec2( -0.6495, 0.3750 ),
									vec2( -0.7386, 0.1302 ),
									vec2( -0.7386, -0.1302 ),
									vec2( -0.6495, -0.3750 ),
									vec2( -0.4821, -0.5745 ),
									vec2( -0.2565, -0.7048 ),
									vec2( -0.0000, -0.7500 ),
									vec2( 0.2565, -0.7048 ),
									vec2( 0.4821, -0.5745 ),
									vec2( 0.6495, -0.3750 ),
									vec2( 0.7386, -0.1302 ),
									vec2( 0.7386, 0.1302 ),
									vec2( 0.6495, 0.3750 ),
									vec2( 0.4821, 0.5745 ),
									vec2( 0.2565, 0.7048 ),
									vec2( 0.0000, 1.0000 ),
									vec2( -0.2588, 0.9659 ),
									vec2( -0.5000, 0.8660 ),
									vec2( -0.7071, 0.7071 ),
									vec2( -0.8660, 0.5000 ),
									vec2( -0.9659, 0.2588 ),
									vec2( -1.0000, 0.0000 ),
									vec2( -0.9659, -0.2588 ),
									vec2( -0.8660, -0.5000 ),
									vec2( -0.7071, -0.7071 ),
									vec2( -0.5000, -0.8660 ),
									vec2( -0.2588, -0.9659 ),
									vec2( -0.0000, -1.0000 ),
									vec2( 0.2588, -0.9659 ),
									vec2( 0.5000, -0.8660 ),
									vec2( 0.7071, -0.7071 ),
									vec2( 0.8660, -0.5000 ),
									vec2( 0.9659, -0.2588 ),
									vec2( 1.0000, -0.0000 ),
									vec2( 0.9659, 0.2588 ),
									vec2( 0.8660, 0.5000 ),
									vec2( 0.7071, 0.7071 ),
									vec2( 0.5000, 0.8660 ),
									vec2( 0.2588, 0.9659 ));




float ctorspec(vec3 ppos, vec3 lvector, vec3 normal,float rough,float fpow) {
	//half vector
	vec3 pos = -normalize(ppos);
	vec3 cHalf = normalize(lvector + pos);

	// beckman's distribution function D
	float normalDotHalf = dot(normal, cHalf);
	float normalDotHalf2 = normalDotHalf * normalDotHalf;

	float roughness2 = rough;
	float exponent = -(1.0 - normalDotHalf2) / (normalDotHalf2 * roughness2);
	float e = 2.71828182846;
	float D = pow(e, exponent) / (roughness2 * normalDotHalf2 * normalDotHalf2);

	// fresnel term F
	float normalDotEye = dot(normal, pos);
	float F = pow(1.0 - normalDotEye, fpow);

	// self shadowing term G
	float normalDotLight = dot(normal, lvector);
	float X = 2.0 * normalDotHalf / dot(pos, cHalf);
	float G = min(1.0, min(X * normalDotLight, X * normalDotEye));
	float pi = 3.1415927;
	float CookTorrance = (D*G)/acos(normalDotEye);

	return clamp(CookTorrance/pi,0.0,1.0);
}

float Blinn_Phong(vec3 ppos, vec3 lvector, vec3 normal,float fpow, float gloss, float visibility)  {
	vec3 lightDir = vec3(lvector);

	vec3 surfaceNormal = normal;
	float cosAngIncidence = dot(surfaceNormal, lightDir);
	cosAngIncidence = clamp(cosAngIncidence, 0.0, 1.0);

	vec3 viewDirection = normalize(-ppos);

	vec3 halfAngle = normalize(lightDir + viewDirection);
	float blinnTerm = dot(surfaceNormal, halfAngle);

	float normalDotEye = dot(normal, normalize(ppos));
	float fresnel = clamp(pow(1.0 + normalDotEye, 5.0),0.0,1.0);
	fresnel = fresnel*0.85 + 0.15 * (1.0-fresnel);
	float pi = 3.1415927;
	float n =  pow(2.0,gloss*10.0);
	return (pow(blinnTerm, n )*((n+8.0)/(8*pi)))*visibility;
}

float getnoise(vec2 pos) {
	return abs(fract(sin(dot(pos ,vec2(18.9898f,28.633f))) * 4378.5453f));
}

#ifdef CELSHADING
vec3 celshade(vec3 clrr) {
	//edge detect
	float d = edepth(newtc.xy);
	float dtresh = 1/(far-near)/5000.0;
	vec4 dc = vec4(d,d,d,d);
	vec4 sa;
	vec4 sb;
	sa.x = edepth(newtc.xy + vec2(-pw,-ph)*BORDER);
	sa.y = edepth(newtc.xy + vec2(pw,-ph)*BORDER);
	sa.z = edepth(newtc.xy + vec2(-pw,0.0)*BORDER);
	sa.w = edepth(newtc.xy + vec2(0.0,ph)*BORDER);

	//opposite side samples
	sb.x = edepth(newtc.xy + vec2(pw,ph)*BORDER);
	sb.y = edepth(newtc.xy + vec2(-pw,ph)*BORDER);
	sb.z = edepth(newtc.xy + vec2(pw,0.0)*BORDER);
	sb.w = edepth(newtc.xy + vec2(0.0,-ph)*BORDER);

	vec4 dd = abs(2.0* dc - sa - sb) - dtresh;
	dd = vec4(step(dd.x,0.0),step(dd.y,0.0),step(dd.z,0.0),step(dd.w,0.0));

	float e = clamp(dot(dd,vec4(0.25f,0.25f,0.25f,0.25f)),0.0,1.0);
	return clrr*e;
}
#endif


float fx(float x) {
return (2 *(-sin(x)*sin(x)*sin(x) + 3*sin(x) + 3*x)) / 3;

}
float fx2(float x) {
return (-cos(x) * sin(x) + 6*x) / 2;

}

vec3 skyLightColor (vec3 fposition) {
vec3 skycoaa = ivec3(60,170,255)/255.0;
vec3 sky_color = pow(skycoaa,vec3(2.2));
vec3 nsunlight = normalize(pow(sunlight,vec3(2.2)));
sky_color = normalize(mix(sky_color,vec3(0.25,0.3,0.4)*length(ambient_color),rainStrength)); //normalize colors in order to don't change luminance
vec3 sVector = normalize(fposition);
const float PI = 3.14159265359;
float cosT = dot(sVector,upVec);
float T = acos(cosT);
float absCosT = abs(cosT);
float cosS = SdotU;
float S = acos(cosS);
float cosY = dot(sunVec,sVector);
float Y = acos(cosY);

float tL = ((fx(Y+PI/2.0)-fx(Y-PI/2.0))*2.5 + fx2(T+PI/2.0)-fx2(T-PI/2.0))/6.28;

//moon sky color
float McosS = MdotU;
float MS = acos(McosS);
float McosY = dot(moonVec,sVector);
float MY = acos(McosY);
float tLMoon = ((fx(MY+PI/2.0)-fx(MY-PI/2.0))*3.0 + fx2(T+PI/2.0)-fx2(T-PI/2.0))/6.28;

return mix(sky_color, nsunlight,1-exp(-0.16*tL*(1-rainStrength*0.8)))*tL*sunVisibility*(1-rainStrength*0.8) + tLMoon*moonVisibility*moonlight;
}

float subSurfaceScattering(vec3 pos, float N) {

return pow(max(dot(lightVector,normalize(pos)),0.0),N)*(N+1)/6.28;

}

vec3 getSkyColor(vec3 fposition) {
//sky gradient
/*----------*/
vec3 skycoaa = ivec3(30,170,255)/255.0;
vec3 sky_color = pow(skycoaa,vec3(2.2));
vec3 nsunlight = normalize(pow(sunlight,vec3(2.2)));
vec3 sVector = normalize(fposition);

sky_color = normalize(mix(sky_color,vec3(0.25,0.3,0.4)*length(ambient_color),rainStrength)); //normalize colors in order to don't change luminance


float Lz = 1.0;
float cosT = dot(sVector,upVec); //T=S-Y
float absCosT = abs(cosT);
float cosS = SdotU;
float S = acos(cosS);				//S=Y+T	-> cos(Y+T)=cos(S) -> cos(Y)*cos(T) - sin(Y)*sin(T) = cos(S)
float cosY = dot(sunVec,sVector);
float Y = acos(cosY);				//Y=S-T


float a = -0.7;
float b = -0.2;
float c = 12.0;
float d = -0.9;
float e = 3.0;

//sun sky color
float L =  (1+a*exp(b/(absCosT+0.01)))*(1+c*exp(d*Y)+e*cosY*cosY);
L = pow(L,1.0-rainStrength*0.8)*(1.0-rainStrength*0.2); //modulate intensity when raining
vec3 skyColorSun = mix(sky_color, nsunlight,1-exp(-0.13*L*(1-rainStrength*0.8)))*L ; //affect color based on luminance (0% physically accurate)
skyColorSun *= sunVisibility;


//moon sky color
float McosS = MdotU;
float MS = acos(McosS);
float McosY = dot(moonVec,sVector);
float MY = acos(McosY);

float L2 =  (1+a*exp(b/(absCosT+0.01)))*(1+c*exp(d*MY)+e*McosY*McosY);
L2 = pow(L2,1.0-rainStrength*0.8)*(1.0-rainStrength*0.2); //modulate intensity when raining
vec3 skyColormoon = mix(moonlight,normalize(vec3(0.25,0.3,0.4))*length(moonlight),rainStrength)*L2*0.4 ; //affect color based on luminance (0% physically accurate)
skyColormoon *= moonVisibility;

sky_color = skyColormoon+skyColorSun/2.0;
//sky_color = vec3(Lc);
/*----------*/


return sky_color;
}



float PosDot(vec3 v1,vec3 v2) {
return max(dot(v1,v2),0.0);
}

float waterH(vec3 posxz) {

float wave = 0.0;


float factor = 1.0;
float amplitude = 0.08;
float speed = 8.0;
float size = 0.4;

float px = posxz.x/50.0 + 250.0;
float py = posxz.z/50.0  + 250.0;

float fpx = abs(fract(px*20.0)-0.5)*2.0;
float fpy = abs(fract(py*20.0)-0.5)*2.0;


float d = length(vec2(fpx,fpy));

for (int i = 1; i < 4; i++) {
wave -= d*factor*cos( (1/factor)*px*py*size + 1.0*frameTimeCounter*speed);
factor /= 2;
}

factor = 1.0;
px = -posxz.x/50.0 + 250.0;
py = -posxz.z/150.0 - 250.0;

fpx = abs(fract(px*20.0)-0.5)*2.0;
fpy = abs(fract(py*20.0)-0.5)*2.0;

d = length(vec2(fpx,fpy));
float wave2 = 0.0;
for (int i = 1; i < 4; i++) {
wave2 -= d*factor*cos( (1/factor)*px*py*size + 1.0*frameTimeCounter*speed);
factor /= 2;
}

return amplitude*wave2+amplitude*wave;
}

//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////

void main() {
fragpos = nvec3(gbufferProjectionInverse * nvec4(fragpos * 2.0 - 1.0));
#ifndef DYNAMIC_HANDLIGHT
		handlight = 0.0;
#endif
	vec2 newtc = texcoord.xy;
	//unpack material flags
	float land = float(aux.g > 0.04);
	float iswater = float(aux.g > 0.04 && aux.g < 0.07);
	float translucent = float(aux.g > 0.3 && aux.g < 0.5);
	float hand = float(aux.g > 0.75 && aux.g < 0.85);
	float emissive = float(aux.g > 0.58 && aux.g < 0.62);
	float shading = 0.0f;
	float spec = 0.0;

vec3 nsunlight = normalize(mix(pow(sunlight,vec3(2.2)),vec3(0.25,0.3,0.4),rainStrength));
sky_color = normalize(mix(sky_color,vec3(0.25,0.3,0.4),rainStrength)); //normalize colors in order to don't change luminance

	float fresnel_pow = 5.0;

	vec3 color = texture2D(gcolor, newtc.st).rgb;
	color = pow(color,vec3(2.2))*(1.0+translucent*0.3);

	float NdotL = dot(lightVector,normal);
	float NdotUp = dot(normal,upVec);

	vec4 fragposition = gbufferProjectionInverse * vec4(newtc.s * 2.0f - 1.0f, newtc.t * 2.0f - 1.0f, 2.0f * pixeldepth - 1.0f, 1.0f);
	fragposition /= fragposition.w;

		vec4 worldposition = vec4(0.0);
		vec4 worldpositionraw = vec4(0.0);
		worldposition = gbufferModelViewInverse * fragposition;
		float xzDistanceSquared = worldposition.x * worldposition.x + worldposition.z * worldposition.z;
		float yDistanceSquared  = worldposition.y * worldposition.y;
		worldpositionraw = worldposition;


	float time = float(worldTime);
	float transition_fading = 1.0-(clamp((time-12000.0)/300.0,0.0,1.0)-clamp((time-13500.0)/300.0,0.0,1.0) + clamp((time-22500.0)/300.0,0.0,1.0)-clamp((time-23400.0)/300.0,0.0,1.0));	//fading between sun/moon shadows
	float night = clamp((time-12000.0)/300.0,0.0,1.0)-clamp((time-22800.0)/200.0,0.0,1.0);

	vec3 uPos = vec3(.0);

	if (iswater > 0.9) {

	vec3 posxz = worldposition.xyz+cameraPosition;
	posxz.x += sin(posxz.z+frameTimeCounter)*0.4;
	posxz.z += cos(posxz.x+frameTimeCounter*0.5)*0.4;

	float deltaPos = 0.4;
	float h0 = waterH(posxz);
	float h1 = waterH(posxz + vec3(deltaPos,0.0,0.0));
	float h2 = waterH(posxz + vec3(-deltaPos,0.0,0.0));
	float h3 = waterH(posxz + vec3(0.0,0.0,deltaPos));
	float h4 = waterH(posxz + vec3(0.0,0.0,-deltaPos));

	float xDelta = ((h1-h0)+(h0-h2))/deltaPos;
	float yDelta = ((h3-h0)+(h0-h4))/deltaPos;


	float refMult = 0.0025-dot(normal,normalize(fragposition).xyz)*0.0015;

	vec3 refract = normalize(vec3(xDelta,yDelta,1.0-xDelta*xDelta-yDelta*yDelta));
	vec4 rA = texture2D(gcolor, newtc.st + refract.xy*refMult);
	rA.rgb = pow(rA.rgb,vec3(2.2));
	vec4 rB = texture2D(gcolor, newtc.st);
	rB.rgb = pow(rB.rgb,vec3(2.2));
	float mask = texture2D(gaux1, newtc.st + refract.xy*refMult).g;
	mask =  float(mask > 0.04 && mask < 0.07);
	newtc = (newtc.st + refract.xy*refMult)*mask + texcoord.xy*(1-mask);
	float uDepth = texture2D(depthtex1,newtc.xy).x;
	color.rgb = pow(texture2D(gcolor,newtc.xy).rgb,vec3(2.2));
	uPos  = nvec3(gbufferProjectionInverse * nvec4(vec3(newtc.xy,uDepth) * 2.0 - 1.0));
	}


	if (land > 0.9) {
		float dist = length(fragposition.xyz);
		float distof = clamp(1.0-dist/shadowDistance,0.0,1.0);
		float distof2 = clamp(1.0-pow(dist/(shadowDistance*0.75),2.0),0.0,1.0);
		//float shadow_fade = clamp(distof*12.0,0.0,1.0);
		float shadow_fade = sqrt(clamp(1.0 - xzDistanceSquared / (shadowDistance*shadowDistance*1.0), 0.0, 1.0) * clamp(1.0 - yDistanceSquared / (shadowDistance*shadowDistance*1.0), 0.0, 1.0));


		/*--reprojecting into shadow space --*/

		worldposition = shadowModelView * worldposition;
		float comparedepth = -worldposition.z;
		worldposition = shadowProjection * worldposition;
		worldposition /= worldposition.w;
		float distb = sqrt(worldposition.x * worldposition.x + worldposition.y * worldposition.y);
		float distortFactor = (1.0f - SHADOW_MAP_BIAS) + distb * SHADOW_MAP_BIAS;
		worldposition.xy *= 1.0f / distortFactor;
		worldposition = worldposition * 0.5f + 0.5f;
		/*---------------------------------*/


		float step = 3.0/shadowMapResolution*(1.0+rainStrength*5.0);
		//shadow_fade = 1.0-clamp((max(abs(worldposition.x-0.5),abs(worldposition.y-0.5))*2.0-0.9),0.0,0.1)*10.0;

		float NdotL = dot(normal, lightVector);
		float diffthresh = (pow(distortFactor*1.2,2.0)*(0.25/148.0)*(tan(acos(abs(NdotL)))) + (0.02/148.0))*(1.0+iswater*2.0);
		diffthresh = mix(diffthresh,0.0005,translucent);

		if (comparedepth > 0.02 &&	worldposition.s < 0.98 && worldposition.s > 0.02 && worldposition.t < 0.98 && worldposition.t > 0.02 ) {
			if ((NdotL < 0.0 && translucent < 0.1) || (sky_lightmap < 0.01 && eyeBrightness.y < 2)) {
					shading = 0.0;
				}

			else {
			#ifdef HQ_SHADOW_FILTER
				step = 2.0/shadowMapResolution*(1.0+rainStrength*5.0);
				//diffthresh = 0.0018f * diffthresh * (0.5+(1.0-NdotL)*5.0*(1.0-translucent));
				float weight;
				float totalweight = 0.0;
				float sigma = 0.25;
				float A = 1.0/sqrt(2.0*3.14159265359*sigma);

				for(int i = 0; i < 60; i++){
					float dist = length(shadow_offsets[i]);
					float weight = A*exp(-(dist*dist)/(2.0*sigma));
					shading += shadow2D(shadow,vec3(worldposition.st + shadow_offsets[i]*step, worldposition.z-diffthresh*(2.0-weight))).x;
					totalweight += 1;
				}

			shading /= totalweight;
			#endif

			step = 0.5/shadowMapResolution*(1.0+rainStrength*5.0);

			#ifdef SHADOW_FILTER
				shading = shadow2D(shadow,vec3(worldposition.st, worldposition.z-diffthresh)).x;
				shading += shadow2D(shadow,vec3(worldposition.st + vec2(step,0), worldposition.z-diffthresh*2)).x;
				shading += shadow2D(shadow,vec3(worldposition.st + vec2(-step,0), worldposition.z-diffthresh*2)).x;
				shading += shadow2D(shadow,vec3(worldposition.st + vec2(0,step), worldposition.z-diffthresh*2)).x;
				shading += shadow2D(shadow,vec3(worldposition.st + vec2(0,-step), worldposition.z-diffthresh*2)).x;
				shading = shading/5.0;
			#endif

			#ifndef SHADOW_FILTER
				#ifndef HQ_SHADOW_FILTER
				shading = shadow2D(shadow,vec3(worldposition.st, worldposition.z-diffthresh)).x;
				#endif
			#endif
			}
		}

		else shading = 1.0;
		if (sky_lightmap < 0.02 && eyeBrightness.y < 2) {
					shading = 0.0;
				}

		vec3 npos = normalize(fragposition.xyz);

		float diffuse = max(dot(lightVector,normal),0.0);

		diffuse = mix(diffuse,1.0,translucent*0.3);
		float sss = subSurfaceScattering(fragposition.xyz,30.0)*SUNLIGHTAMOUNT*2.0;
		sss = (mix(0.0,sss,max(shadow_fade-0.5,0.0)*2.0)*0.5+0.5)*translucent;

		float handLight = (handlight*5.5)/pow(1.0+length(fragposition.xyz/1.4),2.0)*sqrt(dot(normalize(fragposition.xyz), -normal)*0.5+0.51);


float ao = 1.0;
#ifdef SSAO
if (land > 0.9 && iswater < 0.9 && hand < 0.9) {
	vec3 norm = texture2D(gnormal,texcoord.xy).rgb*2.0-1.0;
	vec3 projpos = convertScreenSpaceToWorldSpace(texcoord.xy,pixeldepth);

	float progress = 0.0;
	ao = 0.0;

	float projrad = clamp(distance(convertCameraSpaceToScreenSpace(projpos + vec3(ssaorad,ssaorad,ssaorad)).xy,texcoord.xy),10.0*pw,10.0*pw);

		for (int i = 1; i < nbdir; i++) {
			for (int j = 1; j < sampledir; j++) {
				vec2 samplecoord = vec2(cos(progress),sin(progress))*(j/sampledir)*projrad + texcoord.xy;
				float sample = texture2D(depthtex0,samplecoord).x;
				vec3 sprojpos = convertScreenSpaceToWorldSpace(samplecoord,sample);
				float angle = pow(min(1.0-dot(norm,normalize(sprojpos-projpos)),1.0),2.0);
				float dist = pow(min(abs(ld(sample)-ld(pixeldepth)),0.015)/0.015,2.0);
				float temp = min(dist+angle,1.0);
				ao += pow(temp,3.0);
				//progress += (1.0-temp)/nbdir*3.14;
			}
			progress = i*1.256;
		}

		ao /= (nbdir-1)*(sampledir-1);

	}
#endif




	//Apply different lightmaps to image
		shading *= 1-isEyeInWater;

		vec3 light_col =  mix(pow(sunlight,vec3(2.2)),moonlight,moonVisibility);
		light_col = mix(light_col,vec3(length(light_col))*0.3,rainStrength*0.9);
		vec3 Sunlight_lightmap = light_col*shading*(1.0-rainStrength*0.95)*SUNLIGHTAMOUNT *diffuse*transition_fading ;

		vec3 Ucolor= normalize(vec3(0.1,0.4,0.6));

		//we'll suppose water plane have same height above pixel and at pixel water's surface
			//underwater position

		vec3 uVec = fragposition.xyz-uPos;
		float UNdotUP = abs(dot(normalize(uVec),normal));
		float depth = length(uVec)*UNdotUP;
		float sky_absorbance = mix(mix(1.0,exp(-depth/2.5),iswater),1.0,isEyeInWater);




		float visibility = sky_lightmap;
		float bouncefactor = sqrt((NdotUp*0.4+0.61) * pow(1.01-NdotL*NdotL,2.0)+0.5)*0.66;
		float cfBounce = (-NdotL*0.45+0.56);

		vec3 emissive = (1/length(color))*(emissive+handlight*hand)*eyeAdapt*color*3.0;

		vec3 bounceSunlight = 0.6*cfBounce*light_col*sky_lightmap*sky_lightmap*sky_lightmap*SHADOW_DARKNESS * (1-rainStrength*0.9);

		float tL = (lightS.x*pow(sky_lightmap,2.2) + lightS.y)/5.5;
		float tLMoon = (lightS.z + lightS.w)/3.;

		vec3 skycolor = mix(sky_color, nsunlight,1-exp(-0.11*tL*(1-rainStrength*0.8)))*tL*sunVisibility*(1-rainStrength*0.8) + tLMoon*moonVisibility*moonlight;

		vec3 sky_light = SHADOW_DARKNESS*skycolor*visibility*bouncefactor*(1+moonVisibility*0.7);

		vec3 torchcolor = vec3(TORCH_COLOR_LIGHTING)*eyeAdapt;
		vec3 Torchlight_lightmap = (torch_lightmap + handLight) *  torchcolor ;
		vec3 color_torchlight = Torchlight_lightmap;



		color = ((bounceSunlight+sky_light)*ao+ Sunlight_lightmap*ao + color_torchlight*ao +  sss * light_col * shading *(1.0-rainStrength*0.9)*transition_fading + emissive)*color*sky_absorbance;
		//color.rgb  = bounceSunlight;
		if (iswater > 0.9) color = mix(Ucolor*length(ambient_color)*0.04*sky_lightmap,color,exp(-depth/16));



		float gfactor = 1.0;
		spec = Blinn_Phong(fragposition.xyz,lightVector,normal,fresnel_pow,gfactor,shading*diffuse) *iswater * (1.0-isEyeInWater)*transition_fading;
	}




float gr = 0.0;
#ifdef GODRAYS
        vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
	tpos = vec4(tpos.xyz/tpos.w,1.0);
	vec2 pos1 = tpos.xy/tpos.z;
	vec2 lightPos = pos1*0.5+0.5;


		vec2 deltaTextCoord = vec2( newtc.st - lightPos.xy );
		vec2 textCoord = newtc.st;
		deltaTextCoord *= 1.0 /  float(NUM_SAMPLES) * density;
		float avgdecay = 0.0;
		float distx = abs(newtc.x*aspectRatio-lightPos.x*aspectRatio);
		float disty = abs(newtc.y-lightPos.y);
		float fallof = 1.0;
		float noise = getnoise(textCoord);

		for(int i=0; i < NUM_SAMPLES ; i++) {
			textCoord -= deltaTextCoord;

			fallof *= 0.7;
			float sample = step(texture2D(gaux1, textCoord+ deltaTextCoord*noise*grnoise).g,0.01);
			gr += sample*fallof;
		}

#endif

#ifdef CELSHADING
	if (iswater < 0.9) color = celshade(color);
#endif
	color = clamp(pow(color/MAX_COLOR_RANGE,vec3(1.0/2.2)),0.0,1.0);
/* DRAWBUFFERS:31 */
	gl_FragData[0] = vec4(color, spec);
	gl_FragData[1] = vec4(vec3((gr/NUM_SAMPLES)),1.0);
}
