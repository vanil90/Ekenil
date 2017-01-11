#version 120

//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES


//#define GLOWING_SUN         //Usable but sun will get bigger also bugged while rain

#define GODRAYS
	const float exposure = 3.00;			//godrays intensity 1.2 is default
	const float density = 0.8;			
	const int NUM_SAMPLES = 7;			//increase this for better quality at the cost of performance /8 is default
	const float grnoise = 0.0;		//amount of noise /0.0 is default

//#define MOTIONBLUR
	
#define WATER_REFLECTIONS			
	#define REFLECTION_STRENGTH 1.2
	

//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES



//don't touch these lines if you don't know what you do!
const int maxf = 5;				//number of refinements
const float stp = 1.1;			//size of one step for raytracing algorithm
const float ref = 0.1;			//refinement multiplier
const float inc = 2.1;			//increasement factor at each step
const bool gdepthMipmapEnabled = true;

varying vec4 texcoord;
varying vec3 sunlight;
varying vec3 lightVector;
varying vec3 ambient_color;
uniform vec3 previousCameraPosition;

uniform sampler2D depthtex2;
uniform sampler2D composite;
uniform sampler2D gaux4;
uniform sampler2D gaux1;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D gnormal;
uniform sampler2D gdepth;

uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform vec3 moonPosition;
uniform vec3 cameraPosition;
uniform vec3 skyColor;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousModelView;

uniform int isEyeInWater;
uniform int worldTime;

uniform float far;
uniform float near;
uniform float aspectRatio;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform float wetness;

uniform int fogMode;

//Calculate Time of Day
float timefract = worldTime;
float TimeSunrise  = ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0) + (1.0 - (clamp(timefract, 0.0, 4000.0)/4000.0));
float TimeNoon     = ((clamp(timefract, 0.0, 4000.0)) / 4000.0) - ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0);
float TimeSunset   = ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0) - ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0);
float TimeMidnight = ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0) - ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0);
float pw = 1.0/ viewWidth;
float ph = 1.0/ viewHeight;

	float matflag = texture2D(gaux1,texcoord.xy).g;


	vec3 fogclr = mix(gl_Fog.color.rgb,vec3(0.2,0.2,0.2),rainStrength)*ambient_color;
	
    vec3 fragpos = vec3(texcoord.st, texture2D(depthtex0, texcoord.st).r);
    vec3 normal = texture2D(gnormal, texcoord.st).rgb * 2.0 - 1.0;
	
    vec4 color = texture2D(composite,texcoord.xy);
	


float ld(float depth) {
    return (2.0 * near) / (far + near - depth * (far - near));
}

vec3 nvec3(vec4 pos) {
    return pos.xyz/pos.w;
}

vec4 nvec4(vec3 pos) {
    return vec4(pos.xyz, 1.0);
}

float cdist(vec2 coord) {
	return max(abs(coord.x-0.5),abs(coord.y-0.5))*2.0;
}

float luma(vec3 color) {
return dot(color.rgb,vec3(0.299, 0.587, 0.114));
}


vec3 getFogColor(vec3 fposition) {

vec3 sky_color = pow(ambient_color,vec3(2.2));
vec3 sVector = normalize(fposition);
vec3 upVector = normalize(upPosition);

float Lz = 1.0;
float T = acos(max(dot(sVector,upVector),0.0));
float S = acos(dot(lightVector,upVector));
float Y = acos(dot(lightVector,sVector));

sky_color = mix(sky_color,vec3(0.25,0.3,0.4)*length(ambient_color),rainStrength);

float L =  pow(sqrt((((0.91+10*exp(-3*Y)+0.45*pow(cos(Y),2.0))*(1.0-exp(-0.32/cos(T))))/((0.91+10*exp(-3*S)+0.45*pow(cos(S),2.0))*(1.0-exp(-0.32))))),1.0-rainStrength*0.8);

sky_color = mix(sky_color,sunlight,1-exp(-0.3*L*(1-rainStrength*0.8)));



return vec3(L*Lz)*sky_color;

}

vec4 raytrace(vec3 fragpos, vec3 normal) {
    vec4 color = vec4(0.0);
    vec3 start = fragpos;
    vec3 rvector = normalize(reflect(normalize(fragpos), normalize(normal)));
    vec3 vector = stp * rvector;
    vec3 oldpos = fragpos;
    fragpos += vector;
	vec3 tvector = vector;
    int sr = 0;
    for(int i=0;i<30;i++){
        vec3 pos = nvec3(gbufferProjection * nvec4(fragpos)) * 0.5 + 0.5;
        if(pos.x < 0 || pos.x > 1 || pos.y < 0 || pos.y > 1 || pos.z < 0 || pos.z > 1.0) break;
        vec3 spos = vec3(pos.st, texture2D(depthtex1, pos.st).r);
        spos = nvec3(gbufferProjectionInverse * nvec4(spos * 2.0 - 1.0));
        float err = distance(fragpos.xyz,spos.xyz);
        if(err < length(vector)*pow(length(tvector),0.11)*1.75){

                sr++;
                if(sr >= maxf){
                    float border = clamp(1.0 - pow(cdist(pos.st), 5.0), 0.0, 1.0);
                    color = texture2D(composite, pos.st);
					color.a = 1.0;
                    color.a *= border;
                    break;
                }
				tvector -=vector;
                vector *=ref;
				
        
}
        vector *= inc;
        oldpos = fragpos;
        tvector += vector;
		fragpos = start + tvector;
    }
    return color;
}

float getnoise(vec2 pos) {
return abs(fract(sin(dot(pos ,vec2(18.9898f,28.633f))) * 4378.5453f));

}

//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////

void main() {
	int land = int(matflag < 0.03);
	int iswater = int(matflag > 0.04 && matflag < 0.07);
	int hand  = int(matflag > 0.75 && matflag < 0.85);
	
	fragpos = nvec3(gbufferProjectionInverse * nvec4(fragpos * 2.0 - 1.0));

	#ifdef MOTIONBLUR

	vec4 depth  = texture2D(depthtex2, texcoord.st);
	
	vec4 currentPosition = vec4(texcoord.x * 2.0 - 1.0, texcoord.y * 2.0 - 1.0, 2.0 * depth.x - 1.0, 1.0);
	
	vec4 fragposition = gbufferProjectionInverse * currentPosition;
	fragposition = gbufferModelViewInverse * fragposition;
	fragposition /= fragposition.w;
	fragposition.xyz += cameraPosition;
	
	vec4 previousPosition = fragposition;
	previousPosition.xyz -= previousCameraPosition;
	previousPosition = gbufferPreviousModelView * previousPosition;
	previousPosition = gbufferPreviousProjection * previousPosition;
	previousPosition /= previousPosition.w;

	vec2 velocity = (currentPosition - previousPosition).st * 0.03;

	int samples = 1;

	vec2 coord = texcoord.st + velocity;
	for (int i = 0; i < 8; ++i, coord += velocity) {
		if (coord.s > 1.0 || coord.t > 1.0 || coord.s < 0.0 || coord.t < 0.0) {
			break;
		}
            color += texture2D(composite, coord);
			++samples;
	}

	color = (color/1.0)/samples;
	
#endif

	// Add sky colors.
	vec3 skycolor_sunrise = vec3(0.3, 0.50, 0.95) * (1.0-rainStrength*1.0) * TimeSunrise;
	vec3 skycolor_noon = vec3(0.3, 0.6, 1.0) * 0.9 * (1.0-rainStrength*1.0) * TimeNoon;
	vec3 skycolor_sunset = vec3(0.4, 0.6, 1.0) * (1.0-rainStrength*1.0) * TimeSunset;
	vec3 skycolor_night = vec3(0.6, 1.0, 1.3) * 0.0 * TimeMidnight;
	vec3 skycolor_rain_day = vec3(0.8, 0.9, 1.0) * 0.3 * (TimeSunrise + TimeNoon + TimeSunset) * rainStrength;
	vec3 skycolor_rain_night = vec3(0.6, 0.8, 1.0) * 0.05 * TimeMidnight * rainStrength;
	vec3 skycolor = (skycolor_sunrise + skycolor_noon + skycolor_sunset + skycolor_night + skycolor_rain_day + skycolor_rain_night);
	
    if (iswater > 0.9) {

	#ifdef WATER_REFLECTIONS
	vec4 reflection = raytrace(fragpos, normal);
		
		float normalDotEye = dot(normal, normalize(fragpos));
		float fresnel = clamp(pow(1.0 + normalDotEye, 5.0),0.0,1.0);
		
		reflection.rgb = mix(skycolor.rgb, reflection.rgb, reflection.a);			//fake sky reflection, avoid empty spaces
		reflection.a = min(reflection.a + 0.75,1.0);
		color.rgb = mix(color.rgb,reflection.rgb , fresnel * (1.0-isEyeInWater*0.8) * REFLECTION_STRENGTH*reflection.a);
		//color.rgb += (1.0+fresnel)*spec*sunlight*(1.0-isEyeInWater)*8.0;
	#endif
    }
	
		vec3 colmult = mix(vec3(1.0),vec3(0.1,0.25,0.45),isEyeInWater);
		float depth_diff = clamp(pow(ld(texture2D(depthtex0, texcoord.st).r)*3.4,2.0),0.0,1.0);
		color.rgb = mix(color.rgb*colmult,vec3(0.05,0.1,0.15),depth_diff*isEyeInWater);
		
		float time = float(worldTime);
		float transition_fading = 1.0-(clamp((time-12000.0)/300.0,0.0,1.0)-clamp((time-13000.0)/300.0,0.0,1.0) + clamp((time-22800.0)/200.0,0.0,1.0)-clamp((time-23400.0)/200.0,0.0,1.0));
		
		float fog = clamp(exp(-length(fragpos)/192.0*(1.0+rainStrength)/1.4)+0.25*(1.0-rainStrength),0.0,1.0);
		//inject sun color into the fog
		float volumetric_cone = max(dot(normalize(fragpos),lightVector),0.0)*transition_fading;
		//fogclr += sunlight*pow(volumetric_cone,9.0)*1.5*(1.0-rainStrength*0.9);
		float fogfactor =  clamp(fog + hand + isEyeInWater,0.0,1.0);
		fogclr = mix(fogclr,color.rgb,(1.0-rainStrength)*0.7);
		color.rgb = mix(fogclr,color.rgb,fogfactor);
		
		
		
/* DRAWBUFFERS:5 */
	
	//draw rain
	color.rgb += texture2D(gaux4,texcoord.xy).rgb*texture2D(gaux4,texcoord.xy).a;
	
	
		vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
		tpos = vec4(tpos.xyz/tpos.w,1.0);
		vec2 pos1 = tpos.xy/tpos.z;
		vec2 lightPos = pos1*0.5+0.5;



	
#ifdef GODRAYS

		vec2 deltaTextCoord = vec2( texcoord.st - lightPos.xy );
		vec2 textCoord = texcoord.st;
		deltaTextCoord *= 1.0 /  float(NUM_SAMPLES) * density;
		float illuminationDecay = 1.0;
		vec2 noise = vec2(getnoise(textCoord),getnoise(-textCoord.yx+0.05));
		float gr = 0.0;
		float avgdecay = 0.0;
		float distx = abs(texcoord.x*aspectRatio-lightPos.x*aspectRatio);
		float disty = abs(texcoord.y-lightPos.y);
		illuminationDecay = pow(max(1.0-sqrt(distx*distx+disty*disty),0.0),5.0);
		
		float truepos = 0.0f;
		
		if ((worldTime < 13000 || worldTime > 23000) && sunPosition.z < 0) truepos = 1.0 * (TimeSunrise + TimeNoon + TimeSunset); 
		if ((worldTime < 23000 || worldTime > 13000) && -sunPosition.z < 0) truepos = 1.0 * TimeMidnight; 
		
				float fallof = 1.0;
				
		for(int i=0; i < NUM_SAMPLES ; i++) {
		fallof *= 0.85;
				textCoord -= deltaTextCoord;
				float sample = texture2DLod(gdepth, textCoord + noise*grnoise,3).r;
				gr += sample*fallof;
		}
		

		color.rgb += mix(sunlight,getFogColor(fragpos.xyz),rainStrength)*exposure*(gr/NUM_SAMPLES)*(1.0 - rainStrength*0.8)*illuminationDecay*truepos*transition_fading;

#endif



	#ifdef GLOWING_SUN
	if (land > 0.9){
	
		color.rbg += vec3(1.2,0.5,1.0) * 10 *(TimeSunrise + TimeNoon + TimeSunset)* pow(volumetric_cone,500);
	}
	#endif
	
float visiblesun = 0.0;
float temp;
int nb = 0;

			
//calculate sun occlusion (only on one pixel) 
if (texcoord.x < pw && texcoord.x < ph) {
	for (int i = 0; i < 10;i++) {
		for (int j = 0; j < 10 ;j++) {
		temp = texture2D(gaux1,lightPos + vec2(pw*(i-5.0)*10.0,ph*(j-5.0)*10.0)).g;
		visiblesun +=  1.0-float(temp > 0.04) ;
		nb += 1;
		}
	}
	visiblesun /= nb;

}
		color = clamp(color,0.0,1.0);

	gl_FragData[0] = vec4(color.rgb,visiblesun);
	
}
