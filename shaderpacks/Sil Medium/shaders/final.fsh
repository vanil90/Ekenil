#version 120
/*
                            _____ _____ ___________ 
                           /  ___|_   _|  _  | ___ \
                           \ `--.  | | | | | | |_/ /
                            `--. \ | | | | | |  __/ 
                           /\__/ / | | \ \_/ / |    
                           \____/  \_/  \___/\_|
						Before editing anything here make sure you've 
						read The agreement, which you accepted by downloading
						my shaderpack. The agreement can be found here:
			http://www.minecraftforum.net/topic/1953873-164-172-sildurs-shaders-pcmacintel/
						   
				This code is from Chocapic13' shaders adapted, modified and tweaked by Sildur 
		http://www.minecraftforum.net/forums/mapping-and-modding/minecraft-mods/1293898-chocapic13s-shaders			
*/

/*--------------------
//ADJUSTABLE VARIABLES//
---------------------*/

#define Rain_Drops						//Enables rain drops on screen during raining. Requires sun effects to be enabled. Low performance impact.

//#define Depth_of_Field				//Simulates eye focusing on objects. Low performance impact
	//#define Distance_Blur				//Requires Depth of Field to be enabled, replaces eye focusing effect with distance being blurred instead.

//#define Motionblur					//Blurres your view/camera during movemenent, low performance impact. Doesn't work well with Depth of Field.

#define Colorboost						//Toggle color boost, without it colors are closer to default - less vibrant.

/*---------------------------
//END OF ADJUSTABLE VARIABLES//
----------------------------*/	
	
//Defined values for Optifine
#define DoF_Strength 90					//[60 70 80 90 100 110 120 130 140 150]
#define Dof_Distance_View 256			//[128 256 384 512]
/*----------------------------*/	
varying vec2 texcoord;
varying vec2 rainPos1;
varying vec2 rainPos2;
varying vec2 rainPos3;
varying vec2 rainPos4;
varying vec3 avgAmbient;
varying vec4 weights;

varying float eyeAdapt;

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D gnormal;
uniform sampler2D composite;

uniform int isEyeInWater;
uniform float aspectRatio;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform float frameTimeCounter;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;

uniform float near;
uniform float far;
float comp = 1.0-near/far/far;			//distance above that are considered as sky


#ifdef Depth_of_Field
//Dof constant values
const float focal = 0.024;
float aperture = 0.008;	
const float sizemult = DoF_Strength;
	
float ld(float depth) {
    return (2.0 * near) / (far + near - depth * (far - near));
}	
	
	//hexagon pattern
	const vec2 hex_offsets[60] = vec2[60] (	vec2(  0.2165,  0.1250 ),
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
#endif

//Tonemap
vec3 Uncharted2Tonemap(vec3 x) {
	const float A = 0.2;
	const float B = 0.3;
	const float C = 0.09;
	const float E = 0.024;
#ifdef Colorboost	
	const float D = 0.3;
	const float F = 0.4;
#else	
	const float D = 0.03;
	const float F = 4.0;
#endif	
	return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
}

#ifdef Rain_Drops
float distratio(vec2 pos, vec2 pos2) {
	return distance(pos*vec2(aspectRatio,1.0),pos2*vec2(aspectRatio,1.0));
}
float gen_circular_lens(vec2 center, float size) {
	float dist=distratio(center,texcoord.xy)/size;
	return exp(-dist*dist);
}
#endif

/* If you reached this line, then you're probably about to break the agreement which you accepted by downloading Sildur's shaders!
So stop your doing and ask Sildur before copying anything which would break the agreement, unless you're Chocapic then go ahead ;)
--------------------------------------------------------------------------------------------------------------------------------*/ 

void main() {
	
	//Rain lens flare
	float rainlens = 0.0;
	#ifdef Rain_Drops
	if (rainStrength > 0.02) {
		rainlens += gen_circular_lens(rainPos1,0.1)*weights.x;
		rainlens += gen_circular_lens(rainPos2,0.07)*weights.y;
		rainlens += gen_circular_lens(rainPos3,0.086)*weights.z;
		rainlens += gen_circular_lens(rainPos4,0.092)*weights.w;
	}/*--------------------------------*/
	#endif
	
	//colors - textures
	vec2 fake_refract = vec2(sin(frameTimeCounter + texcoord.x*100.0 + texcoord.y*50.0),cos(frameTimeCounter + texcoord.y*100.0 + texcoord.x*50.0)) ;
	vec2 newTC = clamp(texcoord + fake_refract * 0.01 * (rainlens+isEyeInWater*0.2),1.0/vec2(viewWidth,viewHeight),1.0-1.0/vec2(viewWidth,viewHeight));
	vec3 color = pow(texture2D(composite, newTC.xy).rgb,vec3(2.2))*257.0;
	/*----------------------------------------------------------------------*/
	
	bool land = texture2D(depthtex1, newTC).x < comp;
	
#ifdef Depth_of_Field
	float pw = 1.0/ viewWidth;
	float z = ld(texture2D(depthtex0, newTC.st).r)*far;
	float focus = ld(texture2D(depthtex0, vec2(0.5)).r)*far;
	float pcoc = min(abs(aperture * (focal * (z - focus)) / (z * (focus - focal)))*sizemult,pw*15.0);
	#ifdef Distance_Blur
	float getdist = 1-(exp(-pow(ld(texture2D(depthtex1, newTC.st).r)/Dof_Distance_View*far,4.0-(2.7*rainStrength))*4.0));	
	if(land)pcoc = min(getdist*pw*20.0,pw*20.0);
	#endif
	vec3 bcolor = vec3(0.0);
		for ( int i = 0; i < 60; i++) {
			bcolor += pow(texture2D(composite, newTC.xy + hex_offsets[i]*pcoc*vec2(1.0,aspectRatio)).rgb,vec3(2.2));
		}
		color.rgb = bcolor/61.0*257.0;
#endif

#ifdef Motionblur
float depth = texture2D(depthtex0, texcoord.st).x;

vec4 currentPlayerPosition = vec4(texcoord.x * 2.0f - 1.0f, texcoord.y * 2.0f - 1.0f, 2.0f * depth - 1.0f, 1.0f);
vec4 fragposition = gbufferProjectionInverse * currentPlayerPosition;
	fragposition = gbufferModelViewInverse * fragposition;
	fragposition /= fragposition.w;
	fragposition.xyz += cameraPosition;

vec4 previousPlayerPosition = fragposition;
	previousPlayerPosition.xyz -= previousCameraPosition;
	previousPlayerPosition = gbufferPreviousModelView * previousPlayerPosition;
	previousPlayerPosition = gbufferPreviousProjection * previousPlayerPosition;
	previousPlayerPosition /= previousPlayerPosition.w;

vec2 Blurness = (currentPlayerPosition - previousPlayerPosition).st * 0.0065;
vec2 coord = texcoord.st + Blurness;
vec3 Mcolor = color;
vec3 NormalizeColor = vec3(2.0);

for (int i = 0; i < 60; ++i, coord += Blurness) {
        Mcolor += pow(texture2D(composite, coord).rgb, NormalizeColor);
	}
		color = Mcolor/NormalizeColor;

#endif

//Sun glow and overall color brightness
vec3 blur = pow(texture2D(gnormal,texcoord.xy/4.0).rgb*5.,vec3(2.2))*20.0;
	 color *= 3.14;
	 color.xyz += blur*5.0;
	 color += rainlens*avgAmbient*0.01;
	
//Tonemap
vec3 curr = Uncharted2Tonemap(color*(pow(eyeAdapt,0.4)*2.25));
color = pow(curr/Uncharted2Tonemap(vec3(12.0)),vec3(0.454));
#ifdef Colorboost
color.g = (color.g * 1.1)+(color.b)*(-0.1);
color.b = (color.b * 1.1)+(color.g)*(-0.1);
#endif
/*----------------------------------------------------------*/

	gl_FragColor = vec4(color,1.0);
}
