#version 120
/* DRAWBUFFERS:2 */
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
#define Bloom
/*--------------------------------*/
varying vec2 texcoord;
varying float eyeAdapt;

uniform sampler2D gdepth;

uniform float rainStrength;
/*--------------------------------*/


void main() {
if(texcoord.x < 0.25 && texcoord.y < 0.25){
	vec3 result = vec3(0.0);

#ifdef Bloom
	vec3 glow = texture2D(gdepth, texcoord.xy).rgb;
	vec3 overglow = glow*pow(length(glow)*2.0, 3.0)*2.2;
	gl_FragData[0] = vec4(pow(result.xyz,vec3(0.166))/4.2+(overglow+glow)*(0.5*(1+pow(rainStrength,3.)*4./pow(eyeAdapt,1.0)))/5.,1.0);
#else
gl_FragData[0] = vec4(0.0);
#endif

	} 

}
