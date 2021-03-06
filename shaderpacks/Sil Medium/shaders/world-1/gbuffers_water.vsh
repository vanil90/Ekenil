#version 120
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

*/

varying vec4 color;
varying vec2 texcoord;
varying vec2 lmcoord;

void main() {

	color = gl_Color;
	gl_Position = ftransform();

	texcoord = (gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmcoord /= 1.25; //brightness = moody
	/*-----------------------------------------------------*/


	
}
