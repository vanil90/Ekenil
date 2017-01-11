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

/*--------------------
//ADJUSTABLE VARIABLES//
---------------------*/

	//#define Godrays
		#define Godrays_Density 1.15			//[0.575 1.15 2.3 4.6 9.2]	 

	#define Underwater_Fog						//Toggle fog underwater	
	
	#define Clouds								//Toggle clouds
		//#define Cloud_reflection				//Toggle clouds reflection in water
		
	#define Moonshading							//Toggle moon drawn by shaderpack. If disabled, enable default moon in: video settings -> details -> Sun & Moon: on	
/*---------------------------
//END OF ADJUSTABLE VARIABLES//
----------------------------*/

const int noiseTextureResolution = 256;
/*--------------------------------*/

varying vec2 texcoord;
varying vec2 lightPos;

varying vec3 sunVec;
varying vec3 upVec;
varying vec3 lightColor;
varying vec3 avgAmbient2;
varying vec3 sky1;
varying vec3 sky2;
varying vec3 nsunlight;
varying vec3 sunlight;
varying vec3 cloudColor;
varying vec3 cloudColor2;
const vec3 moonlight = vec3(0.0025, 0.0045, 0.007);

varying float tr;
varying float SdotU;
varying float sunVisibility;
varying float moonVisibility;

uniform sampler2D gdepth;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D gnormal;
uniform sampler2D gaux3;
uniform sampler2D gaux2;
uniform sampler2D gaux4;
uniform sampler2D noisetex;

uniform vec3 cameraPosition;
uniform vec3 sunPosition;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform int isEyeInWater;
uniform ivec2 eyeBrightness;
uniform int worldTime;
uniform float aspectRatio;
uniform float rainStrength;
uniform float frameTimeCounter;

uniform float near;
uniform float far;
float comp = 1.0-near/far/far;

float time = float(worldTime);
float night = clamp((time-13000.0)/300.0,0.0,1.0)-clamp((time-22800.0)/200.0,0.0,1.0);
float tmult = mix(min(abs(worldTime-6000.0)/6000.0,1.0),1.0,rainStrength);

vec3 getcolor(vec2 coord, float lod){
	return pow(texture2DLod(gdepth, coord, lod).xyz,vec3(2.2))*257.0;
}

//Used for Raytracing
vec3 nvec3(vec4 pos) {
    return pos.xyz/pos.w;
}
vec4 nvec4(vec3 pos) {
    return vec4(pos.xyz, 1.0);
}
float cdist(vec2 coord) {
	return max(abs(coord.s-0.5),abs(coord.t-0.5))*2.0;
}/*-----------------------------------------------------*/

#ifdef Clouds
float subSurfaceScattering(vec3 vec,vec3 pos, float N) {
	return pow(max(dot(vec,normalize(pos)),0.0),N)*(N+1)/6.28;
}

float noisetexture(vec2 coord){
	return texture2D(noisetex, coord).x;
}

vec3 drawCloud(vec3 fposition, vec3 color) {
const float r = 3.2;
const vec4 noiseC = vec4(1.0,r,r*r,r*r*r);
const vec4 noiseWeights = 1.0/noiseC/dot(1.0/noiseC,vec4(1.0));

vec3 normalfpos = normalize(fposition);
vec3 tpos = vec3(gbufferModelViewInverse * vec4(normalfpos, 0.0));
tpos = normalize(tpos);

float cosT = max(dot(normalfpos, upVec),0.0);

float wind = abs(frameTimeCounter/2000.0-0.5)+0.5;
float distortion = wind * 0.045;
	
float iMult = -log(cosT)*2.0+2.0;
float heightA = (400.0+300.0*sqrt(cosT))/(tpos.y);

for (int i = 1;i<22;i++) {
	vec3 intersection = tpos*(heightA-4.0*i*iMult); 			//curved cloud plane
	vec2 coord1 = intersection.xz/200000.0+wind*0.05;
	vec2 coord = fract(coord1/1.5);
	
	vec4 noiseSample = vec4(noisetexture(coord+distortion),
							noisetexture(coord*noiseC.y+distortion),
							noisetexture(coord*noiseC.z+distortion),
							noisetexture(coord*noiseC.w+distortion));

	float j = i / 22.0;
	coord = vec2(j+0.5,-j+0.5)/noiseTextureResolution + coord.xy + sin(coord.xy*3.14*j)/10.0 + wind*0.02*(j+0.5);
	
	vec2 secondcoord = 1.0 - coord.yx;
	vec4 noiseSample2 = vec4(noisetexture(secondcoord),
							 noisetexture(secondcoord*noiseC.y),
							 noisetexture(secondcoord*noiseC.z),
							 noisetexture(secondcoord*noiseC.w));

	float finalnoise = dot(noiseSample*noiseSample2,noiseWeights);
	float cl = max((sqrt(finalnoise*max(1.0-abs(i-11.0)/11*(0.15-1.7*rainStrength),0.0))-0.55)/(0.65+1.0*rainStrength)*clamp(cosT*cosT*2.0,0.0,1.0),0.0);

	float cMult = max(pow(30.0-i,3.5)/pow(30.,3.5),0.0)*6.0;

	float sunscattering = subSurfaceScattering(sunVec, fposition, 20.0)*pow(cl, 3.125);
	float moonscattering = subSurfaceScattering(-sunVec, fposition, 20.0)*pow(cl, 5.0);
	
	color = color*(1.0-cl)+cl*cMult*mix(cloudColor2,cloudColor,min(cMult,1.0)) * 0.1428 + sunscattering+moonscattering;
	}
return color;
}/*---------------------------*/
#endif

//Create fog
float getAirDensity (float h) {
	return (max((h),60.0))/10.;
}

float calcFog(vec3 fposition) {
	const float density = 300.0;

	vec3 worldpos = (gbufferModelViewInverse*vec4(fposition,1.0)).rgb+cameraPosition;
	float height = mix(getAirDensity(worldpos.y),6.,rainStrength*0.8);
	float d = length(fposition);

	return clamp(0.75/exp(-6.0/density)*exp(-getAirDensity(cameraPosition.y)/density) * (1.0-exp( -pow(d,2.712)*height/density/(6000.0-tmult*tmult*2000.0)/13.0*(1.0+rainStrength*50.0)))/height,0.0,1.0);
}/*---------------------------------*/

#ifdef Underwater_Fog
vec3 underwaterFog (float depth,vec3 color) {
	const float density = 48.0;
	float fog = exp(-depth/density);

	vec3 Ucolor= normalize(pow(vec3(0.1,0.4,0.6),vec3(2.2)))*(sqrt(3.0));
	
	vec3 c = mix(color*Ucolor,color,fog);
	vec3 fc = Ucolor*length(avgAmbient2)*0.02;
	return mix(fc,c,fog);
}
#endif

//Skycolor
vec3 getSkyc(vec3 fposition) {
vec3 sVector = normalize(fposition);

float invRain07 = 1.0-rainStrength*0.6;
float cosT = dot(sVector,upVec); 
float mCosT = max(cosT,0.0);
float absCosT = 1.0-max(cosT*0.82+0.26,0.2);
float cosS = SdotU;			
float cosY = dot(sunVec,sVector);
float Y = acos(cosY);	

const float a = -1.;
const float b = -0.25;
const float c = 4.0;
const float d = -2.5;
const float e = 0.3;

//luminance
float L =  (1.0+a*exp(b/(mCosT)));
float A = 1.0+e*cosY*cosY;

//gradient
vec3 grad1 = mix(sky1,sky2,absCosT*absCosT);
float sunscat = max(cosY,0.0);
vec3 grad3 = mix(grad1,nsunlight,sunscat*sunscat*(1.0-mCosT)*(1.0-rainStrength*0.5)*(clamp(-(cosS)*4.0+3.0,0.0,1.0)*0.65+0.35)*0.9+0.1);

float Y2 = 3.14159265359-Y;	
float L2 = L * (8.0*exp(d*Y2)+A);

const vec3 moonlight2 = pow(normalize(moonlight),vec3(3.0))*length(moonlight);
const vec3 moonlightRain = normalize(vec3(0.25,0.3,0.4))*length(moonlight);
vec3 gradN = mix(moonlight,moonlight2,1.-L2/2.0);
gradN = mix(gradN,moonlightRain,rainStrength);

return (1.6*grad3*pow(L*(c*exp(d*Y)+A),invRain07)*sunVisibility*vec3(0.85,0.88,1.0) *length(avgAmbient2)+ 0.4*gradN*pow(L2*1.2+1.6,invRain07)*moonVisibility);
}/*---------------------------------*/

//Draw sun and moon
vec3 drawSun(vec3 fposition, vec3 color, float vis) {
	vec3 sVector = normalize(fposition);
	float angle = (1.0-max(dot(sVector,sunVec),0.0))*650.0;
	float sun = exp(-angle*angle*angle);
			sun *= (1.0-rainStrength*0.999)*sunVisibility;
	vec3 sunlightB = mix(pow(sunlight,vec3(1.0))*44.0,vec3(0.25,0.3,0.4),rainStrength*0.8);

	return mix(color,sunlightB,sun*vis);
}
vec3 drawMoon(vec3 fposition, vec3 color, float vis) {
	vec3 sVector = normalize(fposition);
	float angle = (1.0-max(dot(sVector,-sunVec),0.0))*2000.0;
	float moon = exp(-angle*angle*angle);
			moon *= (1.0-rainStrength*0.999)*moonVisibility;
	vec3 moonlightC = mix(pow(moonlight*40.0,vec3(1.0))*44.0,vec3(0.25,0.3,0.4),rainStrength*0.8);

	return mix(color,moonlightC,moon*vis);
}/**--------------------------------------*/

vec3 decode (vec2 enc){
    vec2 fenc = enc*4-2;
    float f = dot(fenc,fenc);
    float g = sqrt(1-f/4.0);
    vec3 n;
    n.xy = fenc*g;
    n.z = 1-f/2;
    return n;
}

#ifdef Godrays
float makeRays(float offcoord){
	const float blurScale = 0.004;

	float distFix = clamp(distance(texcoord,lightPos)*50.-0.5,0.0,1.0);
	vec2 deltaTextCoord = normalize(texcoord - lightPos)*blurScale*distFix;
	vec2 adjustedCoord = texcoord - deltaTextCoord*4.0;
	
	return texture2DLod(gdepth, adjustedCoord + offcoord * deltaTextCoord, 2).a;		
}
#endif

/* If you reached this line, then you're probably about to break the agreement which you accepted by downloading Sildur's shaders!
So stop your doing and ask Sildur before copying anything which would break the agreement, unless you're Chocapic then go ahead ;)
--------------------------------------------------------------------------------------------------------------------------------*/

void main() {

vec3 c = getcolor(texcoord, 0); 

//Depth and fragpos
float depth0 = texture2D(depthtex0, texcoord).x;	
vec4 fragpos0 = gbufferProjectionInverse * (vec4(texcoord, depth0, 1.0) * 2.0 - 1.0);
fragpos0 /= fragpos0.w;
vec3 normalfragpos0 = normalize(fragpos0.xyz);
	
float depth1 = texture2D(depthtex1, texcoord).x;	
vec4 fragpos1 = gbufferProjectionInverse * (vec4(texcoord, depth1, 1.0) * 2.0 - 1.0);
fragpos1 /= fragpos1.w;	
/*--------------------------------------------------------------------------------------------*/	
	
#ifdef Underwater_Fog
	if (isEyeInWater == 1)c.rgb = underwaterFog(length(fragpos0),c.rgb);	
#endif

//draw Sky related things
if (depth1 > comp) {
	c = drawSun(fragpos1.xyz, c, 1.0);
#ifdef Moonshading	
	c = drawMoon(fragpos1.xyz, c, 1.0);
#endif
#ifdef Clouds
	float cosT = dot(normalize(fragpos1.xyz), upVec);	
	if (cosT > 0.0)c = drawCloud(fragpos1.xyz, c);
#endif
}

//Draw rain
 vec4 rain = texture2D(gaux4, texcoord);
 if (rainStrength > 0.01 && length(rain) > 0.001) {	
	float rainRGB = 0.25;
	float rainA = rain.r/1.5;
	
	float torch_lightmap = 6.4 - min(rain.g/rain.r * 6.16,5.6);
	torch_lightmap = 0.1 / torch_lightmap / torch_lightmap - 0.002595;
	
	vec3 rainC = rainRGB*(pow(max(dot(normalfragpos0,sunVec)*0.1+0.9,0.0),6.0)*(0.1+tr*0.9)*pow(sunlight,vec3(0.55))*sunVisibility+pow(max(dot(normalfragpos0,-sunVec)*0.05+0.95,0.0),6.0)*16.0*moonlight*moonVisibility)*0.12 + 0.05*rainRGB*length(avgAmbient2);
	rainC += torch_lightmap*vec3(1.68, 0.52, 0.22);
	c = c*(1.0-rainA)+rainC*1.2*rainA;
}/*------------------------------------*/

if (depth0 < comp){ //is land
	//Fog
	vec3 fogC = getSkyc(fragpos0.xyz)*(0.7+0.3*tmult)*(2.0-rainStrength*1.0)*4.0;
	float fogLand = calcFog(fragpos0.xyz);
	/*-------------------------------*/
	
	vec4 trp = texture2D(gaux3,texcoord.xy);
	bool transparency = dot(trp,trp) > 0.0;	
	
if (transparency) {
	vec3 normal = texture2D(gnormal, texcoord).xyz;
	float sky = normal.z;
	
	bool iswater = sky < 0.2499;
	bool isice = sky > 0.2499 && sky < 0.4999;
	
	if (iswater) sky *= 4.0;
	if (isice) sky = (sky - 0.25)*4.0;
	
	if (!iswater && !isice) sky = (sky - 0.5)*4.0;
		
	sky = max(sky-2./16.0,0.0)*1.14285714286;
	sky *= sky;
	
	normal = decode(normal.xy);
	
	bool reflective = dot(normal,normal) > 0.0;	
	
	normal = normalize(normal);
	

		//Water transparency
		float fogF2 = calcFog(fragpos1.xyz);
		
		if(iswater)c = mix(c,fogC*(1.0-isEyeInWater),fogF2-fogLand)/(2.0+4.0*night);
		else c = mix(c,fogC*(1.0-isEyeInWater),fogF2-fogLand);
		/*---------------------------------------------*/
		
		//Draw transparency
		vec4 alpha = vec4(2.2,2.2,2.2,1.0);
		vec4 finalAc = pow(texture2D(gaux2,texcoord.xy), alpha);
		float alphaT = clamp(length(trp.rgb),0.0,1.0);
		vec4 rawAlbedo = pow(trp, alpha);

		c = mix(c,c*(rawAlbedo.rgb*0.9999+0.0001)*sqrt(3.0),alphaT)*(1.0-alphaT) + finalAc.rgb;
		/*-----------------------------------------------------------------------------------------------*/
		
	//Reflections
	if (reflective && isEyeInWater == 0.0) {
		vec3 reflectedVector = reflect(normalfragpos0, normal);
		vec3 hV= normalize(reflectedVector - normalfragpos0);

		float normalDotEye = dot(hV, normalfragpos0);
		
		float F0 = 0.09;
		
		float fresnel = pow(clamp(1.0 + normalDotEye,0.0,1.0), 5.0) ;			
		fresnel = fresnel+F0*(1.0-fresnel);
			
	#ifdef Cloud_reflection
		vec3 sky_c = getSkyc(reflectedVector)+drawCloud(reflectedVector, vec3(0.0));
	#else
		vec3 sky_c = getSkyc(reflectedVector);
	#endif
		
		vec3 sunmoonreflection = (drawSun(reflectedVector, sky_c, 1.0)+drawMoon(reflectedVector, sky_c, 1.0)) / 2.0;		
		
		vec4 reflection = vec4(0.0);
		reflection.rgb = mix(sunmoonreflection*sky*(1.0-isEyeInWater), reflection.rgb, reflection.a);
		
		fresnel*= !(iswater|| isice)? pow(max(1.0-alphaT,0.01),0.8) : 1.0;
		
		float reflcpower = isice? 0.4 : 0.7;
		
		c = mix(c,reflection.rgb, min(fresnel,1.0)* reflcpower);
	}/*---------------------------------------------------------*/
}
	//Draw land fog
	c = mix(c,fogC*(1.0-isEyeInWater),fogLand);
	
}

#ifdef Godrays
	float sunpos = abs(dot(normalfragpos0,normalize(sunPosition.xyz)));
	float illuminationDecay = pow(sunpos,30.0)+pow(sunpos,16.0)*0.8+pow(sunpos,2.0)*0.125;
	
if (illuminationDecay > 0.001) {
	float GetRays = makeRays(1.0);
		  GetRays += makeRays(2.0);
		  GetRays += makeRays(3.0);
		  GetRays += makeRays(4.0);
		  GetRays += makeRays(5.0);
		  GetRays += makeRays(6.0);
		  GetRays += makeRays(7.0);

	vec3 grC = lightColor*Godrays_Density;
	c += grC*GetRays/7.0*illuminationDecay*(1.0-isEyeInWater);
}
#endif

	gl_FragData[0] = vec4(pow(c/257.0,vec3(0.454)), 1.0);
}