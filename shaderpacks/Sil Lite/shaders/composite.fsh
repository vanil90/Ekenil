#version 120
/* DRAWBUFFERS:3 */	
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
/*--------------------
//ADJUSTABLE VARIABLES//
---------------------*/

//#define Godrays

/*---------------------------
//END OF ADJUSTABLE VARIABLES//
----------------------------*/

/*------------------------------------*/
const vec3 moonlight = vec3(0.0025, 0.0045, 0.007);

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

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D gaux1;
uniform mat4 gbufferProjectionInverse;
uniform float rainStrength;

uniform float near;
uniform float far;

//Sky
vec3 getSkyColor(vec3 fposition) {
vec3 sVector = normalize(fposition);

	float invRain07 = 1.0-rainStrength*0.6;
	float cosT = dot(sVector,upVec); 
	float mCosT = max(cosT,0.0);
	float absCosT = 1.0-max(cosT*0.82+0.26,0.2);
	float cosS = SdotU;			
	float cosY = dot(sunVec,sVector);
	float Y = acos(cosY);	
	/*--------------------------------*/
	const float a = -1.;
	const float b = -0.25;
	const float c = 4.0;
	const float d = -2.5;
	const float e = 0.3;
	/*--------------------------------*/
	//luminance
	float L =  (1.0+a*exp(b/(mCosT)));
	float A = 1.0+e*cosY*cosY;

	//gradient
	vec3 grad1 = mix(sky1,sky2,absCosT*absCosT);
	float sunscat = max(cosY,0.0);
	vec3 grad3 = mix(grad1,nsunlight,sunscat*sunscat*(1.0-mCosT)*(1.0-rainStrength*0.5)*(clamp(-(cosS)*4.0+3.0,0.0,1.0)*0.65+0.35)*0.9+0.1);

	float Y2 = 3.14159265359-Y;	
	float L2 = L * (8.0*exp(d*Y2)+A);

	const vec3 moonlight2 = pow(normalize(moonlight),vec3(3.0))*length(moonlight);
	const vec3 moonlightRain = normalize(vec3(0.25,0.3,0.4))*length(moonlight);
	vec3 gradN = mix(moonlight,moonlight2,1.-L2/2.0);
	gradN = mix(gradN,moonlightRain,rainStrength);

return (1.35*grad3*pow(L*(c*exp(d*Y)+A),invRain07)*sunVisibility*vec3(0.425,0.44,0.5) *pow(length(rawAvg),.4) * (1.0-rainStrength*0.5)+ 0.4*gradN*pow(L2*1.2+1.6,invRain07)*moonVisibility);
}/*--------------------------------------------------------*/

vec2 ntc = texcoord*2.0;

#ifdef Godrays
float cdist(vec2 coord) {
	return 1.0-pow(max(abs(coord.s-0.5),abs(coord.t-0.5))*2.0,2.0);
}

float getnoise(vec2 pos) {
	return fract(sin(dot(pos ,vec2(83147.6995379f, 125370.887575f))));
}

float makeRays(float offcoord){
	vec2 deltatexcoord = vec2(lightPos - ntc) * 0.045;
	vec2 noisetc = ntc + deltatexcoord.xy*getnoise(ntc*2.0);
	vec2 coord = offcoord*deltatexcoord + noisetc;
	
	float land = 1.0-near/far/far;
	float depth0 = texture2D(depthtex0, coord).x;

	return dot(step(land, depth0), 1.0)*cdist(coord);		
}
#endif

/* If you reached this line, then you're probably about to break the agreement which you accepted by downloading Sildur's shaders!
So stop your doing and ask Sildur before copying anything which would break the agreement, unless you're Chocapic then go ahead ;)
--------------------------------------------------------------------------------------------------------------------------------*/

void main() {

float GetRays = 0.0;
vec3 c = vec3(0.0);

if (ntc.x < 1.0 && ntc.y < 1.0 && ntc.x > 0.0 && ntc.y > 0.0) {
float depth1 = texture2D(depthtex1, ntc).x;
float sky = 0.970-near/far/far;

if (depth1 > sky) {
//supersample skybox
vec3 color = pow(texture2D(gaux1, ntc).xyz,vec3(2.2));

vec4 fragpos = gbufferProjectionInverse * (vec4(ntc, depth1, 1.0) * 2.0 - 1.0);
fragpos /= fragpos.w;
/*-----------------------------------------*/

//Draw sky and stars
c = getSkyColor(fragpos.xyz)+moonVisibility*color*0.75;
}

#ifdef Godrays
const int steps = 12;
for (int i = 0; i < steps; i++) {
	GetRays += makeRays(i);
}
	GetRays /= steps;
#endif	

}

gl_FragData[0] = vec4(pow(c/257.0,vec3(0.454)),GetRays);

}