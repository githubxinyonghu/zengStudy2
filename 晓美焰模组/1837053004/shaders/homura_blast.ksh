   homura_blast      SAMPLER    +         SCREEN_PARAMS                                HOMURA_BLAST                                postprocess_base.vs´   attribute vec3 POSITION;
attribute vec2 TEXCOORD0;

varying vec2 PS_TEXCOORD0;

void main()
{
	gl_Position = vec4( POSITION.xyz, 1.0 );
	PS_TEXCOORD0.xy = TEXCOORD0.xy;
}    homura_blast.ps  // HOMURA SHADER: åå¤æ©æ£çéè¡æ³¢
// x,y: åå¿  z: å¤å¾  w: åå¾

#if defined( GL_ES )
precision highp float;
#endif

uniform sampler2D SAMPLER[1];

#define SRC_IMAGE SAMPLER[0]

uniform vec4 SCREEN_PARAMS;

#define W_H  (SCREEN_PARAMS.x / SCREEN_PARAMS.y)

uniform vec4 HOMURA_BLAST;

#define P            HOMURA_BLAST 
#define X 	         P.x 
#define Y            P.y 
#define OUTER_RADIUS P.z
#define INNER_RADIUS P.z - 0.04
#define INTENSITY	 P.w

varying vec2 PS_TEXCOORD0;

void main(void)
{	
	vec2 offset_vec = vec2(PS_TEXCOORD0.x - X, (PS_TEXCOORD0.y  - Y) / W_H);
	float len = length(offset_vec);
	if (len < INNER_RADIUS || len > OUTER_RADIUS)
		gl_FragColor.xyz = texture2D(SRC_IMAGE, PS_TEXCOORD0).xyz;
	else
		gl_FragColor.xyz = texture2D(SRC_IMAGE, 
			PS_TEXCOORD0 - normalize(offset_vec) * (len - INNER_RADIUS) * INTENSITY).xyz;
}
                  