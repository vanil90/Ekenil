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
//#define Eye_Brightness
//----------End of Details----------//




//----------Details----------//
#define Post_Bloom
#define BASIC_DOF
	const float focal = 0.030;
    float aperture = 0.05;
    const float sizemult = 12.0;
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
varying vec3 sunVec;
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

	vec2 fake_refract = vec2(sin(frameTimeCounter + texcoord.x*100.0 + texcoord.y*50.0),cos(frameTimeCounter + texcoord.y*100.0 + texcoord.x*50.0)) ;
	vec2 newTC = texcoord.st + fake_refract * 0.01 * (rainlens+isEyeInWater*0.25);

	vec3 color = pow(texture2D(gaux2, newTC).rgb,vec3(2.2))*MAX_COLOR_RANGE;

	float fog = 1-(exp(-pow(ld(texture2D(depthtex0, newTC.st).r)/256.0*far,4.0-(2.7*rainStrength))*4.0));



	#ifdef BASIC_DOF

	//Circle Offset Pattern (Modified From Airlock42)

	float z = texture2D(depthtex2, texcoord.st).x;
    float focus = centerDepthSmooth;
    float pcoc = (z-focus)/15;

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



         float saturation = 1.000;


        float avg = (color.r + color.g + color.b);

        color = (((color - avg )*saturation)+avg) ;
		color /= saturation;

		#ifdef Eye_Brightness

color.rgb += color.rgb * clamp((-eyeBrightnessSmooth.y+220)/300.0,0.0,1.0)*4.0;

#endif

	color = clamp(pow(color,vec3(1.0/2.2)),0.0,1.0);

	     color.r = color.r*1.0;

	     color.g = color.g*1.0;

	     color.b = color.b*1.0;



	gl_FragColor = vec4(color,1.0);
}
