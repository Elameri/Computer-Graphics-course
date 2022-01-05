#version 410

layout(points) in;
layout(triangle_strip, max_vertices = 4) out;

uniform mat4 matrProj;

uniform int texnumero;
//uniform float tempsDeVieMax;

layout (std140) uniform varsUnif
{
    float tempsDeVieMax;       // temps de vie maximal (en secondes)
    float temps;               // le temps courant dans la simulation (en secondes)
    float dt;                  // intervalle entre chaque affichage (en secondes)
    float gravite;             // gravité utilisée dans le calcul de la position de la particule
    float pointsize;           // taille des points (en pixels)
};

in Attribs {
    vec4 couleur;
    float tempsDeVieRestant;
    float sens; // du vol (partie 3)
    float hauteur; // de la particule dans le repère du monde (partie 3)
} AttribsIn[];

out Attribs {
    vec4 couleur;
    vec2 texCoord;
} AttribsOut;

// la hauteur minimale en-dessous de laquelle les lutins ne tournent plus (partie 3)
const float hauteurInerte = 8.0;

void main()
{

    // assigner la taille des points (en pixels)
    gl_PointSize = gl_in[0].gl_PointSize;

    const float nlutins = 16.0; // 16 positions de vol dans la texture


    vec2 coins[4];
    coins[0] = vec2( -0.5,  0.5 );
    coins[1] = vec2( -0.5, -0.5 );
    coins[2] = vec2(  0.5,  0.5 );
    coins[3] = vec2(  0.5, -0.5 );

    // à partir du point, créer quatre points qui servent de coin aux deux triangles
    for ( int i = 0 ; i < 4 ; ++i )
    {

        float fact = gl_in[0].gl_PointSize; // On utilise la valeur de gl_PointSize pour dimensionner le panneau.

        vec2 decalage = coins[i]; // on positionne successivement aux quatre coins


        
        AttribsOut.couleur = AttribsIn[0].couleur; // assigner la couleur courante
        
        AttribsOut.texCoord = coins[i] + vec2( 0.5, 0.5 ); // on utilise coins[] pour définir des coordonnées de texture

        if (texnumero == 1) { // oiseaux
            
            if (AttribsIn[0].hauteur > hauteurInerte) { // si la hauteur est supérieur à hauteurInerte
                int num = int( mod ( 18.0 * AttribsIn[0].tempsDeVieRestant , nlutins ) ); // 18 Hz
                AttribsOut.texCoord.s = AttribsIn[0].sens * (( AttribsOut.texCoord.s + num ) / nlutins) ;
            }
            else {
                AttribsOut.texCoord.s = AttribsIn[0].sens * (( AttribsOut.texCoord.s ) / nlutins) ;
            }


		}
        else if (texnumero == 2){ // flocons

            if (AttribsIn[0].hauteur > hauteurInerte) { // si la hauteur est supérieur à hauteurInerte
                float angle_rot = 6.0 * AttribsIn[0].tempsDeVieRestant;
                decalage = mat2( cos(angle_rot) , - sin(angle_rot) ,  sin(angle_rot) , cos(angle_rot) ) * decalage;
            }
            
        }


        //les lutins disparaissent en fondant lorsqu’en fin de vie
        if (AttribsIn[0].tempsDeVieRestant < 5){
            AttribsOut.couleur.a = mix( 0, 1,  AttribsIn[0].tempsDeVieRestant/5);
        }

        vec4 pos = vec4( gl_in[0].gl_Position.xy + fact * decalage, gl_in[0].gl_Position.zw );
        

        gl_Position = matrProj * pos;    // on termine la transformation débutée dans le nuanceur de sommets

        
        EmitVertex();
    }


}
