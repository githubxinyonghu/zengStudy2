   homura_sniper      SAMPLER    +         HOMURA_FOCUS                                SCREEN_PARAMS                                postprocess_base.vs�   attribute vec3 POSITION;
attribute vec2 TEXCOORD0;

varying vec2 PS_TEXCOORD0;

void main()
{
	gl_Position = vec4( POSITION.xyz, 1.0 );
	PS_TEXCOORD0.xy = TEXCOORD0.xy;
}    homura_sniper.ps�  #if defined( GL_ES )
precision highp float;
#endif

uniform sampler2D SAMPLER[2];
uniform vec4 HOMURA_FOCUS;

#define SRC_IMAGE        SAMPLER[0]
#define BLUR_BUFFER     SAMPLER[1]

uniform vec4 SCREEN_PARAMS;

#define W_H  (SCREEN_PARAMS.x / SCREEN_PARAMS.y)

#define P       HOMURA_FOCUS
#define X 	    P.x 
#define Y       P.y 
#define RADIUS 	P.z
#define SCALE	P.a   

varying vec2 PS_TEXCOORD0;

void main()
{
	vec2 offset = vec2(PS_TEXCOORD0.x - X, (PS_TEXCOORD0.y - Y) / W_H);

	if (length(offset) > RADIUS){
		gl_FragColor.xyz = texture2D(BLUR_BUFFER, PS_TEXCOORD0.xy).xyz * 0.5;
	}
	else{
		gl_FragColor.xyz = texture2D(SRC_IMAGE, vec2(offset.x / SCALE + X, offset.y / SCALE * W_H + Y)).xyz;
	}
}                  