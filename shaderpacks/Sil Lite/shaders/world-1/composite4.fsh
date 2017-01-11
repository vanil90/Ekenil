#version 120
#extension GL_ARB_shader_texture_lod : enable
/* DRAWBUFFERS:1 */
/*
                            _____ _____ ___________
                           /  ___|_   _|  _  | ___ \
                           \ `--.  | | | | | | |_/ /
                            `--. \ | | | | | |  __/
                           /\__/ / | | \ \_/ / |
                           \____/  \_/  \___/\_|
This code is from Chocapic13' shaders v6.2, modified, tweaked and changed by Sildur for vibrant shaders v1.15 and newer.
						Before editing anything here make sure you've
						read The agreement, which you accepted by downloading
						my shaderpack. The agreement can be found here:
			http://www.minecraftforum.net/topic/1953873-164-172-sildurs-shaders-pcmacintel/

*/

//#define Bloom

/*--------------------------------*/
varying vec2 texcoord;

uniform sampler2D gnormal;

uniform float viewWidth;
uniform float viewHeight;
float pw = 1.0/ viewWidth;
float ph = 1.0/ viewHeight;
/*--------------------------------*/

void main() {
if(texcoord.x<0.25 && texcoord.y<0.25){
#ifdef Bloom
//Blur
const int nSteps = 25;
int center = (nSteps-1)/2;
vec3 blur = vec3(0.0);
float tw = 0.0;

for (int i = 0; i < nSteps; i++) {
	float dist = abs(i-float(center))/center;
	float weight = (exp(-(dist*dist)/0.28));

	vec3 bsample= pow(texture2DLod(gnormal,texcoord.xy + vec2(pw,ph)*vec2(0.0,i*2.0-center*2.0),1).rgb,vec3(2.2))*300.0;
	blur += bsample*weight;
	tw += weight;
}
blur /= tw;
blur = clamp(pow(blur,vec3(0.454)),0.0,1.0);
	
gl_FragData[0] = vec4(blur,1.0);
#else
gl_FragData[0] = vec4(0.0);
#endif
}
}
