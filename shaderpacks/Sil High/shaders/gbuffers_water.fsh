#version 120
/* DRAWBUFFERS:526 */
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
varying vec4 ambientNdotL;
varying vec4 sunlightMat;
varying vec4 transparentBlocks;
vec3 sunlight = sunlightMat.rgb;

varying vec3 normal;
varying mat3 tbnMatrix;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

uniform sampler2D noisetex;
uniform sampler2D texture;

uniform vec3 sunPosition;
uniform vec3 cameraPosition;
uniform int worldTime;
uniform float frameTimeCounter;
uniform float viewWidth;
uniform float viewHeight;

//Normal
vec4 encode (vec3 n, float dif){
    float p = sqrt(n.z*8+8);

	float vis = lmcoord.t;
	if (ambientNdotL.a > 0.9) vis = vis / 4.0;
	if (ambientNdotL.a > 0.4 && ambientNdotL.a < 0.6) vis = vis/4.0+0.25;
	if (ambientNdotL.a < 0.1) vis = vis/4.0+0.5;

    return vec4(n.xy/p + 0.5,vis,1.0);
}

float noisetexture(vec2 coord, float offset, float speed){
return texture2D(noisetex, coord*offset + frameTimeCounter*speed).x/offset;
}

float noiseW(vec3 pos){
	vec2 coord = fract(pos.xz / 1000);
	
	float noise = noisetexture(coord, 0.5, 0.0030);
		  noise -= noisetexture(coord, 0.5, -0.0030);
		  noise += noisetexture(coord, 2.0, 0.0045);
		  noise -= noisetexture(coord, 2.0, -0.0045);
		  noise += noisetexture(coord, 3.5, 0.0060);
		  noise -= noisetexture(coord, 3.5, -0.0060);
		  noise += noisetexture(coord, 5.0, 0.0075);
		  noise -= noisetexture(coord, 5.0, -0.0075);

	return noise;
}

void main() {

	float iswater = ambientNdotL.a;
	float istransparent = transparentBlocks.a;
	
	float diffuse = dot(normalize(sunPosition),normal);
	diffuse = (worldTime > 12700 && worldTime < 23250)? -diffuse : diffuse;

	//Colors
	vec4 albedo = texture2D(texture, texcoord.xy)*color*(istransparent);	//Fix transparent blocks alpha/color
	if (iswater > 0.9)albedo.rgb = mix(albedo.rgb,vec3(0.0, 0.6, 0.8),0.7);	//Watercolor
	vec3 sunlightcolor = (1.0-iswater)*sunlight*(1.0-istransparent)*diffuse;	//Add transparent blocks to lighting

	vec3 newnormal = normal;

if (iswater > 0.9){
	//Positioning
	vec4 fragposition = gbufferProjectionInverse*(vec4(gl_FragCoord.xy/vec2(viewWidth,viewHeight),gl_FragCoord.z,1.0)*2.0-1.0);
	fragposition /= fragposition.w;
	vec4 worldposition = gbufferModelViewInverse * fragposition;

	//Refraction
	vec3 waterpos = worldposition.xyz+cameraPosition;
		waterpos.x -= (waterpos.x-frameTimeCounter*0.05)*7.0;
		waterpos.z -= (waterpos.z-frameTimeCounter*0.05)*7.0;

	const float deltaPos = 0.4;
	float h0 = noiseW(waterpos);
	float h1 = noiseW(waterpos + vec3(deltaPos,0.0,0.0));
	float h2 = noiseW(waterpos + vec3(-deltaPos,0.0,0.0));
	float h3 = noiseW(waterpos + vec3(0.0,0.0,deltaPos));
	float h4 = noiseW(waterpos + vec3(0.0,0.0,-deltaPos));

	float xDelta = ((h1-h0)+(h0-h2))/deltaPos;
	float yDelta = ((h3-h0)+(h0-h4))/deltaPos;

	//Bump mapping
	const float bumpmult = 0.03;
	vec3 bumpMapping = normalize(vec3(xDelta,yDelta,1.0-xDelta*xDelta-yDelta*yDelta));
	bumpMapping = bumpMapping * vec3(bumpmult, bumpmult, bumpmult) + vec3(0.0f, 0.0f, 1.0f - bumpmult);

	newnormal = vec3(normalize(bumpMapping * tbnMatrix));
}

	vec3 fColor = pow(albedo.rgb*(sunlightcolor*2.15+ambientNdotL.rgb*1.3)*0.63,vec3(0.454));
	float alpha = mix(albedo.a,0.35,max(iswater*2.0-1.0,0.0));

	gl_FragData[0] = vec4(fColor,alpha);
	gl_FragData[1] = encode(newnormal.rgb, diffuse);
	gl_FragData[2] = vec4(normalize(pow(albedo.rgb,vec3(0.454))),alpha);
}
