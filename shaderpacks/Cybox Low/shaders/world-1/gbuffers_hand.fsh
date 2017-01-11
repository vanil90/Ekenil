#version 120
/*
!! DO NOT REMOVE !!
This code is from Life Nexus shaders
Read the terms of modification and sharing before changing something below please !
!! DO NOT REMOVE !!
*/
varying vec2 lmcoord;
varying vec4 color;
varying vec2 texcoord;
varying vec3 normal;


uniform sampler2D texture;
uniform sampler2D normals;
uniform sampler2D specular;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform int fogMode;
uniform int worldTime;
uniform float wetness;




//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////

void main() {

	vec4 frag2 = vec4(normal*0.5+0.5, 1.0f);
	
/* DRAWBUFFERS:024 */

	gl_FragData[0] = texture2D(texture, texcoord.st)*color;
	gl_FragData[1] = frag2;	
	gl_FragData[2] = vec4((lmcoord.t), 0.8, lmcoord.s, 1.0);

}