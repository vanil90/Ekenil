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
varying vec2 texcoord;
varying float handItemLight;

uniform int heldItemId;

/* If you reached this line, then you're probably about to break the agreement which you accepted by downloading Sildur's shaders!
So stop your doing and ask Sildur before copying anything which would break the agreement, unless you're Chocapic then go ahead ;)
--------------------------------------------------------------------------------------------------------------------------------*/ 

void main() {

	//Positioning
	gl_Position = ftransform();
	texcoord = (gl_MultiTexCoord0).xy;
	/*--------------------------------*/

	//Handheld Items casting light
	handItemLight = 0.0;
	if(heldItemId == 50.0						//Torch
	|| heldItemId == 10.0 						//flowing lava
	|| heldItemId == 11.0 						//still lava
	|| heldItemId == 51.0 						//fire
	|| heldItemId == 89.0 						//glowstone
	|| heldItemId == 91.0 						//jack o'lantern
	|| heldItemId == 138.0 						//beacon
	|| heldItemId == 169.0)handItemLight = 0.5; //sea lantern
	else if(heldItemId == 76.0					//active redstone torch
	|| heldItemId == 94.0 						//redstone repeater
	|| heldItemId == 327.0)handItemLight = 0.1; //lava bucket
	
}