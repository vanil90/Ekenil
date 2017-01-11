#version 120
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
varying vec2 texcoord;
varying vec3 sunVec;
varying vec3 upVec;
varying vec3 sunlight;

varying float tr;
varying float sunVisibility;
varying float moonVisibility;
varying float handItemLight;

uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform int worldTime;
uniform int heldItemId;

//Sunlight color on land
const vec3 ToD[7] = vec3[7](  vec3(0.58597,0.15,0.02),
								vec3(0.58597,0.35,0.09),
								vec3(0.58597,0.5,0.26),
								vec3(0.58597,0.5,0.35),
								vec3(0.58597,0.5,0.36),
								vec3(0.58597,0.5,0.37),
								vec3(0.58597,0.5,0.38));
								

/* If you reached this line, then you're probably about to break the agreement which you accepted by downloading Sildur's shaders!
So stop your doing and ask Sildur before copying anything which would break the agreement, unless you're Chocapic then go ahead ;)
--------------------------------------------------------------------------------------------------------------------------------*/ 

void main() {

	//Positioning
	gl_Position = ftransform();
	texcoord = (gl_MultiTexCoord0).xy;
	/*--------------------------------*/
	
	//Sun/Moon position
	if (worldTime < 12700 || worldTime > 23250) {
		vec3 lightVector = normalize(sunPosition);
	} else {
		vec3 lightVector = normalize(-sunPosition);
	}
	sunVec = normalize(sunPosition);
	upVec = normalize(upPosition);
	
	float SdotU = dot(sunVec,upVec);
	sunVisibility = pow(clamp(SdotU+0.15,0.0,0.15)/0.15,4.0);
	moonVisibility = pow(clamp(-SdotU+0.15,0.0,0.15)/0.15,4.0);
	
	vec2 trCalc = min(abs(worldTime-vec2(23250.0,12700.0)),750.0);
	tr = max(min(trCalc.x,trCalc.y)/375.0-1.0,0.0);	
	/*--------------------------------*/
	
	//reduced the sun color to a 7 array
	float hour = max(mod(worldTime/1000.0+2.0,24.0)-2.0,0.0);  //-0.1
	float cmpH = max(-abs(floor(hour)-6.0)+6.0,0.0); //12
	float cmpH1 = max(-abs(floor(hour)-5.0)+6.0,0.0); //1

	vec3 temp = ToD[int(cmpH)];
	vec3 temp2 = ToD[int(cmpH1)];
	
	sunlight = pow(mix(temp,temp2,fract(hour)),vec3(0.454));
	sunlight = pow(sunlight,vec3(2.2));
	/*----------------------------------------*/

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