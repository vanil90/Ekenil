#version 120
/* DRAWBUFFERS:01 */
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

#define MobsFlashRed

varying vec4 color;

varying vec4 texcoord;
varying vec3 normal;
varying vec2 lmcoord;

uniform sampler2D texture;
uniform sampler2D lightmap;

uniform vec4 entityColor;	//rgba, replaces entityHurt and entityFlash in 1.9+

uniform ivec2 eyeBrightness;
bool getlight = (eyeBrightness.y / 255.0) < 0.1;

//temporary transparency fix
vec4 lowlevel_lightmap = getlight? texture2D(lightmap, lmcoord.st)*1.25 : vec4(1.0);

//encode normal in two channel (xy),torch and material(z) and sky lightmap (w)
vec4 encode (vec3 n){
	float alpha = getlight? 1.0 : texcoord.w*2.0;

    float p = sqrt(n.z*8+8);
    return vec4(n.xy/p + 0.5,texcoord.z+1/255., alpha);
}

vec3 RGB2YCoCg(vec3 c){
		return vec3( 0.25*c.r+0.5*c.g+0.25*c.b, 0.5*c.r-0.5*c.b +0.5, -0.25*c.r+0.5*c.g-0.25*c.b +0.5);
	}

void main() {

#ifdef MobsFlashRed
//Code by Sp164x
vec4 colTex = texture2D(texture, texcoord.xy) * color * lowlevel_lightmap;
vec4 albedo = mix(colTex, entityColor, vec4(entityColor.aaa, 0));
#else
vec4 albedo = texture2D(texture, texcoord.xy)*color * lowlevel_lightmap;
#endif

vec4 cAlbedo = vec4(RGB2YCoCg(albedo.rgb),albedo.a);

bool pattern = (mod(gl_FragCoord.x,2.0)==mod(gl_FragCoord.y,2.0));
cAlbedo.g = (pattern)?cAlbedo.b: cAlbedo.g;
cAlbedo.b = 1.0;

	gl_FragData[0] = cAlbedo;
	gl_FragData[1] = encode(normal.xyz);
	gl_FragData[2] = vec4(0.0, 0.0, 0.0, 1.0); //fix flickering on amd cards		
}