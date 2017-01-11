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
varying vec2 lightPos;

varying vec3 sunVec;
varying vec3 upVec;
varying vec3 sky1;
varying vec3 sky2;
varying vec3 rawAvg;
varying vec3 nsunlight;

varying float SdotU;
varying float sunVisibility;
varying float moonVisibility;

uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform int worldTime;
uniform float rainStrength;

uniform mat4 gbufferProjection;
/*--------------------------------*/

//Sunlight color
const vec3 ToD[7] = vec3[7](  vec3(1.0,0.15,0.02),
								vec3(1.0,0.35,0.09),
								vec3(1.0,0.5,0.26),
								vec3(1.0,0.5,0.35),
								vec3(1.0,0.5,0.36),
								vec3(1.0,0.5,0.37),
								vec3(1.0,0.5,0.38));
								

/* If you reached this line, then you're probably about to break the agreement which you accepted by downloading Sildur's shaders!
So stop your doing and ask Sildur before copying anything which would break the agreement, unless you're Chocapic then go ahead ;)
--------------------------------------------------------------------------------------------------------------------------------*/ 
	
void main() {
	
	//Lightpos for godrays
	vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
	tpos = vec4(tpos.xyz/tpos.w,1.0);
	vec2 pos1 = tpos.xy/tpos.z;
	lightPos = pos1*0.5+0.5;
	/*--------------------------------*/
	
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
	
	SdotU = dot(sunVec,upVec);
	sunVisibility = pow(clamp(SdotU+0.15,0.0,0.15)/0.15,4.0);
	moonVisibility = pow(clamp(-SdotU+0.15,0.0,0.15)/0.15,4.0);
	/*--------------------------------*/
	
	//reduced the sun color to a 7 array
	float hour = max(mod(worldTime/1000.0+2.0,24.0)-2.0,0.0);  //-0.1
	float cmpH = max(-abs(floor(hour)-6.0)+6.0,0.0); //12
	float cmpH1 = max(-abs(floor(hour)-5.0)+6.0,0.0); //1
	
	vec3 temp = ToD[int(cmpH)];
	vec3 temp2 = ToD[int(cmpH1)];
	
	vec3 sunlight = pow(mix(temp,temp2,fract(hour)),vec3(0.454));
	/*--------------------------------*/
	
	//Lighting
	float tr = clamp(min(min(distance(float(worldTime),23250.0),800.0),min(distance(float(worldTime),12700.0),800.0))/800.0-0.5,0.0,1.0)*2.0;

	vec4 bounced = vec4(0.5,0.66,1.3,0.27);
	vec3 sun_ambient = bounced.w * (vec3(0.25,0.62,1.32)-rainStrength*vec3(0.1,0.47,1.17))*(1.0+rainStrength*7.0) + sunlight*(bounced.x + bounced.z)*(1.0-rainStrength*0.95);

	const vec3 moonlight = vec3(0.0128, 0.02304, 0.03584);
	rawAvg = (sun_ambient*sunVisibility + moonlight*moonVisibility)*(0.05+tr*0.15)*4.7+0.0002;
	
	float cosS = SdotU;
	float mcosS = max(cosS,0.0);				

	float skyMult = max(SdotU*0.1+0.1,0.0)/0.2*(1.0-rainStrength*0.6)*0.7;
	nsunlight = normalize(pow(mix(sunlight,5.*sunlight*sunVisibility*(1.0-rainStrength*0.95)+vec3(0.3,0.3,0.35),rainStrength),vec3(2.2)))*0.6*skyMult;
	
	vec3 sky_color = vec3(0.15, 0.4, 1.);
	sky_color = normalize(mix(sky_color,2.*sunlight*sunVisibility*(1.0-rainStrength*0.95)+vec3(0.3,0.3,0.3)*length(sunlight),rainStrength)); //normalize colors in order to don't change luminance
	
	sky1 = sky_color*0.6*skyMult;
	sky2 = mix(sky_color,mix(nsunlight,sky_color,rainStrength*0.9),1.0-max(mcosS-0.2,0.0)*0.5)*0.6*skyMult;
	sunlight = pow(sunlight,vec3(2.2));
	/*--------------------------------*/
}