#version 120

/*
!! DO NOT REMOVE !!
This code is from Werrus shaders who has given permission for CYBOX to use.
Read the terms of modification and sharing before changing something below please !
!! DO NOT REMOVE !!
*/


/* DRAWBUFFERS:024 */

//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES




//----------Water----------//
	vec4 watercolor = vec4(0.01,0.10,0.23,0.57); 	//water color and opacity (r,g,b,opacity)
//----------End of Water----------//




//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES

const int MAX_OCCLUSION_POINTS = 20;
const float MAX_OCCLUSION_DISTANCE = 96.0;
const float bump_distance = 64.0;				//Bump render distance: tiny = 32, short = 64, normal = 128, far = 256
const float pom_distance = 32.0;				//POM render distance: tiny = 32, short = 64, normal = 128, far = 256
const float fademult = 0.1;
const float PI = 3.1415927;

varying vec4 color;
varying vec4 texcoord;
varying vec4 lmcoord;
varying vec3 binormal;
varying vec3 normal;
varying vec3 tangent;
varying vec3 viewVector;
varying vec3 wpos;
varying float iswater;

uniform sampler2D texture;
uniform sampler2D noisetex;
uniform int worldTime;
uniform float far;
uniform float rainStrength;
uniform float frameTimeCounter;

float timefract = worldTime;

float rainx = clamp(rainStrength, 0.0f, 1.0f)/1.0f;

float waterH(vec2 posxz) {

vec2 movement = vec2(abs(frameTimeCounter/1000.-0.5),abs(frameTimeCounter/1000.-0.5));
vec2 movement2 = vec2(-abs(frameTimeCounter/1000.-0.5),abs(frameTimeCounter/1000.-0.5));
vec2 movement3 = vec2(-abs(frameTimeCounter/1000.-0.5),-abs(frameTimeCounter/1000.-0.5));
vec2 movement4 = vec2(abs(frameTimeCounter/1000.-0.5),-abs(frameTimeCounter/1000.-0.5));
vec2 movement5 = vec2(-abs(frameTimeCounter/1000.-0.5),-abs(frameTimeCounter/1000.-0.5));
vec2 movement6 = vec2(-abs(frameTimeCounter/1000.-0.5),-abs(frameTimeCounter/1000.-0.5));

vec2 coord = (posxz/600)+(movement);
vec2 coord1 = (posxz/599.9)+(movement2);
vec2 coord2 = (posxz/599.8)+(movement3);
vec2 coord3 = (posxz/599.7)+(movement4);
vec2 coord4 = (posxz/1600)+(movement/1.5);
vec2 coord5 = (posxz/1599)+(movement2/1.5);
vec2 coord6 = (posxz/1598)+(movement3/1.5);
vec2 coord7 = (posxz/1597)+(movement4/1.5);
float noise = texture2D(noisetex,fract(coord.xy/2.0)).x;
float noise2 = texture2D(noisetex,fract(coord.xy/2.0)).x;
noise += texture2D(noisetex,fract(coord.xy)).x/2.0;
noise += texture2D(noisetex,fract(coord.xy*2.0)).x/4.0;
noise += texture2D(noisetex,fract(coord.xy*8.6)).x/8.0;
noise += texture2D(noisetex,fract(coord1.xy)).x/2.0;
noise += texture2D(noisetex,fract(coord1.xy*2.0)).x/4.0;
noise += texture2D(noisetex,fract(coord1.xy*4.0)).x/8.0;
noise += texture2D(noisetex,fract(coord2.xy)).x/2.0;
noise += texture2D(noisetex,fract(coord2.xy*2.0)).x/4.0;
noise += texture2D(noisetex,fract(coord2.xy*4.0)).x/8.0;
noise += texture2D(noisetex,fract(coord3.xy)).x/2.0;
noise += texture2D(noisetex,fract(coord3.xy*2.0)).x/4.0;
noise += texture2D(noisetex,fract(coord3.xy*4.0)).x/8.0;
noise2 += texture2D(noisetex,fract(coord4.xy)).x/2.0;
noise2 += texture2D(noisetex,fract(coord4.xy*2.0)).x/4.0;
noise2 += texture2D(noisetex,fract(coord4.xy*4.0)).x/8.0;
noise2 += texture2D(noisetex,fract(coord5.xy)).x/2.0;
noise2 += texture2D(noisetex,fract(coord5.xy*2.0)).x/4.0;
noise2 += texture2D(noisetex,fract(coord5.xy*4.0)).x/8.0;
noise2 += texture2D(noisetex,fract(coord6.xy)).x/2.0;
noise2 += texture2D(noisetex,fract(coord6.xy*2.0)).x/4.0;
noise2 += texture2D(noisetex,fract(coord6.xy*4.0)).x/8.0;
noise2 += texture2D(noisetex,fract(coord7.xy)).x/2.0;
noise2 += texture2D(noisetex,fract(coord7.xy*2.0)).x/4.0;
noise2 += texture2D(noisetex,fract(coord7.xy*4.0)).x/8.0;

return noise+noise2;
}

//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////

void main() {

	vec4 tex = vec4((watercolor*length(texture2D(texture, texcoord.xy).rgb*color.rgb)*color).rgb,watercolor.a);
	if (iswater < 0.9)  tex = texture2D(texture, texcoord.xy)*color;

	vec3 posxz = wpos.xyz;

	float deltaPos = 0.1;
	float h0 = waterH(posxz.xz);
	float h1 = waterH(posxz.xz + vec2(deltaPos,0.0));
	float h2 = waterH(posxz.xz + vec2(-deltaPos,0.0));
	float h3 = waterH(posxz.xz + vec2(0.0,deltaPos));
	float h4 = waterH(posxz.xz + vec2(0.0,-deltaPos));

	float xDelta = (h1-h0)+(h0-h2);
	float yDelta = (h3-h0)+(h0-h4);

	vec3 newnormal = normalize(vec3(xDelta,yDelta,1.0-pow(abs(xDelta+yDelta),2.0)));

	vec4 frag2;
		frag2 = vec4((normal) * 0.5f + 0.5f, 1.0f);

	if (iswater > 0.9) {
		vec3 bump = newnormal;
			bump = bump;


		float bumpmult = 0.15;

		bump = bump * vec3(bumpmult, bumpmult, bumpmult) + vec3(0.0f, 0.0f, 1.0f - bumpmult);
		mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
							tangent.y, binormal.y, normal.y,
							tangent.z, binormal.z, normal.z);

		frag2 = vec4(normalize(bump * tbnMatrix) * 0.5 + 0.5, 1.0);
	}
	gl_FragData[0] = tex;
	gl_FragData[1] = frag2;
	gl_FragData[2] = vec4(lmcoord.t, mix(1.0,0.05,iswater), lmcoord.s, 1.0);
}
