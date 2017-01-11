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

//#define Lens_Flares
#define Lens_Flares_Strength 1.0 //[0.5 1.0 4.0 8.0 10.0]

//#define Bloom
/*--------------------------------*/
varying vec2 texcoord;
varying float eyeAdapt;

uniform sampler2D gdepth;

uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
/*--------------------------------*/

vec3 textureDistorted(
	in sampler2D tex, 
	in vec2 texcoord, 
	in vec2 direction,
	in vec3 distortion 
) {

	vec3 sample = vec3(
		texture2D(tex, (texcoord + direction * distortion.r)/4.0).r,
		texture2D(tex, (texcoord + direction * distortion.g)/4.0).g,
		texture2D(tex, (texcoord + direction * distortion.b)/4.0).b
	);
	
	sample = max(sample-0.085*normalize(vec3(sample)),0.0);
	return pow(sample,vec3(8.2));
}/*--------------------------------*/

void main() {
if(texcoord.x < 0.25 && texcoord.y < 0.25){
	vec2 tc4 = texcoord.xy*4.0;
	vec3 result = vec3(0.0);	
	
#ifdef Lens_Flares	
	vec2 ntc = 1.0-tc4; // flip ntcoords
	vec2 texelSize = 4.0 / vec2(viewWidth,viewHeight);
	
	const int uSamples = 17;
	const float uDistortion = 15.0;
	
	vec2 ghostVec = (vec2(0.5) - ntc)/uSamples*1.41421356237;
	vec3 distortion = vec3(-texelSize.x * uDistortion, 0.0, texelSize.x * uDistortion);

//Sun Lens flares
	for (int i = 0; i < uSamples; ++i) {
		vec2 offset = (ntc + ghostVec * float(i));
		
		float weight = min(length(vec2(0.5) - offset) / 0.70710678118,1.0);

		vec3 sresult = textureDistorted(
			gdepth,
			offset,
			normalize(ghostVec),
			distortion
		)*pow(1.0 - weight, 30.0);
		
		//Lens flare strength - brightness
		result += sresult*pow(weight, 4.0)*(200*Lens_Flares_Strength);

	}
#endif

#ifdef Bloom
	vec3 glow = texture2D(gdepth, texcoord.xy).rgb;
	vec3 overglow = glow*pow(length(glow)*2.0, 3.0)*2.2;

	gl_FragData[0] = vec4(pow(result.xyz,vec3(0.166))/4.2+(overglow+glow)*(0.5*(1+pow(rainStrength,3.)*4./pow(eyeAdapt,1.0)))/5.,1.0);
#else
	gl_FragData[0] = vec4(0.0);
#endif
	} 
}
