#version 120
#extension GL_ARB_shader_texture_lod : enable
#define MAX_COLOR_RANGE 48.0

/*
!! DO NOT REMOVE !!
This code is from  CYBOXshaders
Read the terms of modification and sharing before changing something below please !
!! DO NOT REMOVE !!
*/




//----------Details----------//
#define VIGNETTE
//----------End of Details----------//




//----------Lens Effects----------//
//#define LENS_EFFECTS
	#define LENS_STRENGTH 0.5
#define RAIN_DROPS
//----------End of Lens Effects----------//




//----------Details----------//
#define Post_Bloom
#define BASIC_DOF
	const float focal = 0.030;
    float aperture = 0.05;
    const float sizemult = 12.0;
		//#define Normal   //Normal DOF
		#define Smooth    //Smooth DOF
//----------End of Details----------//




///////////////////////////////
/////////Tonemapping///////////
///////////////////////////////

//tonemapping constants
float A = 1.0;		//brightness multiplier
float B = 0.37;		//black level (lower means darker and more constrasted, higher make the image whiter and less constrasted)
float C = 0.1;		//constrast level

///////////////////////////////
//END OF ADJUSTABLE VARIABLES//
///////////////////////////////

varying vec4 texcoord;

varying vec3 lightVector;
varying vec3 Vec;
varying vec3 moonVec;
varying vec3 upVec;

varying vec3 sunlight;
varying vec3 moonlight;
varying vec3 ambient_color;

varying float eyeAdapt;

varying float SdotU;
varying float MdotU;
varying float sunVisibility;
varying float moonVisibility;


uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;
uniform sampler2D noisetex;
uniform sampler2D gaux1;
uniform sampler2D gaux2;
uniform sampler2D gaux4;
uniform sampler2D composite;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;
uniform ivec2 eyeBrightness;
uniform ivec2 eyeBrightnessSmooth;
uniform int isEyeInWater;
uniform int worldTime;
uniform float aspectRatio;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform float wetness;
uniform float centerDepthSmooth;
uniform float frameTimeCounter;
uniform int fogMode;
vec3 sunPos = sunPosition;
float pw = 1.0/ viewWidth;
float ph = 1.0/ viewHeight;
float timefract = worldTime;

//Raining
float rainx = clamp(rainStrength, 0.0f, 2.0f)/2.0f;
float wetx  = clamp(wetness, 0.0f, 2.0f);

//Calculate Time of Day
float TimeSunrise  = ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0) + (1.0 - (clamp(timefract, 0.0, 4000.0)/4000.0));
float TimeNoon     = ((clamp(timefract, 0.0, 4000.0)) / 4000.0) - ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0);
float TimeSunset   = ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0) - ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0);
float TimeMidnight = ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0) - ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0);

const vec2 circle_offsets[60] = vec2[60](	vec2(  0.2165,  0.1250 ),
											vec2(  0.0000,  0.2500 ),
											vec2( -0.2165,  0.1250 ),
											vec2( -0.2165, -0.1250 ),
											vec2( -0.0000, -0.2500 ),
											vec2(  0.2165, -0.1250 ),
											vec2(  0.4330,  0.2500 ),
											vec2(  0.0000,  0.5000 ),
											vec2( -0.4330,  0.2500 ),
											vec2( -0.4330, -0.2500 ),
											vec2( -0.0000, -0.5000 ),
											vec2(  0.4330, -0.2500 ),
											vec2(  0.6495,  0.3750 ),
											vec2(  0.0000,  0.7500 ),
											vec2( -0.6495,  0.3750 ),
											vec2( -0.6495, -0.3750 ),
											vec2( -0.0000, -0.7500 ),
											vec2(  0.6495, -0.3750 ),
											vec2(  0.8660,  0.5000 ),
											vec2(  0.0000,  1.0000 ),
											vec2( -0.8660,  0.5000 ),
											vec2( -0.8660, -0.5000 ),
											vec2( -0.0000, -1.0000 ),
											vec2(  0.8660, -0.5000 ),
											vec2(  0.2163,  0.3754 ),
											vec2( -0.2170,  0.3750 ),
											vec2( -0.4333, -0.0004 ),
											vec2( -0.2163, -0.3754 ),
											vec2(  0.2170, -0.3750 ),
											vec2(  0.4333,  0.0004 ),
											vec2(  0.4328,  0.5004 ),
											vec2( -0.2170,  0.6250 ),
											vec2( -0.6498,  0.1246 ),
											vec2( -0.4328, -0.5004 ),
											vec2(  0.2170, -0.6250 ),
											vec2(  0.6498, -0.1246 ),
											vec2(  0.6493,  0.6254 ),
											vec2( -0.2170,  0.8750 ),
											vec2( -0.8663,  0.2496 ),
											vec2( -0.6493, -0.6254 ),
											vec2(  0.2170, -0.8750 ),
											vec2(  0.8663, -0.2496 ),
											vec2(  0.2160,  0.6259 ),
											vec2( -0.4340,  0.5000 ),
											vec2( -0.6500, -0.1259 ),
											vec2( -0.2160, -0.6259 ),
											vec2(  0.4340, -0.5000 ),
											vec2(  0.6500,  0.1259 ),
											vec2(  0.4325,  0.7509 ),
											vec2( -0.4340,  0.7500 ),
											vec2( -0.8665, -0.0009 ),
											vec2( -0.4325, -0.7509 ),
											vec2(  0.4340, -0.7500 ),
											vec2(  0.8665,  0.0009 ),
											vec2(  0.2158,  0.8763 ),
											vec2( -0.6510,  0.6250 ),
											vec2( -0.8668, -0.2513 ),
											vec2( -0.2158, -0.8763 ),
											vec2(  0.6510, -0.6250 ),
											vec2(  0.8668,  0.2513 ));

// Standard depth function.
float getDepth(float depth) {
    return 2.0 * near * far / (far + near - (2.0 * depth - 1.0) * (far - near));
}

float ld(float depth) {
    return (2.0 * near) / (far + near - depth * (far - near));
}

float luma(vec3 color) {
	return dot(color,vec3(0.299, 0.587, 0.114));
}



vec3 Uncharted2Tonemap(vec3 x) {
	float D = 0.2;
	float E = 0.02;
	float F = 0.3;
	float W = MAX_COLOR_RANGE;
	return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
}

float distratio(vec2 pos, vec2 pos2) {
	float xvect = pos.x*aspectRatio-pos2.x*aspectRatio;
	float yvect = pos.y-pos2.y;
	return sqrt(xvect*xvect + yvect*yvect);
}

float gen_circular_lens(vec2 center, float size) {
	float dist=distratio(center,texcoord.xy)/size;
	return exp(-dist*dist);
}

vec2 noisepattern(vec2 pos) {
	return vec2(abs(fract(sin(dot(pos ,vec2(18.9898f,28.633f))) * 4378.5453f)),abs(fract(sin(dot(pos.yx ,vec2(18.9898f,28.633f))) * 4378.5453f)));
}

float getnoise(vec2 pos) {
	return abs(fract(sin(dot(pos ,vec2(18.9898f,28.633f))) * 4378.5453f));
}

float cdist(vec2 coord) {
	return max(abs(coord.s-0.5),abs(coord.t-0.5))*2.0;
}



vec3 alphablend(vec3 c, vec3 ac, float a) {
vec3 n_ac = normalize(ac)*(1/sqrt(3.));
vec3 nc = sqrt(c*n_ac);
return mix(c,nc,a);
}

float smStep (float edge0,float edge1,float x) {

float t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
return t * t * (3.0 - 2.0 * t);
}
float dirtPattern (vec2 tc) {
	float noise = texture2D(noisetex,tc).x;
	noise += texture2D(noisetex,tc*3.5).x/3.5;
	noise += texture2D(noisetex,tc*12.25).x/12.25;
	noise += texture2D(noisetex,tc*42.87).x/42.87;
	return noise / 1.4472;
}
float matflag = texture2D(gaux1,texcoord.xy).g;

//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////

void main() {

	        const float pi = 3.14159265359;
                float rainlens = 0.0;
                const float lifetime = 4.0;		//water drop lifetime in seconds
	        float ftime = frameTimeCounter*2.0/lifetime;
                vec2 drop = vec2(0.0,fract(frameTimeCounter/20.0));            				int hand  = int(matflag > 0.75 && matflag < 0.85);

#ifdef RAIN_DROPS
		if (rainStrength > 0.02) {
		float gen = 1.0-fract((ftime+0.5)*0.5);
		vec2 pos = (noisepattern(vec2(-0.94386347*floor(ftime*0.5+0.25),floor(ftime*0.5+0.25))))*0.8+0.1 - drop;
		rainlens += gen_circular_lens(fract(pos),0.04)*gen*rainStrength;

		gen = 1.0-fract((ftime+1.0)*0.5);
		pos = (noisepattern(vec2(0.9347*floor(ftime*0.5+0.5),-0.2533282*floor(ftime*0.5+0.5))))*0.8+0.1- drop;
		rainlens += gen_circular_lens(fract(pos),0.023)*gen*rainStrength;

		gen = 1.0-fract((ftime+1.5)*0.5);
		pos = (noisepattern(vec2(0.785282*floor(ftime*0.5+0.75),-0.285282*floor(ftime*0.5+0.75))))*0.8+0.1- drop;
		rainlens += gen_circular_lens(fract(pos),0.03)*gen*rainStrength;

		gen =  1.0-fract(ftime*0.5);
		pos = (noisepattern(vec2(-0.347*floor(ftime*0.5),0.6847*floor(ftime*0.5))))*0.8+0.1- drop;
		rainlens += gen_circular_lens(fract(pos),0.05)*gen*rainStrength;

		gen = 1.0-fract((ftime+1.0)*0.5);
		pos = (noisepattern(vec2(0.8514*floor(ftime*0.5+0.5),-0.456874*floor(ftime*0.5+0.5))))*0.8+0.1- drop;
		rainlens += gen_circular_lens(fract(pos),0.020)*gen*rainStrength;

		gen = 1.0-fract((ftime+1.5)*0.5);
		pos = (noisepattern(vec2(0.845156*floor(ftime*0.5+0.75),-0.2457854*floor(ftime*0.5+0.75))))*0.8+0.1- drop;
		rainlens += gen_circular_lens(fract(pos),0.033)*gen*rainStrength;

		gen =  1.0-fract(ftime*0.5);
		pos = (noisepattern(vec2(-0.368*floor(ftime*0.5),0.8654*floor(ftime*0.5))))*0.8+0.1- drop;
		rainlens += gen_circular_lens(fract(pos),0.05)*gen*rainStrength*5;

		gen =  1.0-fract(ftime*0.5);
		pos = (noisepattern(vec2(-0.458*floor(ftime*0.5),0.7546*floor(ftime*0.5))))*0.8+0.1- drop;
		rainlens += gen_circular_lens(fract(pos),0.055)*gen*rainStrength*5;

		gen = 1.0-fract((ftime+1.0)*0.5);
		pos = (noisepattern(vec2(0.7532*floor(ftime*0.5+0.5),-0.54275*floor(ftime*0.5+0.5))))*0.8+0.1- drop;
		rainlens += gen_circular_lens(fract(pos),0.029)*gen*rainStrength*5;

		rainlens *= clamp((eyeBrightness.y-220)/15.0,0.0,1.0);
	}
#endif
	vec2 fake_refract = vec2(sin(frameTimeCounter + texcoord.x*100.0 + texcoord.y*50.0),cos(frameTimeCounter + texcoord.y*100.0 + texcoord.x*50.0)) ;
	vec2 newTC = texcoord.st + fake_refract * 0.01 * (rainlens+isEyeInWater*0.25);

	vec3 color = pow(texture2D(gaux2, newTC).rgb,vec3(2.2))*MAX_COLOR_RANGE;

	float fog = 1-(exp(-pow(ld(texture2D(depthtex0, newTC.st).r)/256.0*far,4.0-(2.7*rainStrength))*4.0));



	#ifdef BASIC_DOF

	//Circle Offset Pattern (Modified From Airlock42)

#ifdef Normal

	float z = ld(texture2D(depthtex0, newTC.st).r)*far;
	 float focus = ld(texture2D(depthtex0, vec2(0.5)).r)*far;
	 float pcoc = min(abs(aperture * (focal * (z - focus)) / (z * (focus - focal)))*sizemult,pw*5.0);

#endif

#ifdef Smooth

float z = texture2D(depthtex2, texcoord.st).x;
	float focus = centerDepthSmooth;
	float pcoc = (z-focus)/15;

#endif

	vec3 bcolor = color/MAX_COLOR_RANGE;

        if (pcoc > pw && hand < 0.9) {
		for ( int i = 0; i < 60; i++) {

	vec2 aspt = vec2(1.0,aspectRatio);
	vec2 shape = circle_offsets[i]*1.2;

	bcolor += pow(texture2D(gaux2, newTC.xy + shape*aspt*pcoc).rgb,vec3(2.2));
		}
	color.rgb = bcolor/60.0*MAX_COLOR_RANGE;
	}
	#endif


	#ifdef Post_Bloom

vec3 blur = vec3(0);
vec2 bloomcoord = texcoord.xy;

	blur += pow(texture2D(composite,bloomcoord/pow(2.0,2.0) + vec2(0.0,0.0)).rgb,vec3(2.2))*pow(6.0,0.25);
	blur += pow(texture2D(composite,bloomcoord/pow(2.0,3.0) + vec2(0.3,0.0)).rgb,vec3(2.2))*pow(5.0,0.25);
	blur += pow(texture2D(composite,bloomcoord/pow(2.0,4.0) + vec2(0.0,0.3)).rgb,vec3(2.2))*pow(4.0,0.25);
	blur += pow(texture2D(composite,bloomcoord/pow(2.0,5.0) + vec2(0.1,0.3)).rgb,vec3(2.2))*pow(3.0,0.25);
	blur += pow(texture2D(composite,bloomcoord/pow(2.0,6.0) + vec2(0.2,0.3)).rgb,vec3(2.2))*pow(2.0,0.25);
	blur += pow(texture2D(composite,bloomcoord/pow(2.0,7.0) + vec2(0.3,0.3)).rgb,vec3(2.2))*pow(1.0,0.25);
	//blur = pow(texture2D(composite,bloomcoord/2).rgb,vec3(2.2));

color.xyz = mix(color,blur*MAX_COLOR_RANGE,0.006);
//color = blur*MAX_COLOR_RANGE*0.006;
//color = vec3(pow(length(blur),0.5));
#endif

	float dirt = dirtPattern(texcoord.xy/100.);


	//Tonemapping
	vec3 curr = Uncharted2Tonemap(color);

	vec3 whiteScale = 1.0f/Uncharted2Tonemap(vec3(MAX_COLOR_RANGE));
	color = curr*whiteScale;


	#ifdef VIGNETTE
	float len = length(texcoord.xy-vec2(.5));
	float len2 = distratio(texcoord.xy,vec2(.5));
	float dc = mix(len,len2,0.3);
    float vignette = smStep(0.95, 0.15,  dc);
	color = mix(color,color*vignette,0.8);
	#endif



#ifdef LENS_EFFECTS
	vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
		tpos = vec4(tpos.xyz/tpos.w,1.0);
	vec2 lightPos = tpos.xy/tpos.z;
		lightPos = (lightPos + 1.0f)/2.0f;

float distof = min(min(1.0-lightPos.x,lightPos.x),min(1.0-lightPos.y,lightPos.y));
float fading = clamp(1.0-step(distof,0.1)+pow(distof*10.0,5.0),0.0,1.0);

float time = float(worldTime);
float transition_fading = 1.0-(clamp((time-12000.0)/300.0,0.0,1.0)-clamp((time-13000.0)/300.0,0.0,1.0) + clamp((time-22800.0)/200.0,0.0,1.0)-clamp((time-23400.0)/200.0,0.0,1.0));

float sunvisibility = min(texture2D(gaux2,vec2(0.0)).a*2.5,1.0) * (1.0-rainStrength*0.9) * fading * transition_fading;

float centerdist = distance(lightPos.xy,vec2(0.5))/1.0;
float sizemult = 2.0 + centerdist;
float noise = fract(sin(dot(texcoord.st ,vec2(18.9898f,28.633f))) * 4378.5453f)*0.1 + 0.9;






vec3 sP = sunPosition;

			vec2 lPos = lightPos;

			if (fading > 0.01 && TimeMidnight < 1.0) {

			float sunmask = 0.0f;
			float sunstep = -4.5f;
			float masksize = 0.004f;

			sunmask = texture2D(gaux2,vec2(0.0)).a;

			sunmask *= LENS_STRENGTH * (2.0f - TimeMidnight)*fading;
			sunmask *= 1.0 - rainx;

			if (sunmask > 0.02) {

			//Detect if sun is on edge of screen
				float edgemaskx = clamp(distance(lPos.x, 0.5f)*8.0f - 3.0f, 0.0f, 1.0f);
				float edgemasky = clamp(distance(lPos.y, 0.5f)*8.0f - 3.0f, 0.0f, 1.0f);

				const float flaremultR = 1.5f;
				const float flaremultG = 1.5f;
				const float flaremultB = 1.5f;

			////Darken colors if the sun is visible
				float centermask = 1.0 - clamp(distance(lPos.xy, vec2(0.5f, 0.5f))*2.0, 0.0, 1.0);
				centermask = pow(centermask, 1.0f);
				centermask *= sunmask;

				float flarescale = 1.0f;
				const float flarescaleconst = 1.0f;

			//Flare gets bigger at center of screen
				flarescale *= (1.5 - centermask);


	//anamorphic lens
			  vec2 flareANAscale = vec2(0.65f*flarescale, 40.0f*flarescale);
			  float flareANApow = 0.5f;
			  float flareANAfill = 1.0f;
			  float flareANAoffset = -2.0f;
			vec2 flareANApos = vec2(  ((1.0 - lPos.x)*(flareANAoffset + 1.0) - (flareANAoffset*0.5))  *aspectRatio*flareANAscale.x,  ((1.0 - lPos.y)*(flareANAoffset + 1.0) - (flareANAoffset*0.5))  *flareANAscale.y);


			float flareANA = distance(flareANApos, vec2(texcoord.s*aspectRatio*flareANAscale.x, texcoord.t*flareANAscale.y));
				  flareANA = 0.5 - flareANA;
				  flareANA = clamp(flareANA*flareANAfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flareANA = sin(flareANA*1.57075);
				  flareANA *= sunmask;
				  flareANA = pow(flareANA, 1.1f);

				  flareANA *= flareANApow;

				  	color.r += flareANA*0.75f*flaremultR;
					color.g += flareANA*1.0f*flaremultG;
					color.b += flareANA*1.5f*flaremultB;

		//anamorphic lens 2
			  vec2 flareANA2scale = vec2(0.75f*flarescale, 7.5f*flarescale);
			  float flareANA2pow = 0.5f;
			  float flareANA2fill = 1.0f;
			  float flareANA2offset = -2.0f;
			vec2 flareANA2pos = vec2(  ((1.0 - lPos.x)*(flareANA2offset + 1.0) - (flareANA2offset*0.5))  *aspectRatio*flareANA2scale.x,  ((1.0 - lPos.y)*(flareANA2offset + 1.0) - (flareANA2offset*0.5))  *flareANA2scale.y);


			float flareANA2 = distance(flareANA2pos, vec2(texcoord.s*aspectRatio*flareANA2scale.x, texcoord.t*flareANA2scale.y));
				  flareANA2 = 0.5 - flareANA2;
				  flareANA2 = clamp(flareANA2*flareANA2fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flareANA2 = sin(flareANA2*1.57075);
				  flareANA2 *= sunmask;
				  flareANA2 = pow(flareANA2, 1.1f);

				  flareANA2 *= flareANA2pow;

				  	color.r += flareANA2*0.75f*flaremultR;
					color.g += flareANA2*1.0f*flaremultG;
					color.b += flareANA2*1.5f*flaremultB;

		//anamorphic lens3
			  vec2 flareANA3scale = vec2(40.0f*flarescale, 0.65f*flarescale);
			  float flareANA3pow = 0.5f;
			  float flareANA3fill = 1.0f;
			  float flareANA3offset = -2.0f;
			vec2 flareANA3pos = vec2(  ((1.0 - lPos.x)*(flareANA3offset + 1.0) - (flareANA3offset*0.5))  *aspectRatio*flareANA3scale.x,  ((1.0 - lPos.y)*(flareANA3offset + 1.0) - (flareANA3offset*0.5))  *flareANA3scale.y);


			float flareANA3 = distance(flareANA3pos, vec2(texcoord.s*aspectRatio*flareANA3scale.x, texcoord.t*flareANA3scale.y));
				  flareANA3 = 0.5 - flareANA3;
				  flareANA3 = clamp(flareANA3*flareANA3fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flareANA3 = sin(flareANA3*1.57075);
				  flareANA3 *= sunmask;
				  flareANA3 = pow(flareANA3, 1.1f);

				  flareANA3 *= flareANA3pow;

				  	color.r += flareANA3*0.75f*flaremultR;
					color.g += flareANA3*1.0f*flaremultG;
					color.b += flareANA3*1.5f*flaremultB;

		//anamorphic lens 4
			  vec2 flareANA4scale = vec2(7.5f*flarescale, 0.75f*flarescale);
			  float flareANA4pow = 0.5f;
			  float flareANA4fill = 1.0f;
			  float flareANA4offset = -2.0f;
			vec2 flareANA4pos = vec2(  ((1.0 - lPos.x)*(flareANA4offset + 1.0) - (flareANA4offset*0.5))  *aspectRatio*flareANA4scale.x,  ((1.0 - lPos.y)*(flareANA4offset + 1.0) - (flareANA4offset*0.5))  *flareANA4scale.y);


			float flareANA4 = distance(flareANA4pos, vec2(texcoord.s*aspectRatio*flareANA4scale.x, texcoord.t*flareANA4scale.y));
				  flareANA4 = 0.5 - flareANA4;
				  flareANA4 = clamp(flareANA4*flareANA4fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flareANA4 = sin(flareANA4*1.57075);
				  flareANA4 *= sunmask;
				  flareANA4 = pow(flareANA4, 1.1f);

				  flareANA4 *= flareANA4pow;

				  	color.r += flareANA4*0.75f*flaremultR;
					color.g += flareANA4*1.0f*flaremultG;
					color.b += flareANA4*1.5f*flaremultB;


	//--//far rings around the sun//--//

	//far red ring
			  vec2 flare4ARscale = vec2(1.43f*flarescale, 1.43f*flarescale);
			  float flare4ARpow = 0.2f;
			  float flare4ARfill = 10.0f;
			  float flare4ARoffset = -2.0f;
			vec2 flare4ARpos = vec2(  ((1.0 - lPos.x)*(flare4ARoffset + 1.0) - (flare4ARoffset*0.5))  *aspectRatio*flare4ARscale.x,  ((1.0 - lPos.y)*(flare4ARoffset + 1.0) - (flare4ARoffset*0.5))  *flare4ARscale.y);


			float flare4AR = distance(flare4ARpos, vec2(texcoord.s*aspectRatio*flare4ARscale.x, texcoord.t*flare4ARscale.y));
				  flare4AR = 0.5 - flare4AR;
				  flare4AR = clamp(flare4AR*flare4ARfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare4AR = pow(flare4AR, 1.6f);
				  flare4AR = sin(flare4AR*3.1415);
				  flare4AR *= sunmask;


				  flare4AR *= flare4ARpow;

				  	color.r += flare4AR*0.4f*flaremultR;
					color.g += flare4AR*0.0f*flaremultG;
					color.b += flare4AR*0.0f*flaremultB;

	//far green ring

			  vec2 flare8ARscale = vec2(1.35f*flarescale, 1.35f*flarescale);
			  float flare8ARpow = 0.2f;
			  float flare8ARfill = 10.0f;
			  float flare8ARoffset = -2.0f;
			vec2 flare8ARpos = vec2(  ((1.0 - lPos.x)*(flare8ARoffset + 1.0) - (flare8ARoffset*0.5))  *aspectRatio*flare8ARscale.x,  ((1.0 - lPos.y)*(flare8ARoffset + 1.0) - (flare8ARoffset*0.5))  *flare8ARscale.y);


			float flare8AR = distance(flare8ARpos, vec2(texcoord.s*aspectRatio*flare8ARscale.x, texcoord.t*flare8ARscale.y));
				  flare8AR = 0.5 - flare8AR;
				  flare8AR = clamp(flare8AR*flare8ARfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare8AR = pow(flare8AR, 1.9f);
				  flare8AR = sin(flare8AR*3.1415);
				  flare8AR *= sunmask;


				  flare8AR *= flare8ARpow;

				  	color.r += flare8AR*0.0f*flaremultR;
					color.g += flare8AR*0.4f*flaremultG;
					color.b += flare8AR*0.0f*flaremultB;

	//far blue ring

			  vec2 flare9ARscale = vec2(1.25f*flarescale, 1.25*flarescale);
			  float flare9ARpow = 0.4f;
			  float flare9ARfill = 10.0f;
			  float flare9ARoffset = -2.0f;
			vec2 flare9ARpos = vec2(  ((1.0 - lPos.x)*(flare9ARoffset + 1.0) - (flare9ARoffset*0.5))  *aspectRatio*flare9ARscale.x,  ((1.0 - lPos.y)*(flare9ARoffset + 1.0) - (flare9ARoffset*0.5))  *flare9ARscale.y);


			float flare9AR = distance(flare9ARpos, vec2(texcoord.s*aspectRatio*flare9ARscale.x, texcoord.t*flare9ARscale.y));
				  flare9AR = 0.5 - flare9AR;
				  flare9AR = clamp(flare9AR*flare9ARfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare9AR = pow(flare9AR, 1.9f);
				  flare9AR = sin(flare9AR*3.1415);
				  flare9AR *= sunmask;


				  flare9AR *= flare9ARpow;

				  	color.r += flare9AR*0.0f*flaremultR;
					color.g += flare9AR*0.0f*flaremultG;
					color.b += flare9AR*0.4*flaremultB;


	//-//far lens flares//-//

	//far small flare 2AF
			  vec2 flare2AFscale = vec2(56.5f*flarescale, 56.5f*flarescale);
			  float flare2AFpow = 0.7f;
			  float flare2AFfill = 3.0f;
			  float flare2AFoffset = -1.1731f;
			vec2 flare2AFpos = vec2(  ((1.0 - lPos.x)*(flare2AFoffset + 1.0) - (flare2AFoffset*0.5))  *aspectRatio*flare2AFscale.x,  ((1.0 - lPos.y)*(flare2AFoffset + 1.0) - (flare2AFoffset*0.5))  *flare2AFscale.y);


			float flare2AF = distance(flare2AFpos, vec2(texcoord.s*aspectRatio*flare2AFscale.x, texcoord.t*flare2AFscale.y));
				  flare2AF = 0.5 - flare2AF;
				  flare2AF = clamp(flare2AF*flare2AFfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare2AF = sin(flare2AF*1.57075);
				  flare2AF *= sunmask;
				  flare2AF = pow(flare2AF, 1.1f);

				  flare2AF *= flare2AFpow;

				  	color.r += flare2AF*0.4f*flaremultR;
					color.g += flare2AF*0.4f*flaremultG;
					color.b += flare2AF*0.0f*flaremultB;


	//far small flare 1AF
			  vec2 flare1AFscale = vec2(60.5f*flarescale, 60.5f*flarescale);
			  float flare1AFpow = 1.7f;
			  float flare1AFfill = 3.0f;
			  float flare1AFoffset = -1.1f;
			vec2 flare1AFpos = vec2(  ((1.0 - lPos.x)*(flare1AFoffset + 1.0) - (flare1AFoffset*0.5))  *aspectRatio*flare1AFscale.x,  ((1.0 - lPos.y)*(flare1AFoffset + 1.0) - (flare1AFoffset*0.5))  *flare1AFscale.y);


			float flare1AF = distance(flare1AFpos, vec2(texcoord.s*aspectRatio*flare1AFscale.x, texcoord.t*flare1AFscale.y));
				  flare1AF = 0.5 - flare1AF;
				  flare1AF = clamp(flare1AF*flare1AFfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare1AF = sin(flare1AF*1.57075);
				  flare1AF *= sunmask;
				  flare1AF = pow(flare1AF, 1.1f);

				  flare1AF *= flare1AFpow;

				  	color.r += flare1AF*0.0f*flaremultR;
					color.g += flare1AF*0.25f*flaremultG;
					color.b += flare1AF*0.05f*flaremultB;

		//far small flare 3AF
			  vec2 flare3AFscale = vec2(30.5f*flarescale, 30.5f*flarescale);
			  float flare3AFpow = 0.7f;
			  float flare3AFfill = 3.0f;
			  float flare3AFoffset = -1.0731f;
			vec2 flare3AFpos = vec2(  ((1.0 - lPos.x)*(flare3AFoffset + 1.0) - (flare3AFoffset*0.5))  *aspectRatio*flare3AFscale.x,  ((1.0 - lPos.y)*(flare3AFoffset + 1.0) - (flare3AFoffset*0.5))  *flare3AFscale.y);


			float flare3AF = distance(flare3AFpos, vec2(texcoord.s*aspectRatio*flare3AFscale.x, texcoord.t*flare3AFscale.y));
				  flare3AF = 0.5 - flare3AF;
				  flare3AF = clamp(flare3AF*flare3AFfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare3AF = sin(flare3AF*1.57075);
				  flare3AF *= sunmask;
				  flare3AF = pow(flare3AF, 1.1f);

				  flare3AF *= flare3AFpow;

				  	color.r += flare3AF*0.0f*flaremultR;
					color.g += flare3AF*0.25f*flaremultG;
					color.b += flare3AF*0.50f*flaremultB;

			//far orange circle flare
			  vec2 flare3Gscale = vec2(2.199f*flarescale, 2.199*flarescale);
			  float flare3Gpow = 0.4f;
			  float flare3Gfill = 10.0f;
			  float flare3Goffset = -2.0f;
			vec2 flare3Gpos = vec2(  ((1.0 - lPos.x)*(flare3Goffset + 1.0) - (flare3Goffset*0.5))  *aspectRatio*flare3Gscale.x,  ((1.0 - lPos.y)*(flare3Goffset + 1.0) - (flare3Goffset*0.5))  *flare3Gscale.y);


			float flare3G = distance(flare3Gpos, vec2(texcoord.s*aspectRatio*flare3Gscale.x, texcoord.t*flare3Gscale.y));
				  flare3G = 0.5 - flare3G;
				  flare3G = clamp(flare3G*flare3Gfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare3G = sin(flare3G*1.57075);

				  flare3G = pow(flare3G, 1.1f);

				  flare3G *= flare3Gpow;

			//subtract of orange circle flare
				  vec2 flare3Hscale = vec2(2.5f*flarescale, 2.5f*flarescale);
				  float flare3Hpow = 5.4f;
				  float flare3Hfill = 3.4f;
				  float flare3Hoffset = -2.0f;
				vec2 flare3Hpos = vec2(  ((1.0 - lPos.x)*(flare3Hoffset + 1.0) - (flare3Hoffset*0.5))  *aspectRatio*flare3Hscale.x,  ((1.0 - lPos.y)*(flare3Hoffset + 1.0) - (flare3Hoffset*0.5))  *flare3Hscale.y);


				float flare3H = distance(flare3Hpos, vec2(texcoord.s*aspectRatio*flare3Hscale.x, texcoord.t*flare3Hscale.y));
					flare3H = 0.5 - flare3H;
					flare3H = clamp(flare3H*flare3Hfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
					flare3H = sin(flare3H*1.57075);
					flare3H = pow(flare3H, 0.9f);

					flare3H *= flare3Hpow;

				flare3G = clamp(flare3G - flare3H, 0.0, 10.0);
				flare3G *= sunmask;

				  	color.r += flare3G*1.0f*flaremultR;
					color.g += flare3G*0.3f*flaremultG;
					color.b += flare3G*0.2f*flaremultB;



	//-//close lens flares//-//

	//close small flare 2A
			  vec2 flare2Ascale = vec2(24.5f*flarescale, 24.5f*flarescale);
			  float flare2Apow = 1.0f;
			  float flare2Afill = 3.0f;
			  float flare2Aoffset = -0.4231f;
			vec2 flare2Apos = vec2(  ((1.0 - lPos.x)*(flare2Aoffset + 1.0) - (flare2Aoffset*0.5))  *aspectRatio*flare2Ascale.x,  ((1.0 - lPos.y)*(flare2Aoffset + 1.0) - (flare2Aoffset*0.5))  *flare2Ascale.y);


			float flare2A = distance(flare2Apos, vec2(texcoord.s*aspectRatio*flare2Ascale.x, texcoord.t*flare2Ascale.y));
				  flare2A = 0.5 - flare2A;
				  flare2A = clamp(flare2A*flare2Afill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare2A = sin(flare2A*1.57075);
				  flare2A *= sunmask;
				  flare2A = pow(flare2A, 1.1f);

				  flare2A *= flare2Apow;

				  	color.r += flare2A*0.1f*flaremultR;
					color.g += flare2A*0.2f*flaremultG;
					color.b += flare2A*0.25f*flaremultB;

	//close small flare 4A
			  vec2 flare4Ascale = vec2(3.5f*flarescale, 3.5f*flarescale);
			  float flare4Apow = 1.0f;
			  float flare4Afill = 3.0f;
			  float flare4Aoffset = -0.0231f;
			vec2 flare4Apos = vec2(  ((1.0 - lPos.x)*(flare4Aoffset + 1.0) - (flare4Aoffset*0.5))  *aspectRatio*flare4Ascale.x,  ((1.0 - lPos.y)*(flare4Aoffset + 1.0) - (flare4Aoffset*0.5))  *flare4Ascale.y);


			float flare4A = distance(flare4Apos, vec2(texcoord.s*aspectRatio*flare4Ascale.x, texcoord.t*flare4Ascale.y));
				  flare4A = 0.5 - flare4A;
				  flare4A = clamp(flare4A*flare4Afill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare4A = sin(flare4A*1.57075);
				  flare4A *= sunmask;
				  flare4A = pow(flare4A, 1.1f);

				  flare4A *= flare4Apow;

				  	color.r += flare4A*0.25f*flaremultR;
					color.g += flare4A*0.0f*flaremultG;
					color.b += flare4A*0.1f*flaremultB;

			//close big flare 8A
			  vec2 flare8Ascale = vec2(3.3f*flarescale, 3.3f*flarescale);
			  float flare8Apow = 1.0f;
			  float flare8Afill = 3.0f;
			  float flare8Aoffset = -0.8231f;
			vec2 flare8Apos = vec2(  ((1.0 - lPos.x)*(flare8Aoffset + 1.0) - (flare8Aoffset*0.5))  *aspectRatio*flare8Ascale.x,  ((1.0 - lPos.y)*(flare8Aoffset + 1.0) - (flare8Aoffset*0.5))  *flare8Ascale.y);


			float flare8A = distance(flare8Apos, vec2(texcoord.s*aspectRatio*flare8Ascale.x, texcoord.t*flare8Ascale.y));
				  flare8A = 0.5 - flare8A;
				  flare8A = clamp(flare8A*flare8Afill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare8A = sin(flare8A*1.57075);
				  flare8A *= sunmask;
				  flare8A = pow(flare8A, 1.1f);

				  flare8A *= flare8Apow;

				  	color.r += flare8A*0.0f*flaremultR;
					color.g += flare8A*0.2f*flaremultG;
					color.b += flare8A*0.4f*flaremultB;

		//close small flare 9A
			  vec2 flare9Ascale = vec2(58.5f*flarescale, 58.5f*flarescale);
			  float flare9Apow = 1.0f;
			  float flare9Afill = 3.0f;
			  float flare9Aoffset = -0.6731f;
			vec2 flare9Apos = vec2(  ((1.0 - lPos.x)*(flare9Aoffset + 1.0) - (flare9Aoffset*0.5))  *aspectRatio*flare9Ascale.x,  ((1.0 - lPos.y)*(flare9Aoffset + 1.0) - (flare9Aoffset*0.5))  *flare9Ascale.y);


			float flare9A = distance(flare9Apos, vec2(texcoord.s*aspectRatio*flare9Ascale.x, texcoord.t*flare9Ascale.y));
				  flare9A = 0.5 - flare9A;
				  flare9A = clamp(flare9A*flare9Afill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare9A = sin(flare9A*1.57075);
				  flare9A *= sunmask;
				  flare9A = pow(flare9A, 1.1f);

				  flare9A *= flare9Apow;

				  	color.r += flare9A*0.50f*flaremultR;
					color.g += flare9A*0.1f*flaremultG;
					color.b += flare9A*0.125f*flaremultB;

	//close small flare 10A
			  vec2 flare10Ascale = vec2(36.5f*flarescale, 36.5f*flarescale);
			  float flare10Apow = 1.0f;
			  float flare10Afill = 3.0f;
			  float flare10Aoffset = -0.6231f;
			vec2 flare10Apos = vec2(  ((1.0 - lPos.x)*(flare10Aoffset + 1.0) - (flare10Aoffset*0.5))  *aspectRatio*flare10Ascale.x,  ((1.0 - lPos.y)*(flare10Aoffset + 1.0) - (flare10Aoffset*0.5))  *flare10Ascale.y);


			float flare10A = distance(flare10Apos, vec2(texcoord.s*aspectRatio*flare10Ascale.x, texcoord.t*flare10Ascale.y));
				  flare10A = 0.5 - flare10A;
				  flare10A = clamp(flare10A*flare10Afill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare10A = sin(flare10A*1.57075);
				  flare10A *= sunmask;
				  flare10A = pow(flare10A, 1.1f);

				  flare10A *= flare10Apow;

				  	color.r += flare10A*0.05f*flaremultR;
					color.g += flare10A*0.5f*flaremultG;
					color.b += flare10A*0.25f*flaremultB;

			//close blue flare
			  vec2 flare3Cscale = vec2(2.8f*flarescale, 2.8f*flarescale);
			  float flare3Cpow = 2.6f;
			  float flare3Cfill = 10.0f;
			  float flare3Coffset = 0.1f;
			vec2 flare3Cpos = vec2(  ((1.0 - lPos.x)*(flare3Coffset + 1.0) - (flare3Coffset*0.5))  *aspectRatio*flare3Cscale.x,  ((1.0 - lPos.y)*(flare3Coffset + 1.0) - (flare3Coffset*0.5))  *flare3Cscale.y);


			float flare3C = distance(flare3Cpos, vec2(texcoord.s*aspectRatio*flare3Cscale.x, texcoord.t*flare3Cscale.y));
				  flare3C = 0.5 - flare3C;
				  flare3C = clamp(flare3C*flare3Cfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare3C = sin(flare3C*1.57075);

				  flare3C = pow(flare3C, 1.1f);

				  flare3C *= flare3Cpow;


			//subtract of blue flare
				  vec2 flare3Dscale = vec2(1.8f*flarescale, 1.8f*flarescale);
				  float flare3Dpow = 5.4f;
				  float flare3Dfill = 1.375f;
				  float flare3Doffset = -0.0f;
				vec2 flare3Dpos = vec2(  ((1.0 - lPos.x)*(flare3Doffset + 1.0) - (flare3Doffset*0.5))  *aspectRatio*flare3Dscale.x,  ((1.0 - lPos.y)*(flare3Doffset + 1.0) - (flare3Doffset*0.5))  *flare3Dscale.y);


				float flare3D = distance(flare3Dpos, vec2(texcoord.s*aspectRatio*flare3Dscale.x, texcoord.t*flare3Dscale.y));
					flare3D = 0.5 - flare3D;
					flare3D = clamp(flare3D*flare3Dfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
					flare3D = sin(flare3D*1.57075);
					flare3D = pow(flare3D, 0.9f);

					flare3D *= flare3Dpow;

				flare3C = clamp(flare3C - flare3D, 0.0, 10.0);
				flare3C *= sunmask;

				  	color.r += flare3C*0.25f*flaremultR;
					color.g += flare3C*0.25f*flaremultG;
					color.b += flare3C*0.25f*flaremultB;

			//close blue flare2
			  vec2 flare3Escale = vec2(2.7f*flarescale, 2.7f*flarescale);
			  float flare3Epow = 1.7f;
			  float flare3Efill = 10.0f;
			  float flare3Eoffset = -0.3f;
			vec2 flare3Epos = vec2(  ((1.0 - lPos.x)*(flare3Eoffset + 1.0) - (flare3Eoffset*0.5))  *aspectRatio*flare3Escale.x,  ((1.0 - lPos.y)*(flare3Eoffset + 1.0) - (flare3Eoffset*0.5))  *flare3Escale.y);


			float flare3E = distance(flare3Epos, vec2(texcoord.s*aspectRatio*flare3Escale.x, texcoord.t*flare3Escale.y));
				  flare3E = 0.5 - flare3E;
				  flare3E = clamp(flare3E*flare3Efill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare3E = sin(flare3E*1.57075);

				  flare3E = pow(flare3E, 1.1f);

				  flare3E *= flare3Epow;

			//subtract of blue flare2
				  vec2 flare3Fscale = vec2(1.4f*flarescale, 1.4f*flarescale);
				  float flare3Fpow = 2.7f;
				  float flare3Ffill = 1.4f;
				  float flare3Foffset = -0.4f;
				vec2 flare3Fpos = vec2(  ((1.0 - lPos.x)*(flare3Foffset + 1.0) - (flare3Foffset*0.5))  *aspectRatio*flare3Fscale.x,  ((1.0 - lPos.y)*(flare3Foffset + 1.0) - (flare3Foffset*0.5))  *flare3Fscale.y);


				float flare3F = distance(flare3Fpos, vec2(texcoord.s*aspectRatio*flare3Fscale.x, texcoord.t*flare3Fscale.y));
					flare3F = 0.5 - flare3F;
					flare3F = clamp(flare3F*flare3Ffill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
					flare3F = sin(flare3F*1.57075);
					flare3F = pow(flare3F, 0.9f);

					flare3F *= flare3Fpow;

				flare3E = clamp(flare3E - flare3F, 0.0, 10.0);
				flare3E *= sunmask;

				  	color.r += flare3E*0.25f*flaremultR;
					color.g += flare3E*0.25f*flaremultG;
					color.b += flare3E*0.25f*flaremultB;


	//-//far rings around the sun//-//

	//close red ring

			  vec2 flare5ARscale = vec2(0.86f*flarescale, 0.86f*flarescale);
			  float flare5ARpow = 0.5f;
			  float flare5ARfill = 15.0f;
			  float flare5ARoffset = 2.6f;
			vec2 flare5ARpos = vec2(  ((1.0 - lPos.x)*(flare5ARoffset + 1.0) - (flare5ARoffset*0.5))  *aspectRatio*flare5ARscale.x,  ((1.0 - lPos.y)*(flare5ARoffset + 1.0) - (flare5ARoffset*0.5))  *flare5ARscale.y);


			float flare5AR = distance(flare5ARpos, vec2(texcoord.s*aspectRatio*flare5ARscale.x, texcoord.t*flare5ARscale.y));
				  flare5AR = 0.5 - flare5AR;
				  flare5AR = clamp(flare5AR*flare5ARfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare5AR = pow(flare5AR, 1.9f);
				  flare5AR = sin(flare5AR*3.1415);
				  flare5AR *= sunmask;


				  flare5AR *= flare5ARpow;

				  color.r += flare5AR*0.2f*flaremultR;
					color.g += flare5AR*0.0f*flaremultG;
					color.b += flare5AR*0.0f*flaremultB;

			//close green ring

			  vec2 flare6ARscale = vec2(0.9f*flarescale, 0.9f*flarescale);
			  float flare6ARpow = 0.5f;
			  float flare6ARfill = 15.0f;
			  float flare6ARoffset = 2.6f;
			vec2 flare6ARpos = vec2(  ((1.0 - lPos.x)*(flare6ARoffset + 1.0) - (flare6ARoffset*0.5))  *aspectRatio*flare6ARscale.x,  ((1.0 - lPos.y)*(flare6ARoffset + 1.0) - (flare6ARoffset*0.5))  *flare6ARscale.y);


			float flare6AR = distance(flare6ARpos, vec2(texcoord.s*aspectRatio*flare6ARscale.x, texcoord.t*flare6ARscale.y));
				  flare6AR = 0.5 - flare6AR;
				  flare6AR = clamp(flare6AR*flare6ARfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare6AR = pow(flare6AR, 1.9f);
				  flare6AR = sin(flare6AR*3.1415);
				  flare6AR *= sunmask;


				  flare6AR *= flare6ARpow;

				  	color.r += flare6AR*0.0f*flaremultR;
					color.g += flare6AR*0.15f*flaremultG;
					color.b += flare6AR*0.0f*flaremultB;

			//close blue ring

			  vec2 flare7ARscale = vec2(0.94f*flarescale, 0.94f*flarescale);
			  float flare7ARpow = 1.0f;
			  float flare7ARfill = 15.0f;
			  float flare7ARoffset = 2.6f;
			vec2 flare7ARpos = vec2(  ((1.0 - lPos.x)*(flare7ARoffset + 1.0) - (flare7ARoffset*0.5))  *aspectRatio*flare7ARscale.x,  ((1.0 - lPos.y)*(flare7ARoffset + 1.0) - (flare7ARoffset*0.5))  *flare7ARscale.y);


			float flare7AR = distance(flare7ARpos, vec2(texcoord.s*aspectRatio*flare7ARscale.x, texcoord.t*flare7ARscale.y));
				  flare7AR = 0.5 - flare7AR;
				  flare7AR = clamp(flare7AR*flare7ARfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare7AR = pow(flare7AR, 0.9f);
				  flare7AR = sin(flare7AR*3.1415);
				  flare7AR *= sunmask;


				  flare7AR *= flare7ARpow;

				  	color.r += flare7AR*0.0f*flaremultR;
					color.g += flare7AR*0.0f*flaremultG;
					color.b += flare7AR*0.2*flaremultB;

	//-//end of the flares//-//
			}
}





#endif


         float saturation = 1.000;


        float avg = (color.r + color.g + color.b);

        color = (((color - avg )*saturation)+avg) ;
		color /= saturation;

	color = clamp(pow(color,vec3(1.0/2.2)),0.0,1.0);

	     color.r = color.r*1.0;

	     color.g = color.g*1.0;

	     color.b = color.b*1.0;



	gl_FragColor = vec4(color,1.0);
}
