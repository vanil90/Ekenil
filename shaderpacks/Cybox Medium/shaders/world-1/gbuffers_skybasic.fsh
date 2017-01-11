#version 120

/*
!! DO NOT REMOVE !!
This code is from Life Nexus shaders
Read the terms of modification and sharing before changing something below please !
!! DO NOT REMOVE !!
*/
/* DRAWBUFFERS:0 */

varying vec4 color;
varying vec4 texcoord;
varying vec3 normal;

uniform int worldTime;
uniform sampler2D texture;
uniform float rainStrength;
uniform int fogMode;

const int FOGMODE_LINEAR = 9729;
const int FOGMODE_EXP = 2048;

//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////

void main() {
	gl_FragData[0] = color;
	float fogFactor;
	
		fogFactor = clamp(exp(-gl_Fog.density * gl_FogFragCoord), 0.0, 1.0);


	gl_FragData[0] = mix(gl_FragData[0],gl_Fog.color,1.0-fogFactor);
}