#version 120
/* DRAWBUFFERS:56 */
/*
                            _____ _____ ___________
                           /  ___|_   _|  _  | ___ \
                           \ `--.  | | | | | | |_/ /
                            `--. \ | | | | | |  __/
                           /\__/ / | | \ \_/ / |
                           \____/  \_/  \___/\_|

						Before editing anything here make sure you've
						read The agreement, which you accepted by downloading
						my shaderpack. The agreement can be found here:
			http://www.minecraftforum.net/topic/1953873-164-172-sildurs-shaders-pcmacintel/

						Sildur's shaders, derived from Chocapic's shaders */

varying vec2 texcoord;

varying vec3 normal;
uniform vec3 sunPosition;

varying vec4 color;
varying vec4 ambientNdotL;
varying vec4 sunlightMat;

uniform sampler2D texture;
uniform int worldTime;

void main() {

	//Sun/moon position
	float diffuse = dot(normalize(sunPosition),normal);
	diffuse = (worldTime > 12700 && worldTime < 23250)? -diffuse : diffuse;
	/*-----------------------------------------------------------------------*/

	//Colors
	vec4 albedo = texture2D(texture, texcoord.xy)*color;
	albedo.rgb = pow(albedo.rgb,vec3(2.2));
	
	vec3 Shading = (sunlightMat.rgb*diffuse*2.0+color.a/2.0)*ambientNdotL.rgb;
	vec3 fColor = pow(albedo.rgb*(Shading+ambientNdotL.rgb*3.5),vec3(0.454));
	/*--------------------------------------------------------------------------*/

	gl_FragData[0] = vec4(fColor,albedo.a);
	gl_FragData[1] = vec4(normalize(pow(albedo.rgb,vec3(0.454))),albedo.a);
}