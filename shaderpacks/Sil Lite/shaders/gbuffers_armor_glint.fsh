#version 120
/* DRAWBUFFERS:0 */

uniform sampler2D texture;
uniform sampler2D lightmap;

varying vec4 color;
varying vec4 texcoord;
varying vec2 lmcoord;

void main() {

vec4 albedo = texture2D(texture, texcoord.st) * texture2D(lightmap, lmcoord.st)*color;
albedo.rgb *= 1.5;

	gl_FragData[0] = albedo;

}