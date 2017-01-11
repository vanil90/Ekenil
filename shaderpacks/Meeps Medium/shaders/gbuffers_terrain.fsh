#version 120

/* DRAWBUFFERS:024 */

//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES

//#define POM 		//Parallax Occlusion Mapping.
	#define POM_AMOUNT 0.08		//the lower it is the bigger bump there will be. When you divide normalres by 2 use the squared root of this number and when you multiply by 2 use the square of this number.
	
//#define NORMAL_MAP
	#define NORMAL_MAP_MAX_ANGLE 1.0  		//The higher the value, the more extreme per-pixel normal mapping (bump mapping) will be.
	#define NORMALMAP_RES 1024.0		//the resolution is the normalmap resolution that you can see when opening terrain_nh,not the texturepack resolution. Most often it's 1024 or 2048.

#define MIN_LIGHTAMOUNT 0.1		//affect the minecraft lightmap (not torches)
#define MINELIGHTMAP_EXP 2.0		//affect the minecraft lightmap (not torches)

//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES



const vec3 intervalMult = vec3(1.0/NORMALMAP_RES, 1.0/NORMALMAP_RES, POM_AMOUNT);
const int RGB16 = 2;
const int RGBA16 = 3;
const int gnormalFormat = RGB16;
const int compositeFormat = RGBA16;
const int GL_EXP = 2048;
const int GL_LINEAR = 9729;
const int MAX_OCCLUSION_POINTS = 20;
const float bump_distance = 64.0;		//bump render distance: tiny = 32, short = 64, normal = 128, far = 256
const float pom_distance = 32.0;		//POM render distance: tiny = 32, short = 64, normal = 128, far = 256
const float fademult = 0.1;

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec3 normal;
varying vec4 color;
varying float translucent;

uniform sampler2D texture;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform int fogMode;
uniform int worldTime;
uniform float wetness;

float totalspec = 0.0;
float wetx = clamp(wetness, 0.0f, 1.0)/1.0;

//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////

void main() {	
	
	vec2 adjustedTexCoord = texcoord.st;
	vec3 lightVector;
	vec3 indlmap = texture2D(texture,adjustedTexCoord).rgb*color.rgb;
	vec4 frag2 = vec4(vec3(normal) * 0.5 + 0.5, 1.0f);
	
	float dirtest = 0.4;
	float pomsample = 0.0;
	float texinterval = 0.0625;
	
	if (worldTime < 12700 || worldTime > 23250) {
		lightVector = normalize(sunPosition);
	}
	
	else {
		lightVector = normalize(moonPosition);
	}
	
	dirtest = mix(1.0-0.8*step(dot(frag2.xyz*2.0-1.0,lightVector),-0.02),0.4,float(translucent > 0.01));

	

	gl_FragData[0] = vec4(indlmap,texture2D(texture,adjustedTexCoord).a*color.a);
	gl_FragData[1] = frag2;	
	gl_FragData[2] = vec4(lmcoord.t, dirtest, lmcoord.s, 1.0);
	
}