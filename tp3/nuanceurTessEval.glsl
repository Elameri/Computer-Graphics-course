#version 410

layout(quads) in;

// Définition des paramètres des sources de lumière
layout (std140) uniform LightSourceParameters
{
    vec4 ambient[3];
    vec4 diffuse[3];
    vec4 specular[3];
    vec4 position[3];      // dans le repère du monde
    vec3 spotDirection[3]; // dans le repère du monde
    float spotExponent;
    float spotAngleOuverture; // ([0.0,90.0] ou 180.0)
    float constantAttenuation;
    float linearAttenuation;
    float quadraticAttenuation;
} LightSource;

layout (std140) uniform varsUnif
{
    // partie 1: illumination
    int typeIllumination;     // 0:Gouraud, 1:Phong
    bool utiliseBlinn;        // indique si on veut utiliser modèle spéculaire de Blinn ou Phong
    bool utiliseDirect;       // indique si on utilise un spot style Direct3D ou OpenGL
    bool afficheNormales;     // indique si on utilise les normales comme couleurs (utile pour le débogage)
    // partie 2: texture
    float tempsGlissement;    // temps de glissement
    int iTexCoul;             // numéro de la texture de couleurs appliquée
    // partie 3b: texture
    int iTexNorm;             // numéro de la texture de normales appliquée
};

// Définition des paramètres des matériaux
layout (std140) uniform MaterialParameters
{
    vec4 emission;
    vec4 ambient;
    vec4 diffuse;
    vec4 specular;
    float shininess;
} FrontMaterial;

layout (std140) uniform LightModelParameters
{
    vec4 ambient;       // couleur ambiante globale
    bool twoSide;       // éclairage sur les deux côtés ou un seul?
} LightModel;

in Attribs {
    vec4 couleur;
    vec3 normale;
    vec2 texCoord;
} AttribsIn[];

out Attribs {
    vec4 couleur;
    vec3 lumiDir[3];
    vec3 normale;
    vec3 obsVec;
    vec2 texCoord;
} AttribsOut;

uniform mat4 matrModel;
uniform bool deformer;
uniform mat4 matrVisu;
uniform mat4 matrProj;
uniform mat3 matrNormale;

float interpole( float v0, float v1, float v2, float v3 )
{
    // mix( x, y, f ) = x * (1-f) + y * f.
    float v01 = mix( v0, v1, gl_TessCoord.x );
    float v32 = mix( v3, v2, gl_TessCoord.x );
    return mix( v01, v32, gl_TessCoord.y );
}
vec2 interpole( vec2 v0, vec2 v1, vec2 v2, vec2 v3 )
{
    // mix( x, y, f ) = x * (1-f) + y * f.
    vec2 v01 = mix( v0, v1, gl_TessCoord.x );
    vec2 v32 = mix( v3, v2, gl_TessCoord.x );
    return mix( v01, v32, gl_TessCoord.y );
}
vec3 interpole( vec3 v0, vec3 v1, vec3 v2, vec3 v3 )
{
    // mix( x, y, f ) = x * (1-f) + y * f.
    vec3 v01 = mix( v0, v1, gl_TessCoord.x );
    vec3 v32 = mix( v3, v2, gl_TessCoord.x );
    return mix( v01, v32, gl_TessCoord.y );
}
vec4 interpole( vec4 v0, vec4 v1, vec4 v2, vec4 v3 )
{
    // mix( x, y, f ) = x * (1-f) + y * f.
    vec4 v01 = mix( v0, v1, gl_TessCoord.x );
    vec4 v32 = mix( v3, v2, gl_TessCoord.x );
    return mix( v01, v32, gl_TessCoord.y );
}
float attenuation = 1.0;

vec4 calculerReflexion( in int j, in vec3 L, in vec3 N, in vec3 O ) // pour la lumière j
{
    vec4 coul = vec4(0);

    // calculer l'éclairage seulement si le produit scalaire est positif
    float NdotL = max( 0.0, dot( N, L ) );
    if ( NdotL > 0.0 )
    {
        // calculer la composante diffuse
        coul += attenuation * FrontMaterial.diffuse * LightSource.diffuse[j] * NdotL;

        // calculer la composante spéculaire (Blinn ou Phong : spec = BdotN ou RdotO )
        float spec = ( utiliseBlinn ?
                       dot( normalize( L + O ), N ) : // dot( B, N )
                       dot( reflect( -L, N ), O ) ); // dot( R, O )
        if ( spec > 0 ) coul += attenuation * FrontMaterial.specular * LightSource.specular[j] * pow( spec, FrontMaterial.shininess );
    }

    return( coul );
}

void main()
{
   
    // interpoler la position et les attributs selon gl_TessCoord
    
    AttribsOut.couleur = interpole( AttribsIn[0].couleur, AttribsIn[1].couleur, AttribsIn[3].couleur, AttribsIn[2].couleur );

    vec4 positionScene = interpole( gl_in[0].gl_Position, gl_in[1].gl_Position, gl_in[3].gl_Position, gl_in[2].gl_Position );

    AttribsOut.normale = interpole( AttribsIn[0].normale, AttribsIn[1].normale, AttribsIn[3].normale, AttribsIn[2].normale);
    AttribsOut.texCoord = interpole( AttribsIn[0].texCoord, AttribsIn[1].texCoord, AttribsIn[3].texCoord, AttribsIn[2].texCoord);

    vec3 N = normalize ( AttribsOut.normale);
    vec3 pos = vec3( matrVisu *positionScene);
    vec3 obsVec = (-pos); // part de position vers camera

    for (int j=0; j<AttribsOut.lumiDir.length; j++){
        AttribsOut.lumiDir[j] = ( matrVisu * LightSource.position[j] ).xyz - pos;
     }

    if ( typeIllumination == 0 ) { // Gouraud

        // normale et position de l'observateur
        vec3 O = normalize( obsVec ); // normalize transforme en matrice unitaire

        // calcul de la composante ambiante du modèle
        vec4 coul = FrontMaterial.emission + FrontMaterial.ambient * LightModel.ambient;

        for (int j=0; j<AttribsOut.lumiDir.length; j++){

            // vecteur vers la source lumineuse
            vec3 L = normalize( AttribsOut.lumiDir[j] );

            // couleur du sommet
            coul += calculerReflexion( j, L, N, O );
        }
        AttribsOut.couleur = clamp( coul, 0.0, 1.0 );
    }
        AttribsOut.obsVec= obsVec;
     gl_Position = matrProj* matrVisu * positionScene; // PVM 

}

