   mami_circle   	   MatrixPVW                                                                                SAMPLER    +         IMAGE_PARAMS                                PosUVColour.vs�  
// 巴麻美 扇形切割 by 老王
// Mami shader
// fan animation

uniform mat4 MatrixPVW;

attribute vec3 POSITION;
attribute vec2 TEXCOORD0;
attribute vec4 DIFFUSE;

varying vec2 PS_TEXCOORD;
varying vec4 PS_COLOUR;

void main()
{
	gl_Position = MatrixPVW * vec4( POSITION.xyz, 1.0 );
	PS_TEXCOORD.xy = TEXCOORD0.xy;
	PS_COLOUR.rgba = vec4( DIFFUSE.rgb * DIFFUSE.a, DIFFUSE.a ); // premultiply the alpha
}    ui.ps�  
#if defined( GL_ES )
precision mediump float;
#endif

uniform sampler2D SAMPLER[1];
varying vec2 PS_TEXCOORD;
varying vec4 PS_COLOUR;

uniform vec2 ALPHA_RANGE;
uniform vec4 IMAGE_PARAMS;

// #define ALPHA_MIN   ALPHA_RANGE.x
// #define ALPHA_MAX   ALPHA_RANGE.y

// coord of center
#define X	IMAGE_PARAMS.x 
#define Y 	IMAGE_PARAMS.y 
// angle
#define ANGLE IMAGE_PARAMS.z
// 0 = DS, 1 = DST
#define IS_DST	IMAGE_PARAMS.w

float Mami_GetAngle(float x, float y){
	float a = atan(y/x)+1.571;
	if (x < 0.0){
		a += 3.1416;
	}
	if (a < 0.0){
		a += 6.2832;
	}
	
	return a;
}

void main()
{
	vec4 colour = texture2D( SAMPLER[0], PS_TEXCOORD.xy );
	colour.rgba *= PS_COLOUR.rgba;
	gl_FragColor = colour;

	float a = Mami_GetAngle(PS_TEXCOORD.x - X, PS_TEXCOORD.y - Y);
	float alpha = clamp(1.0-(a-ANGLE)*20.0, 0.0, 1.0);

	// Should I premultipy alpha in DS?.....
	gl_FragColor = vec4(colour.rgb * alpha, colour.a * alpha);
}                 