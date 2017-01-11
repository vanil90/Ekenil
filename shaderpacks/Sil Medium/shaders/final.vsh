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
/*--------------------------------*/
varying vec2 texcoord;
varying vec2 rainPos1;
varying vec2 rainPos2;
varying vec2 rainPos3;
varying vec2 rainPos4;
varying vec3 avgAmbient;
varying vec4 weights;

varying float eyeAdapt;

uniform vec3 sunPosition;
uniform vec3 upPosition;

uniform ivec2 eyeBrightnessSmooth;
uniform int worldTime;
uniform float rainStrength;
uniform float frameTimeCounter;

const vec3 ToD[7] = vec3[7](  vec3(0.58597,0.16,0.025),
								vec3(0.58597,0.4,0.2),
								vec3(0.58597,0.52344,0.24680),
								vec3(0.58597,0.55422,0.34),
								vec3(0.58597,0.57954,0.38),
								vec3(0.58597,0.58,0.40),
								vec3(0.58597,0.58,0.40));
						
float luma(vec3 color) {
	return dot(color,vec3(0.299, 0.587, 0.114));
}

vec2 noisepattern(vec2 pos) {
	vec2 all_values = vec2(83147.6995379f, 125370.887575f); //performs the computation all at once.
	return vec2(abs(fract(sin(dot(pos ,all_values)))),abs(fract(sin(dot(pos.yx ,all_values)))));
}


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
	vec3 sunVec = normalize(sunPosition);
	vec3 upVec = normalize(upPosition);
	float SdotU = dot(sunVec,upVec);

	float sunVisibility = pow(clamp(SdotU+0.15,0.0,0.15)/0.15,4.0);
	float moonVisibility = pow(clamp(-SdotU+0.15,0.0,0.15)/0.15,4.0);
	/*--------------------------------------------------------------*/
	
	//reduced the sun color to a 7 array
	float hour = max(mod(worldTime/1000.0+2.0,24.0)-2.0,0.0);  //-0.1
	float cmpH = max(-abs(floor(hour)-6.0)+6.0,0.0); //12
	float cmpH1 = max(-abs(floor(hour)-5.0)+6.0,0.0); //1

	vec3 temp = ToD[int(cmpH)];
	vec3 temp2 = ToD[int(cmpH1)];
	
	vec3 sunlight = mix(temp,temp2,fract(hour));
	/*-------------------------------------------*/	

	//Lighting
	float eyebright = max(eyeBrightnessSmooth.y/255.0-0.5/16.0,0.0)*1.03225806452;
	float SkyL2 = mix(1.0,eyebright*eyebright,eyebright);

	vec2 trCalc = min(abs(worldTime-vec2(23250.0,12700.0)),750.0);
	float tr = max(min(trCalc.x,trCalc.y)/375.0-1.0,0.0);
	
	vec4 bounced = vec4(0.5*SkyL2,0.66*SkyL2,0.7,0.3);

	vec3 sun_ambient = bounced.w * (vec3(0.25,0.62,1.32)-rainStrength*vec3(0.11,0.32,1.07)) + sunlight*(bounced.x + bounced.z);

	const vec3 moonlight = vec3(0.0035, 0.0063, 0.0098);
	
	avgAmbient =(sun_ambient*sunVisibility + moonlight*moonVisibility)*eyebright*eyebright*(0.05+tr*0.15)*4.7+0.0006;

	eyeAdapt = log(clamp(luma(avgAmbient),0.007,80.0))/log(2.6)*0.35;
	eyeAdapt = 1.0/pow(2.6,eyeAdapt)*1.75;
	avgAmbient /= sqrt(3.0);
	/*--------------------------------*/

	const float lifetime = 4.0;		//water drop lifetime in seconds
	float ftime = frameTimeCounter*2.0/lifetime;  
	vec2 drop = vec2(0.0,fract(frameTimeCounter/20.0));
	rainPos1 = fract((noisepattern(vec2(-0.94386347*floor(ftime*0.5+0.25),floor(ftime*0.5+0.25))))*0.8+0.1 - drop);
	rainPos2 = fract((noisepattern(vec2(0.9347*floor(ftime*0.5+0.5),-0.2533282*floor(ftime*0.5+0.5))))*0.8+0.1- drop);
	rainPos3 = fract((noisepattern(vec2(0.785282*floor(ftime*0.5+0.75),-0.285282*floor(ftime*0.5+0.75))))*0.8+0.1- drop);
	rainPos4 = fract((noisepattern(vec2(-0.347*floor(ftime*0.5),0.6847*floor(ftime*0.5))))*0.8+0.1- drop);
	weights.x = 1.0-fract((ftime+0.5)*0.5);
	weights.y = 1.0-fract((ftime+1.0)*0.5);
	weights.z = 1.0-fract((ftime+1.5)*0.5);
	weights.w = 1.0-fract(ftime*0.5);
	weights *= rainStrength*clamp((eyeBrightnessSmooth.y-220)/15.0,0.0,1.0);

}
