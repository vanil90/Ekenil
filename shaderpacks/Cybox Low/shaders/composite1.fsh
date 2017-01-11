#version 120


#define MAX_COLOR_RANGE 48.0
/*
!! DO NOT REMOVE !!
This code is from CYBOX shaders
Read the terms of modification and sharing before changing something below please !
!! DO NOT REMOVE !!
*/

//////////////////////////////
/////ADJUSTABLE VARIABLES/////
//////////////////////////////




//----------Sky----------//
	#define Clouds
		#define CLOUD_SIZE 0.8
		#define MOON_VISIBILITY 0.8 			//Changes the cloud visibility
    #define Stars
//----------End of Sky----------//




//----------Reflections----------//
	//#define WATER_REFLECTIONS
		#define REFLECTION_STRENGTH 1.0

//#define RAIN_REFLECTIONS
#define Rain_REFLECTION_STRENGTH 0.1; //The lower the number the stronger the specular reflections
//----------End of Reflections----------//




//----------Extra----------//
	#define MOTIONBLUR //Do not disable change the 0.04 on line 589 to zero
#define MOTIONBLUR_AMOUNT 10.0
//----------End of Extra----------//




///////////////////////////////
//END OF ADJUSTABLE VARIABLES//
///////////////////////////////
const int 		noiseTextureResolution  = 500;

//don't touch these lines if you don't know what you do!
const int maxf = 5;				//number of refinements
const float stp = 1.0;			//size of one step for raytracing algorithm
const float ref = 0.12;			//refinement multiplier
const float inc = 1.48;			//increasement factor at each step

//ground constants (lower quality)
const int Gmaxf = 3;				//number of refinements
const float Gstp = 1.2;			//size of one step for raytracing algorithm
const float Gref = 0.11;			//refinement multiplier
const float Ginc = 3.0;			//increasement factor at each step

varying vec4 texcoord;

varying vec3 lightVector;
varying vec3 sunVec;
varying vec3 moonVec;
varying vec3 upVec;

varying vec3 sunlight;
varying vec3 moonlight;
varying vec3 ambient_color;
varying vec3 fcolor;

varying float eyeAdapt;

varying float SdotU;
varying float MdotU;
varying float sunVisibility;
varying float moonVisibility;

uniform sampler2D composite;
uniform sampler2D gaux1;
uniform sampler2D gaux2;
uniform sampler2D gaux3;
uniform sampler2D gaux4;

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;

uniform sampler2D gnormal;
uniform sampler2D gdepth;
uniform sampler2D noisetex;

uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 upPosition;
uniform vec3 cameraPosition;
uniform vec3 skyColor;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousModelView;
uniform vec3 previousCameraPosition;

uniform int isEyeInWater;
uniform int worldTime;
uniform float far;
uniform float near;
uniform float aspectRatio;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform float wetness;
uniform float frameTimeCounter;
uniform int fogMode;
uniform float centerDepthSmooth;
uniform ivec2 eyeBrightnessSmooth;

float timefract = worldTime;
float TimeSunrise  = ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0) + (1.0 - (clamp(timefract, 0.0, 4000.0)/4000.0));
float TimeNoon     = ((clamp(timefract, 0.0, 4000.0)) / 4000.0) - ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0);
float TimeSunset   = ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0) - ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0);
float TimeMidnight = ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0) - ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0);

/*--------------------------------*/
vec2 wind[4] = vec2[4](vec2(abs(frameTimeCounter/1000.-0.5),abs(frameTimeCounter/1000.-0.5))+vec2(0.5),
					vec2(-abs(frameTimeCounter/1000.-0.5),abs(frameTimeCounter/1000.-0.5)),
					vec2(-abs(frameTimeCounter/1000.-0.5),-abs(frameTimeCounter/1000.-0.5)),
					vec2(abs(frameTimeCounter/1000.-0.5),-abs(frameTimeCounter/1000.-0.5)));
/*--------------------------------*/

float pw = 1.0/ viewWidth;
float ph = 1.0/ viewHeight;
float matflag = texture2D(gaux1,texcoord.xy).g;

vec3 fragpos = vec3(texcoord.st, texture2D(depthtex0, texcoord.st).r);
vec3 normal = texture2D(gnormal, texcoord.st).rgb * 2.0 - 1.0;

float time = float(worldTime);
float night = clamp((time-12000.0)/300.0,0.0,1.0)-clamp((time-22800.0)/200.0,0.0,1.0);

float sky_lightmap = texture2D(gaux1,texcoord.xy).r;

vec4 color = texture2D(composite,texcoord.xy);


vec3 nvec3(vec4 pos) {
    return pos.xyz/pos.w;
}

vec4 nvec4(vec3 pos) {
    return vec4(pos.xyz, 1.0);
}

float cdist(vec2 coord) {
	return max(abs(coord.s-0.5),abs(coord.t-0.5))*2.0;
}



vec3 getSkyColor(vec3 fposition) {
//sky gradient
/*----------*/
vec3 sky_color = vec3(0.1, 0.35, 1.);
vec3 nsunlight = normalize(pow(sunlight,vec3(2.2)));
vec3 sVector = normalize(fposition);

sky_color = normalize(mix(sky_color,vec3(0.25,0.3,0.4)*length(ambient_color),rainStrength)); //normalize colors in order to don't change luminance

float Lz = 1.0;
float cosT = dot(sVector,upVec);
float absCosT = max(cosT,0.0);
float cosS = dot(sunVec,upVec);
float S = acos(cosS);
float cosY = dot(sunVec,sVector);
float Y = acos(cosY);
float a = -0.8;
float b = -0.2;
float c = 7.0;
float d = -0.8;
float e = 3.0;

//sun sky color
float L =  (1+a*exp(b/(absCosT+0.01)))*(1+c*exp(d*Y)+e*cosY*cosY);
L = pow(L,1.0-rainStrength*0.8)*(1.0-rainStrength*0.2); //modulate intensity when raining
vec3 skyColorSun = mix(sky_color, nsunlight,1-exp(-0.05*L*(1-rainStrength*1.0)))*L*0.16 ; //affect color based on luminance (0% physically accurate)
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

sky_color = skyColormoon*2.0+skyColorSun;
//sky_color = vec3(Lc);
/*----------*/
return sky_color;
}


vec3 drawSun(vec3 fposition,vec3 color,int land) {
vec3 sVector = normalize(fposition);

float angle = (1-max(dot(sVector,sunVec),0.0))*250.0;
float sun = exp(-angle*angle);
sun *= land*(1-rainStrength*0.)*sunVisibility;
vec3 sunlight = mix(sunlight,vec3(0.25,0.3,0.4)*length(ambient_color)*4.,rainStrength*0.8);

return mix(color,sunlight*40.,sun);

}

vec3 skyGradient (vec3 fposition, vec3 color, vec3 fogclr) {

	return (fogclr*3.+color)/4.;


}

vec3 calcFog(vec3 fposition, vec3 color, vec3 fogclr) {
	const float density = 700.0;
	const float start = 0.02;
	float rainFog = 1.0+20.0*rainStrength;
	float fog = min(exp(-length(fposition)/density/(sunVisibility*1.2+0.5)*rainFog)+start*sunVisibility*(1-rainStrength),1.0);

	vec3 fc = fogclr*1.5;
	return mix(fc,color,fog);
}


float subSurfaceScattering(vec3 vec,vec3 pos, float N) {

return pow(max(dot(vec,normalize(pos)),0.0),N)*(N+1)/6.28;

}
float subSurfaceScattering2(vec3 vec,vec3 pos, float N) {

return pow(max(dot(vec,normalize(pos))*0.5+0.5,0.0),N)*(N+1)/6.28;

}


vec3 simplifiedCloud(vec3 fposition,vec3 color) {
/*--------------------------------*/
vec3 sVector = normalize(fposition);
float cosT = max(dot(normalize(sVector),upVec),0.0);
float McosY = MdotU;
float cosY = SdotU;
vec3 tpos = vec3(gbufferModelViewInverse * vec4(fposition,1.0));
vec3 wvec = normalize(tpos);
vec3 wVector = normalize(tpos);
/*--------------------------------*/
vec4 totalcloud = vec4(.0);
/*--------------------------------*/
vec3 intersection = wVector*((-400.0)/(wVector.y));
vec3 iSpos = (gbufferModelView*vec4(intersection,1.0)).rgb;
float cosT2 = pow(0.89,distance(vec2(0.0),intersection.xz)/100);
/*--------------------------------*/
for (int i = 0;i<7;i++) {
	intersection = wVector*((-cameraPosition.y+500.0-i*3.66*(1+cosT2*cosT2*3.5)+400*sqrt(cosT2))/(wVector.y)); 			//curved cloud plane
	vec3 wpos = tpos.xyz+cameraPosition;
	vec2 coord1 = (intersection.xz+cameraPosition.xz)/1000.0/140.+wind[0]*0.07;
	vec2 coord = fract(coord1/2.0);
	/*--------------------------------*/
	float noise = texture2D(noisetex,coord).x;
	noise += texture2D(noisetex,coord*3.5).x/3.5;
	noise += texture2D(noisetex,coord*12.25).x/12.25;
	noise /= 1.4238;
	coord += mix(cos(coord.x+wind[0]), cos(coord.y+wind[0]), coord);
	/*--------------------------------*/
	float cl = max(noise-0.6  +rainStrength*0.4,0.0)*(1-rainStrength*0.4);
	float density = max(1-cl*2.5,0.)*max(1-cl*2.5,0.)*(i/7.)*(i/7.);
	/*--------------------------------*/
	vec3 c =(ambient_color + mix(sunlight,length(sunlight)*vec3(0.25,0.32,0.4),rainStrength)*sunVisibility + mix(moonlight,length(moonlight)*vec3(0.25,0.32,0.4),rainStrength) * moonVisibility) * 0.12 *density + (24.*subSurfaceScattering(sunVec,fposition,10.0)*pow(density,3.) + 10.*subSurfaceScattering2(sunVec,fposition,0.1)*pow(density,2.))*mix(sunlight,length(sunlight)*vec3(0.25,0.32,0.4),rainStrength)*sunVisibility +  (24.*subSurfaceScattering(moonVec,fposition,10.0)*pow(density,3.) + 10.*subSurfaceScattering2(moonVec,fposition,0.1)*pow(density,2.))*mix(moonlight,length(moonlight)*vec3(0.25,0.32,0.4),rainStrength)*moonVisibility;
	cl = max(cl-(abs(i-3.0)/3.)*0.15,0.)*0.146;
	/*--------------------------------*/
	totalcloud += vec4(c.rgb*exp(-totalcloud.a),cl);
	totalcloud.a = min(totalcloud.a,1.0);
	/*--------------------------------*/
	if (totalcloud.a > 0.999) break;
}

return mix(color.rgb,totalcloud.rgb*(1 - rainStrength*0.87)*6.,totalcloud.a*pow(cosT2,1.2));

}

vec4 raytrace(vec3 fragpos, vec3 normal,vec3 fogclr) {
    vec4 color = vec4(0.0);
    vec3 start = fragpos;
    vec3 rvector = normalize(reflect(normalize(fragpos), normalize(normal)));
    vec3 vector = stp * rvector;
    vec3 oldpos = fragpos;
    fragpos += vector;
	vec3 tvector = vector;
    int sr = 0;
    for(int i=0;i<40;i++){
        vec3 pos = nvec3(gbufferProjection * nvec4(fragpos)) * 0.5 + 0.5;
        if(pos.x < 0 || pos.x > 1 || pos.y < 0 || pos.y > 1 || pos.z < 0 || pos.z > 1.0) break;
        vec3 spos = vec3(pos.st, texture2D(depthtex1, pos.st).r);
        spos = nvec3(gbufferProjectionInverse * nvec4(spos * 2.0 - 1.0));
        float err = abs(fragpos.z-spos.z);
	if(err < pow(length(vector)*1.85,1.15)){

                sr++;
                if(sr >= maxf){
                    float border = clamp(1.0 - pow(cdist(pos.st), 20.0), 0.0, 1.0);
                    color = texture2D(composite, pos.st);
					float land = texture2D(gaux1, pos.st).g;
					land = float(land < 0.03);
					spos.z = mix(fragpos.z,20000.0*(0.4+sunVisibility*0.6),land);
					color.rgb = calcFog(spos,pow(color.rgb,vec3(2.2))*MAX_COLOR_RANGE,fogclr);
					color.a = 1.0;
                    color.a *= border;
                    break;
                }
				tvector -=vector;
                vector *=ref;


}
        vector *= inc;
        oldpos = fragpos;
        tvector += vector;
		fragpos = start + tvector;
    }
    return color;
}

#ifdef Clouds
vec3 drawCloud(vec3 fposition,vec3 color) {
/*--------------------------------*/
vec3 sVector = normalize(fposition);
float cosT = max(dot(normalize(sVector),upVec),0.0);
float McosY = MdotU;
float cosY = SdotU;
vec3 tpos = vec3(gbufferModelViewInverse * vec4(fposition,1.0));
vec3 wvec = normalize(tpos);
vec3 wVector = normalize(tpos);
/*--------------------------------*/
vec4 totalcloud = vec4(.0);
/*--------------------------------*/
vec3 intersection = wVector*((-cameraPosition.y+400.0+400*sqrt(cosT))/(wVector.y));
vec3 iSpos = (gbufferModelView*vec4(intersection,1.0)).rgb;
float cosT2 = max(dot(normalize(iSpos),upVec),0.0);

/*--------------------------------*/
for (int i = 0;i<10;i++) {
	intersection = wVector*((-cameraPosition.y+200.0-i*3.*(1+cosT2*cosT2*3.5)+500*sqrt(cosT2))/(wVector.y)); 			//curved cloud plane
	vec3 wpos = tpos.xyz+cameraPosition;
	vec2 coord1 = (intersection.xz+cameraPosition.xz)/1000.0*CLOUD_SIZE/140.+wind[0]*0.07;
	vec2 coord = fract(coord1/2.0);

	/*--------------------------------*/
	float noise = texture2D(noisetex,coord+frameTimeCounter/16000).x;
	noise += texture2D(noisetex,coord*3.5).x/3.5;
	noise += texture2D(noisetex,coord*12.25).x/12.25;
	noise += texture2D(noisetex,coord*42.87).x/42.87;
	noise /= 1.4472;
	/*--------------------------------*/
	float cl = max(noise-0.6  +rainStrength*0.4,0.0)*(1-rainStrength*0.4);
	float density = max(1-cl*2.5,0.)*max(1-cl*2.5,0.)*(i/11.)*(i/11.);
	/*--------------------------------*/
	vec3 c =(ambient_color + mix(sunlight,length(sunlight)*vec3(0.25,0.32,0.4),rainStrength)*sunVisibility + mix(moonlight,length(moonlight)*vec3(0.25,0.32,0.4),rainStrength) * moonVisibility) * 0.12*1.6 *density + (24.*subSurfaceScattering(sunVec,fragpos,10.0)*pow(density,3.) + 10.*subSurfaceScattering2(sunVec,fragpos,0.1)*pow(density,2.))*mix(sunlight,length(sunlight)*vec3(0.25,0.32,0.4),rainStrength)*sunVisibility +  (24.*subSurfaceScattering(moonVec,fragpos,10.0)*pow(density,3.) + 10.*subSurfaceScattering2(moonVec,fragpos,0.1)*pow(density,2.))*mix(moonlight,length(moonlight)*vec3(0.25,0.32,0.4),rainStrength)*moonVisibility;
	cl = max(cl-(abs(i-5.)/5.)*0.15,0.)*0.12;
	/*--------------------------------*/
	totalcloud += vec4(c.rgb*exp(-totalcloud.a),cl);
	totalcloud.a = min(totalcloud.a,1.0);
	/*--------------------------------*/
	if (totalcloud.a > 0.999) break;
}

return mix(color.rgb,totalcloud.rgb*(1 - rainStrength*0.87)*33.7,totalcloud.a*pow(cosT2,1.2));

}
#endif

#ifdef Stars

vec3 drawStar(vec3 fposition,vec3 color) {
vec3 sVector = normalize(fposition);
float cosT = dot(sVector,upVec);
float McosY = MdotU;
float cosY = SdotU;
//star generation
/*----------*/
vec3 tpos = vec3(gbufferModelViewInverse * vec4(fposition,1.0));
vec3 wvec = normalize(tpos);
vec3 wVector = normalize(tpos);
vec3 intersection = wVector*(50.0/(wVector.y));



//float canHit = length(intersection)-length(tpos);

	vec2 wind = vec2(abs(frameTimeCounter/1000.-0.5),abs(frameTimeCounter/1000.-0.5));


	vec3 wpos = tpos.xyz+cameraPosition;
	intersection.xz = intersection.xz + 5.0*cosT*intersection.xz;		//curve the star pattern, because sky is not 100% plane in reality
	vec2 coord = (intersection.xz+wind*10)/512.0;
	vec2 coord1 = (intersection.xz+wind*10)/512.0;
	float noise = texture2D(noisetex,fract(coord.xy/2.0)).x;

	  float N = 8.0;
vec3 star_color = vec3(1.0, 1.0, 1.0)*1.0*moonVisibility*(1-rainStrength) + moonlight*48.0*pow(max(McosY,0.0),N)*(N+1)/6.28  * (1-rainStrength)*moonVisibility ;	//coloring stars
/*----------*/

	noise += texture2D(noisetex,fract(coord.xy)).x/2.0;
	noise += texture2D(noisetex,fract(coord1.xy)).x/2.0;

	float cl = max(noise-1.7,0.0);
	float ef = 0.01;

      float star2 = (1.0 - (pow((1-rainStrength*0.9)*ef,cl)))*max(cosT,0.0);


vec3 s = mix(color,star_color,star2);



//s = mix(s,star_color,star);  //mix up sky color and stars



return s;
}
#endif
vec4 raytraceGround(vec3 fragpos, vec3 normal, vec3 fogclr) {
    vec4 color = vec4(0.0);
    vec3 start = fragpos;
    vec3 rvector = normalize(reflect(normalize(fragpos), normalize(normal)));
    vec3 vector = Gstp * rvector;
    vec3 oldpos = fragpos;
    fragpos += vector;
	vec3 tvector = vector;
    int sr = 0;
    for(int i=0;i<30;i++){
        vec3 pos = nvec3(gbufferProjection * nvec4(fragpos)) * 0.5 + 0.5;
		if(pos.x < 0 || pos.x > 1 || pos.y < 0 || pos.y > 1 || pos.z < 0 || pos.z > 1.0) break;
        vec3 spos = vec3(pos.st, texture2D(depthtex1, pos.st).r);
        spos = nvec3(gbufferProjectionInverse * nvec4(spos * 2.0 - 1.0));
        float err = distance(fragpos.xyz,spos.xyz);
        if(err < length(vector)){

                sr++;
                if(sr >= maxf){
                    float border = clamp(1.0 - pow(cdist(pos.st), 20.0), 0.0, 1.0);
                    color = texture2D(composite, pos.st);
					float land = texture2D(gaux1, pos.st).g;
					land = float(matflag < 0.03);
					spos.z = mix(fragpos.z,2000.0*(0.25+sunVisibility*0.75),land);
					color.rgb = calcFog(spos,pow(color.rgb,vec3(2.2))*MAX_COLOR_RANGE,fogclr);
					color.a = 1.0;
                    color.a *= border;
                    break;
                }
				tvector -=vector;
                vector *=Gref;


}
        vector *= Ginc;
        oldpos = fragpos;
        tvector += vector;
		fragpos = start + tvector;
    }
    return color;
}
vec3 underwaterFog (float depth,vec3 color) {
	const float density = 100.0;
	float fog = exp(-depth/density);
	vec3 Ucolor= normalize(pow(vec3(0.13,0.4,0.54),vec3(2.2)))*(sqrt(3.0));

	vec3 c = mix(color*Ucolor,color,fog);
	vec3 fc = Ucolor*length(ambient_color)*0.05;
	return mix(fc,c,fog);
}
float waterH(vec3 posxz) {

float wave = 0.0;


float factor = 0.0;
float amplitude = 0.0;
float speed = 0.0;
float size = 0.0;

float px = posxz.x/50.0 + 250.0;
float py = posxz.z/50.0  + 250.0;

float fpx = abs(fract(px*20.0)-0.5)*2.0;
float fpy = abs(fract(py*20.0)-0.5)*2.0;

float d = length(vec2(fpx,fpy));

for (int i = 1; i < 4; i++) {
wave -= d*factor*cos( (1/factor)*px*py*size + 1.0*frameTimeCounter*speed);
factor /= 2;
}

factor = 0.0;
px = -posxz.x/50.0 + 250.0;
py = -posxz.z/150.0 - 250.0;

fpx = abs(fract(px*20.0)-0.5)*2.0;
fpy = abs(fract(py*20.0)-0.5)*2.0;

d = length(vec2(fpx,fpy));
float wave2 = 2.0;
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
	color.rgb = pow(color.rgb,vec3(2.2))*MAX_COLOR_RANGE;
	int land = int(matflag < 0.03);
	int iswater = int(matflag > 0.04 && matflag < 0.07);
	int hand  = int(matflag > 0.75 && matflag < 0.85);

	fragpos = nvec3(gbufferProjectionInverse * nvec4(fragpos * 2.0 - 1.0));
	vec3 tfpos = fragpos.xyz;
	if (land > 0.9) fragpos = (gbufferModelView*(gbufferModelViewInverse*vec4(fragpos,1.0)+vec4(.0,max(cameraPosition.y-70.,.0),.0,.0))).rgb;
	vec3 uPos  = nvec3(gbufferProjectionInverse * nvec4(vec3(texcoord.xy,texture2D(depthtex1,texcoord.xy).x) * 2.0 - 1.0));		//underwater position
	color.rgb = drawSun(fragpos,color.rgb,land);
	float cosT = dot(normalize(fragpos),upVec);
	vec3 fogclr = getSkyColor(fragpos.xyz);
	uPos.z = mix(uPos.z,2000.0*(0.25+sunVisibility*0.75),land);
		float normalDotEye = dot(normal, normalize(fragpos));
		float fresnel = pow(1.0 + normalDotEye, 5.0);
		fresnel = mix(1.,fresnel,0.98);


	#ifdef MOTIONBLUR


	if (iswater > 0.9) {

	} else {
	vec4 depth  = texture2D(depthtex2, texcoord.st);

	vec4 currentPosition = vec4(texcoord.x * 2.0f - 1.0f, texcoord.y * 2.0f - 1.0f, 2.0f * depth.x - 1.0f, 1.0f);

	vec4 fragposition = gbufferProjectionInverse * currentPosition;
	fragposition = gbufferModelViewInverse * fragposition;
	fragposition /= fragposition.w;
	fragposition.xyz += cameraPosition;


	vec4 previousPosition = fragposition;
	previousPosition.xyz -= previousCameraPosition;
	previousPosition = gbufferPreviousModelView * previousPosition;
	previousPosition = gbufferPreviousProjection * previousPosition;
	previousPosition /= previousPosition.w;

//vec3 bcolor = color/MAX_COLOR_RANGE;
	vec2 velocity = (currentPosition - previousPosition).st * 0.0;

	int samples = 1;

	vec2 coord = texcoord.st + velocity;
	for (int i = 0; i < 6; ++i, coord += velocity) {
		if (coord.s > 1.0 || coord.t > 1.0 || coord.s < 0.0 || coord.t < 0.0) {
			break;
		}
            color += texture2D(composite, coord),color.rgb, iswater;
			++samples;
	}

	color.rgb *= 25.0;


	//Colour Properties
		float Tonemap_Contrast 		= 1.34;
		float Tonemap_Saturation 	= 1.3;
		float Tonemap_Decay			= 19.0;
		float Tonemap_Curve			= 130.0;

	color.rgb += 3.501;

	vec3 colorN = normalize(color.rgb);

	vec3 clrfr = color.rgb/colorN.rgb;
	     clrfr = pow(clrfr.rgb, vec3(Tonemap_Contrast));

	colorN.rgb = pow(colorN.rgb, vec3(Tonemap_Saturation));

	color.rgb = clrfr.rgb * colorN.rgb;

	color.rgb = (color.rgb * (0.7 + color.rgb/Tonemap_Decay))/(color.rgb + Tonemap_Curve)/samples;
}


#endif


				vec3 lc = mix(vec3(0.0),sunlight,sunVisibility);
		vec4 reflection = vec4(0.0);
		vec3 npos = normalize(fragpos);
		vec3 reflectedVector = reflect(normalize(fragpos), normalize(normal));
		reflectedVector = fragpos + reflectedVector * (2048.0-fragpos.z);
		vec3 skyc = getSkyColor(reflectedVector);
		vec3 sky_color = calcFog(reflectedVector,drawCloud(reflectedVector,vec3(0.0)),skyc)*clamp(sky_lightmap*2.0-2/16.0,0.0,1.0);






		#ifdef RAIN_REFLECTIONS
		 if (isEyeInWater < 0.9 && iswater < 0.1 && land < .1) {

		vec3 sky_color = calcFog(reflectedVector,drawCloud(reflectedVector,vec3(0.0)),skyc)*clamp(sky_lightmap*2.0-2/16.0,0.0,1.0);
		 reflection = raytraceGround(fragpos, normal, skyc);
		 reflection.rgb = mix(sky_color, reflection.rgb, reflection.a)+(color.a)*64.0;			//fake sky reflection, avoid empty spaces
		 reflection.rgb = reflection.rgb/Rain_REFLECTION_STRENGTH;
		 reflection.a = min(reflection.a + 1.0*sky_lightmap,0.01);

		  float iswet = wetness*pow(sky_lightmap,5.0)*sqrt(0.5+max(dot(normal,normalize(upPosition)),0.0));


		  color.rgb += (reflection.rgb*1*fresnel*7.0*reflection.a)*iswet*rainStrength;
		  }

	   #endif

#ifdef Clouds
	if (land > 0.1 && hand < 0.1) {
			if (cosT > 0.) color.rgb = drawCloud(tfpos.xyz,color.rgb);
}
#endif
#ifdef Stars
	if (land > 0.9 && moonVisibility > 0.1) color.rgb = drawStar(fragpos.xyz,color.rgb);
#endif

	if (hand < 0.1) color.rgb = calcFog(uPos.xyz,color.rgb,fogclr);
	if (isEyeInWater == 1) color.rgb = underwaterFog(length(fragpos),color.rgb);

	vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
	tpos = vec4(tpos.xyz/tpos.w,1.0);
	vec2 pos1 = tpos.xy/tpos.z;
	vec2 lightPos = pos1*0.5+0.5;
	float gr = 0.0;


	float visiblesun = 0.0;
	float temp;
	float nb = 0;

//calculate sun occlusion (only on one pixel)
if (texcoord.x < 3.0*pw && texcoord.x < 3.0*ph) {
	for (int i = 0; i < 100;i++) {
		for (int j = 0; j < 10 ;j++) {
		temp = texture2D(gaux1,lightPos + vec2(pw*(i-5.0)*10.0,ph*(j-5.0)*10.0)).g;
		visiblesun +=  1.0-float(temp > 0.04) ;
		nb += 1;
		}
	}
	visiblesun /= nb;

}

	color.rgb = clamp(pow(color.rgb/MAX_COLOR_RANGE,vec3(1.0/2.2)),0.0,1.0);

/* DRAWBUFFERS:5 */
	gl_FragData[0] = vec4(color.rgb,visiblesun);
}
