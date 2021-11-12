#version 410

////////////////////////////////////////////////////////////////////////////////

// Définition des paramètres des sources de lumière
layout (std140) uniform LightSourceParameters
{
    vec4 ambient;
    vec4 diffuse;
    vec4 specular;
    vec4 position;      // dans le repère du monde
    vec3 spotDirection; // dans le repère du monde
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
    vec4 ambient;       // couleur ambiante
    bool localViewer;   // observateur local ou à l'infini?
    bool twoSide;       // éclairage sur les deux côtés ou un seul?
} LightModel;

////////////////////////////////////////////////////////////////////////////////

uniform int illumination; // on veut calculer l'illumination ?


bool utiliseBlinn = false;

uniform bool afficheNormales;

in Attribs {
    vec3 lumiDir;
    vec3 normale, obsVec;
    vec4 couleur;
} AttribsIn;

out vec4 FragColor;

float attenuation = 1.0;
vec4 calculerReflexion( in vec3 L, in vec3 N, in vec3 O )
{
    vec4 coul = FrontMaterial.emission + FrontMaterial.ambient * LightModel.ambient;

    // calculer la composante ambiante pour la source de lumière
    coul += FrontMaterial.ambient * LightSource.ambient;

    // calculer l'éclairage seulement si le produit scalaire est positif
    float NdotL = max( 0.0, dot( N, L ) );
    if ( NdotL > 0.0 )
    {
        // calculer la composante diffuse
        // (dans cet exemple, on utilise plutôt la couleur de l'objet au lieu de FrontMaterial.diffuse)
        //coul += attenuation * FrontMaterial.diffuse * LightSource.diffuse * NdotL;
        coul += attenuation * AttribsIn.couleur * LightSource.diffuse * NdotL;

        // calculer la composante spéculaire (Blinn ou Phong : spec = BdotN ou RdotO )
        float spec = ( utiliseBlinn ?
                       dot( normalize( L + O ), N ) : // dot( B, N )
                       dot( reflect( -L, N ), O ) ); // dot( R, O )
        if ( spec > 0 ) coul += attenuation * FrontMaterial.specular * LightSource.specular * pow( spec, FrontMaterial.shininess );
    }

    return( coul );
}

void main(void)
{
    if (illumination == 1) {
        vec3 L = normalize( AttribsIn.lumiDir ); // vecteur vers la source lumineuse
        //vec3 N = normalize( AttribsIn.normale ); // vecteur normal
        vec3 N = normalize( gl_FrontFacing ? AttribsIn.normale : -AttribsIn.normale );
        vec3 O = normalize( AttribsIn.obsVec );  // position de l'observateur

        vec4 coul = calculerReflexion( L, N, O );

        // seuiller chaque composante entre 0 et 1 et assigner la couleur finale du fragment
 
        FragColor = clamp( coul, 0.0, 1.0 );

        // Pour « voir » les normales, on peut remplacer la couleur du fragment par la normale.
        // (Les composantes de la normale variant entre -1 et +1, il faut
        // toutefois les convertir en une couleur entre 0 et +1 en faisant (N+1)/2.)
        if ( afficheNormales ) FragColor = clamp( vec4( (N+1)/2, AttribsIn.couleur.a ), 0.0, 1.0 );
    }
    else {
        FragColor = AttribsIn.couleur;
    }


}
