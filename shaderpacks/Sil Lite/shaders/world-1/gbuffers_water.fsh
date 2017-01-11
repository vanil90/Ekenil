#version 120
//no drawbuffer or else blocks might be invisible for some systems
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

varying vec4 color;
varying vec2 texcoord;
varying vec2 lmcoord;

uniform sampler2D texture;
uniform sampler2D lightmap;

void main() {

	gl_FragData[0] = texture2D(texture, texcoord.xy)* color * texture2D(lightmap, lmcoord.st);
	
}
