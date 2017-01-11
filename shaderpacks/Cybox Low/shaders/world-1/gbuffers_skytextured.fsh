#version 120

/*
!! DO NOT REMOVE !!
This code is from Life Nexus shaders
Read the terms of modification and sharing before changing something below please !
!! DO NOT REMOVE !!
*/

/* DRAWBUFFERS:0 */

varying vec4 color;
varying vec2 texcoord;

uniform sampler2D texture;
uniform int fogMode;

const int FOGMODE_LINEAR = 9729;
const int FOGMODE_EXP = 2048;

//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////

void main() {

	gl_FragData[0] = texture2D(texture,texcoord.xy)*color;

}