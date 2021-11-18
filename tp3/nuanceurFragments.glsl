#version 410

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

// Définition des paramètres des matériaux
layout (std140) uniform MaterialParameters
{
    vec4 emission;
    vec4 ambient;
    vec4 diffuse;
    vec4 specular;
    float shininess;
} FrontMaterial;

// Définition des paramètres globaux du modèle de lumière
layout (std140) uniform LightModelParameters
{
    vec4 ambient;       // couleur ambiante globale
    bool twoSide;       // éclairage sur les deux côtés ou un seul?
} LightModel;

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

uniform sampler2D laTextureCoul;
uniform sampler2D laTextureNorm;

/////////////////////////////////////////////////////////////////

in Attribs {
    vec4 couleur;
    vec3 lumiDir[3];
    vec3 normale;
    vec3 obsVec;
    vec2 texCoord;
} AttribsIn;

out vec4 FragColor;

float calculerSpot( in vec3 D, in vec3 L, in vec3 N )
{
    float spotFacteur = 0.0;
    return( spotFacteur );
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

void main( void )
{
    
    vec4 texCouleur = texture(laTextureCoul, AttribsIn.texCoord + vec2(-tempsGlissement, 0.0)); // Passage du temps

    if ( typeIllumination == 0 ) { // Gouraud

        FragColor = AttribsIn.couleur; 

        if (iTexCoul != 0) { 
            // lorsque le texel est bien foncé, le rendre complètement transparent
            if (length(texCouleur.rgb) < 0.5) {
                discard;
            }
            else {
                FragColor *= texCouleur; 
            }
        }
    }

    else { //Phong

        vec4 coul = FrontMaterial.emission + FrontMaterial.ambient * LightModel.ambient;

        vec3 N = normalize( AttribsIn.normale );
        vec3 O = normalize( AttribsIn.obsVec );

        for (int j=0; j<3; j++){
            vec3 L = normalize( AttribsIn.lumiDir[j] ); 
            coul += calculerReflexion( j, L, N, O );
        }

        
        FragColor = coul;

        if (iTexCoul != 0) { 
            // lorsque le texel est bien foncé, le rendre complètement transparent
            if (length(texCouleur.rgb) < 0.5) {
                discard;
            }
            else {
                FragColor *= texCouleur; 
            } 
        }

    }

    // seuiller chaque composante entre 0 et 1 et assigner la couleur finale du fragment
    FragColor = clamp(FragColor, 0.0, 1.0 );

}
