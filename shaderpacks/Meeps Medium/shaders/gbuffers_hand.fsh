#version 120

/* DRAWBUFFERS:024 */

//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES

#define MIN_LIGHTAMOUNT 0.1		//affect the minecraft lightmap (not torches)
#define MINELIGHTMAP_EXP 2.0		//affect the minecraft lightmap (not torches)

//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES



const int GL_EXP = 2048;
const int GL_LINEAR = 9729;
const int MAX_OCCLUSION_POINTS = 20;
const float MAX_OCCLUSION_DISTANCE = 100.0;
const float bump_distance = 64.0;		//bump render distance: tiny = 32, short = 64, normal = 128, far = 256
const float fademult = 0.1;

varying vec4 color;
varying vec4 texcoord;
varying vec4 lmcoord;
varying vec3 normal;

uniform sampler2D texture;
uniform sampler2D normals;
uniform int fogMode;
uniform float rainStrength;

float rainx = clamp(rainStrength, 0.0f, 1.0f)/1.0f;

//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////

void main() {	
	
	vec2 adjustedTexCoord = texcoord.st;
	
	float texinterval = 0.0625f;
	
	vec3 indlmap = texture2D(texture,adjustedTexCoord).rgb*color.rgb;
	
	gl_FragData[0] = vec4(indlmap,texture2D(texture,adjustedTexCoord).a*color.a);
	gl_FragData[1] = vec4(normal*0.5+0.5,1.0);	
	//x = specularity / y = land(0.0/1.0)/shadow early exit(0.2)/water(0.05)/hand(0.8) / z = torch lightmap
	gl_FragData[2] = vec4(lmcoord.t, 0.8, lmcoord.s, 1.0f);
	
}