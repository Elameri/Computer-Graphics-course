#version 410

uniform sampler2D leLutin;
uniform int texnumero;

in Attribs {
    vec4 couleur;
    vec2 texCoord;
} AttribsIn;

out vec4 FragColor;

void main( void )
{

    //FragColor = texture( leLutin, gl_PointCoord );

    if ( texnumero != 0 )
    {
        vec4 couleur = texture( leLutin, AttribsIn.texCoord );
        
        if (couleur.a < 0.1){
            discard;
        }
        FragColor.rgb =  mix( AttribsIn.couleur.rgb, couleur.rgb, 0.6 );
        FragColor.a = AttribsIn.couleur.a;
    }
    else {
        FragColor = AttribsIn.couleur;
    }

}
