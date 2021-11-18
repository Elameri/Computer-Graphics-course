#version 410



// D�finition des param�tres des sources de lumi�re
layout (std140) uniform LightSourceParameters
{
    vec4 ambient[3];
    vec4 diffuse[3];
    vec4 specular[3];
    vec4 position[3];      // dans le rep�re du monde
    vec3 spotDirection[3]; // dans le rep�re du monde
    float spotExponent;
    float spotAngleOuverture; // ([0.0,90.0] ou 180.0)
    float constantAttenuation;
    float linearAttenuation;
    float quadraticAttenuation;
} LightSource;

// D�finition des param�tres des mat�riaux
layout (std140) uniform MaterialParameters
{
    vec4 emission;
    vec4 ambient;
    vec4 diffuse;
    vec4 specular;
    float shininess;
} FrontMaterial;

// D�finition des param�tres globaux du mod�le de lumi�re
layout (std140) uniform LightModelParameters
{
    vec4 ambient;       // couleur ambiante globale
    bool twoSide;       // �clairage sur les deux c�t�s ou un seul?
} LightModel;

layout (std140) uniform varsUnif
{
    // partie 1: illumination
    int typeIllumination;     // 0:Gouraud, 1:Phong
    bool utiliseBlinn;        // indique si on veut utiliser mod�le sp�culaire de Blinn ou Phong
    bool utiliseDirect;       // indique si on utilise un spot style Direct3D ou OpenGL
    bool afficheNormales;     // indique si on utilise les normales comme couleurs (utile pour le d�bogage)
    // partie 2: texture
    float tempsGlissement;    // temps de glissement
    int iTexCoul;             // num�ro de la texture de couleurs appliqu�e
    // partie 3b: texture
    int iTexNorm;             // num�ro de la texture de normales appliqu�e
};

uniform mat4 matrModel;
uniform mat4 matrVisu;
uniform mat4 matrProj;
uniform mat3 matrNormale;

/////////////////////////////////////////////////////////////////

layout(location=0) in vec4 Vertex;
layout(location=2) in vec3 Normal;
layout(location=8) in vec4 TexCoord;

out Attribs {
    vec4 couleur;
    vec3 normale;
    vec2 texCoord;
} AttribsOut;


void main( void )
{   
    // appliquer la transformation standard du sommet (P * V * M * sommet)
    gl_Position = matrModel * Vertex;
    AttribsOut.normale = matrNormale * Normal;
    AttribsOut.texCoord = TexCoord.st;

}
