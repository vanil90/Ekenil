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
varying vec2 lightPos;

varying vec3 sunVec;
varying vec3 upVec;
varying vec3 lightColor;
varying vec3 avgAmbient2;
varying vec3 sky1;
varying vec3 sky2;
varying vec3 sunlight;
varying vec3 nsunlight;
varying vec3 cloudColor;
varying vec3 cloudColor2;

varying float tr;
varying float SdotU;
varying float sunVisibility;
varying float moonVisibility;

uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform int worldTime;
uniform float rainStrength;
uniform ivec2 eyeBrightnessSmooth;
uniform mat4 gbufferProjection;

const vec3 ToD[7] = vec3[7](  vec3(1.35,0.15,0.02),
								vec3(1.35,0.35,0.09),
								vec3(1.35,0.5,0.26),
								vec3(1.35,0.5,0.35),
								vec3(1.35,0.5,0.36),
								vec3(1.35,0.5,0.37),
								vec3(1.35,0.5,0.38));	


/* If you reached this line, then you're probably about to break the agreement which you accepted by downloading Sildur's shaders!
So stop your doing and ask Sildur before copying anything which would break the agreement, unless you're Chocapic then go ahead ;)
--------------------------------------------------------------------------------------------------------------------------------*/ 

void main() {

	//Light pos for Godrays
	vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
	tpos = vec4(tpos.xyz/tpos.w,1.0);
	vec2 pos1 = tpos.xy/tpos.z;
	lightPos = pos1*0.5+0.5;
	/*-----------------------*/
	
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
	/*--------------------------------------------------------------*/
	
	//reduced the sun color to a 7 array
	float hour = max(mod(worldTime/1000.0+2.0,24.0)-2.0,0.0);  //-0.1
	float cmpH = max(-abs(floor(hour)-6.0)+6.0,0.0); //12
	float cmpH1 = max(-abs(floor(hour)-5.0)+6.0,0.0); //1
	
	vec3 temp = ToD[int(cmpH)];
	vec3 temp2 = ToD[int(cmpH1)];
	
	sunlight  = mix(temp,temp2,fract(hour));
	vec3 sunlight04 = pow(mix(temp,temp2,fract(hour)),vec3(0.454));
	/*--------------------------------------------------------------*/	
	
	//lighting
	float eyebright = max(eyeBrightnessSmooth.y/255.0-0.5/16.0,0.0)*1.03225806452;

	vec2 trCalc = min(abs(worldTime-vec2(23250.0,12700.0)),750.0);
	tr = max(min(trCalc.x,trCalc.y)/375.0-1.0,0.0);
	
	vec4 bounced = vec4(0.5,0.66,0.7,0.3);
	vec3 sun_ambient = bounced.w * (vec3(0.25,0.62,1.32)-rainStrength*vec3(0.1,0.47,1.17))*(1.0+rainStrength*7.0) + sunlight*(bounced.x + bounced.z)*(1.0-rainStrength*0.95);

	const vec3 moonlight = vec3(0.001, 0.0018, 0.0028);
	vec3 moon_ambient = (moonlight + moonlight*eyebright*eyebright*eyebright);
	
	avgAmbient2 = (sun_ambient*sunVisibility + 3.*moon_ambient*moonVisibility)*(0.05+tr*0.15)*4.7+0.0002;
	avgAmbient2 /= sqrt(3.0);
	
	//clouds
	cloudColor = sunlight04*sunVisibility*(1.0-rainStrength*0.97)*length(avgAmbient2) + avgAmbient2*0.7*(1.0-rainStrength*0.5) + 16.0*moonlight*moonVisibility*(1.0-rainStrength*0.95);
	cloudColor2 = 0.1*sunlight04*sunVisibility*(1.0-rainStrength*0.95)*length(avgAmbient2) + 1.5*length(avgAmbient2)*mix(vec3(0.15, 0.4, 1.),vec3(0.3,0.3,0.35),rainStrength)*(1.0-rainStrength*0.5) + 16.0*moonlight*moonVisibility*(1.0-rainStrength*0.95);	
	/*--------------------------------*/
	
	//Light pos for godrays
	float truepos = sign(sunPosition.z)*1.0;		//1 -> sun / -1 -> moon
	lightColor = mix(sunlight*sunVisibility,12.*moonlight*moonVisibility,(truepos+1.0)/2.);
	if (length(lightColor)>0.0000001)lightColor = mix(lightColor,normalize(vec3(0.3,0.3,0.3))*pow(normalize(lightColor),vec3(0.4))*length(lightColor)*0.03,rainStrength)*(0.25+0.25*tr);
	/*-------------------------------------------------------------------------------------------------------*/

	//Sky lighting
	float cosS = SdotU;
	float mcosS = max(cosS,0.0);				

	float skyMult = max(SdotU*0.1+0.1,0.0)/0.2*(1.0-rainStrength*0.6)*0.7;
	nsunlight = normalize(pow(mix(sunlight04 ,5.*sunlight04 *sunVisibility*(1.0-rainStrength*0.95)+vec3(0.3,0.3,0.35),rainStrength),vec3(2.2)))*0.6*skyMult;
	
	vec3 sky_color = vec3(0.15, 0.4, 1.);
	sky_color = normalize(mix(sky_color,2.*sunlight04 *sunVisibility*(1.0-rainStrength*0.95)+vec3(0.3,0.3,0.3)*length(sunlight04 ),rainStrength)); //normalize colors in order to don't change luminance
	
	sky1 = sky_color*0.6*skyMult;
	sky2 = mix(sky_color,mix(nsunlight,sky_color,rainStrength*0.9),1.0-max(mcosS-0.2,0.0)*0.5)*0.6*skyMult;
	/*-------------------------------------------------------------------------------------------------------*/

}
