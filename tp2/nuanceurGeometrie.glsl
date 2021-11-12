#version 410

layout(triangles) in;
layout(triangle_strip, max_vertices = 3) out;

in Attribs {
	vec4 couleur;
} AttribsIn[];

out Attribs {
	vec3 lumiDir;
	vec3 normale, obsVec;
	vec4 couleur;
} AttribsOut;


void main() {

	AttribsOut.lumiDir = vec3( 0, 0, 1 );
	AttribsOut.obsVec = vec3( 0, 0, 1 );

	vec4 Sommet0 = gl_in[0].gl_Position;
	vec4 Sommet1 = gl_in[1].gl_Position;
	vec4 Sommet2 = gl_in[2].gl_Position;

	vec3 arete1 = vec3( Sommet1 - Sommet0 );
	vec3 arete2 = vec3( Sommet2 - Sommet0 );

	AttribsOut.normale = cross ( arete1 , arete2 );

	for ( int i = 0 ; i < gl_in.length() ; ++i ) {
		gl_Position = gl_in[i].gl_Position;
		AttribsOut.couleur = AttribsIn[i].couleur;
		EmitVertex();
	}

	EndPrimitive(); // implicite à la fin du nuanceur
}