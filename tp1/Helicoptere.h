#ifndef __HELICOPTERE_H__
#define __HELICOPTERE_H__

// les formes
FormeCube* cube = NULL;
FormeQuad* quad = NULL;
FormeSphere* sphere = NULL;
FormeCylindre* cylindre = NULL;
// (partie 1) Vous devez vous servir des quatre fonctions ci-dessous (*sans les modifier*) pour tracer tous les parties des objets.
// affiche un cylindre de rayon 1.0 et de longueur 1.0, dont la base est centrée en (0,0,0)
void afficherCylindre() { cylindre->afficher(); }
// affiche une sphère de rayon 1.0, centrée en (0,0,0)
void afficherSphere() { sphere->afficher(); }
// affiche un cube d'arête 1.0, centrée en (0,0,0)
void afficherCube() { cube->afficher(); }
// affiche un quad d'arête 1
void afficherQuad() { quad->afficher(); }

// affiche la position courante du repère (pour débogage)
void afficherRepereCourant(int num = 0)
{
    glUniformMatrix4fv(locmatrModel, 1, GL_FALSE, matrModel);
    FenetreTP::afficherAxes(1.5, 3.0);
}

// partie 1: l'helicoptere
class Helicoptere
{
public:
    Helicoptere()
    {
        initVar();
        // créer l'hélicoptère graphique
        initialiserGraphique();

        // créer quelques autres formes
        cube = new FormeCube(1.0, true);
        quad = new FormeQuad(1.0, true);
        sphere = new FormeSphere(1.0, 8, 8, true);
        cylindre = new FormeCylindre(1.0, 1.0, 1.0, 16, 1, true);
    }
    ~Helicoptere()
    {
        conclureGraphique();
        delete cube;
        delete quad;
        delete sphere;
        delete cylindre;
    }

    void initVar() { position = glm::vec3(0.25 * Etat::dimBoite, 0.0, 0.0); taille = 1; angleCorps = anglePale = 0.0; anglePatte = 70.0; }
    void verifierAngles() // vérifier que les angles ne débordent pas les valeurs permises
    {
        if (anglePatte > 90.0) anglePatte = 90.0; else if (anglePatte < 45.0) anglePatte = 45.0;
    }

    void initialiserGraphique()
    {
        GLint prog = 0; 
        glGetIntegerv(GL_CURRENT_PROGRAM, &prog);
        if (prog <= 0) {
            std::cerr << "Pas de programme actif!" << std::endl;
            locVertex = locColor = -1;
            return;
        }
        if ((locVertex = glGetAttribLocation(prog, "Vertex")) == -1) std::cerr << "!!! pas trouvé la \"Location\" de Vertex" << std::endl;
        if ((locColor = glGetAttribLocation(prog, "Color")) == -1) std::cerr << "!!! pas trouvé la \"Location\" de Color" << std::endl;

        // allouer les objets OpenGL
        glGenVertexArrays(1, &vao);

        // initialiser le VAO pour la théière
        glBindVertexArray(vao);



        // (partie 2) MODIFICATIONS

        GLuint vbo[2];
        glGenBuffers(2, vbo);

        // créer le VBO pour les sommets, le lier au tampon courant et copier le tableau de sommets dessus
        glBindBuffer(GL_ARRAY_BUFFER, vbo[0]);
        glBufferData(GL_ARRAY_BUFFER, sizeof(gTheiereSommets), gTheiereSommets, GL_STATIC_DRAW);
        // on a déja le numéro d’attribut dans le vertex shader (locVertex), on donne la struct du VBO de sommets
        glVertexAttribPointer(locVertex, 3, GL_FLOAT, GL_FALSE, 0, 0);
        // puis on active l'utilisation de ce VBO pour l’affichage
        glEnableVertexAttribArray(locVertex);


        // créer le VBO la connectivité, le lier au tampon courant et copier le tableau des connectivités dessus
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo[1]);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(gTheiereConnec), gTheiereConnec, GL_STATIC_DRAW);
        
        // on défait les liens
        glBindVertexArray(0);
    }

    void conclureGraphique()
    {
        glDeleteBuffers(1, &vboTheiereSommets);
        glDeleteBuffers(1, &vboTheiereConnec);
    }

    // (partie 2)
    void afficherTheiere()
    {
        glBindVertexArray(vao);
        // (partie 2)
        glDrawElements(GL_TRIANGLES, sizeof(gTheiereConnec) / sizeof(GLuint), GL_UNSIGNED_INT, 0);
        glBindVertexArray(0);
    }

    // afficher la boite (le corps) de l'hélicoptère.
    // - Le corps de l'hélicoptère est un cube légèrement étiré en z (avant-arrière) : facteurs d'échelle = ( 1.0, 1.0, 1.5 ).
    //   Pour la partie 2, la taille de la théière sera simplement modulée par ( 0.25, 0.25, 0.25 ).
    // - Le bas du cube corps est déplacé à l'origine.
    // Au-dessus du corps, un mat vertical est représenté par un cylindre vertical de taille ( 0.1, 0.1, 0.5 )
    void afficherCorps()
    {
        // donner la couleur de la boite
        glVertexAttrib3f(locColor, 1.0, 1.0, 1.0); // blanc

        // afficherRepereCourant( ); // débogage: montrer le repère à la position courante

        //Afficher la boite
        // afficher le bon modèle
        switch (Etat::modele)
        {
        default:
        case 1: // un cube
            matrModel.PushMatrix(); {
                matrModel.Scale(1.0, 1.0, 1.5);
                matrModel.Translate(0.0, 0.5, 0.0);
                glUniformMatrix4fv(locmatrModel, 1, GL_FALSE, matrModel);
                afficherCube();
            }matrModel.PopMatrix(); glUniformMatrix4fv(locmatrModel, 1, GL_FALSE, matrModel);

            // et son mat
            matrModel.PushMatrix(); {
                matrModel.Rotate(90.0, 1.0, 0.0, 0.0);
                matrModel.Scale(0.1, 0.1, 0.5);
                matrModel.Translate(0.0, 0.0, -3);
                glVertexAttrib3f(locColor, 0.0, 1.0, 1.0); // cyan
                glUniformMatrix4fv(locmatrModel, 1, GL_FALSE, matrModel);
                afficherCylindre();
            }matrModel.PopMatrix(); glUniformMatrix4fv(locmatrModel, 1, GL_FALSE, matrModel);
            break;

        case 2: // la théière
            matrModel.PushMatrix(); {
                matrModel.Scale(0.25, 0.25, 0.25);
                glUniformMatrix4fv(locmatrModel, 1, GL_FALSE, matrModel);
                afficherTheiere();
            }matrModel.PopMatrix(); glUniformMatrix4fv(locmatrModel, 1, GL_FALSE, matrModel);
            break;
        }
    }

    // afficher les deux pales
    // Une pale est un quadrilatère de longueur "4" et de largeur ".2".
    // - La première pale est à hauteur de 0.25 au-dessus de la face supérieure du corps et tourne dans le sens horaire lorsque vue du dessus.
    // - La seconde pale est à hauteur de 0.50 au-dessus de la face supérieure du corps et tourne dans le sens antihoraire
    // L'angle de rotation des pales est donné par la variable « anglePale ».
    void afficherPales()
    {

        matrModel.PushMatrix(); {
            // pale verte
            glVertexAttrib3f(locColor, 0.0, 1.0, 0.0); // vert
            matrModel.Rotate(anglePale, 0.0, 1.0, 0.0);
            matrModel.Rotate(90.0, 1.0, 0.0, 0.0);
            matrModel.Scale(4.0, 0.2, 1.0);
            matrModel.Translate(-0.5, -0.5, -1.5);
            glUniformMatrix4fv(locmatrModel, 1, GL_FALSE, matrModel);
            afficherQuad();
        }matrModel.PopMatrix(); glUniformMatrix4fv(locmatrModel, 1, GL_FALSE, matrModel);


        matrModel.PushMatrix(); {
            // pale violette
            glVertexAttrib3f(locColor, 0.5, 0.5, 1.0); // violet
            matrModel.Rotate(anglePale, 0.0, -1.0, 0.0);
            matrModel.Rotate(90.0, 1.0, 0.0, 0.0);
            matrModel.Scale(4.0, 0.2, 1.0);
            matrModel.Translate(-0.5, -0.5, -1.25);
            glUniformMatrix4fv(locmatrModel, 1, GL_FALSE, matrModel);
            afficherQuad();
        }matrModel.PopMatrix(); glUniformMatrix4fv(locmatrModel, 1, GL_FALSE, matrModel);


    }

    // afficher les pattes
    // Les pattes sont des cylindres de largeur « largMembre » et longueur « longMembre ».
    // Les pattes sont attachées en haut de la boite du corps de l'hélicoptère à « anglePatte » degrés d'écart.
    void afficherPattes()
    {
        // donner la couleur des pattes
        glVertexAttrib3f(locColor, 0.9, 0.4, 0.0); // marron;

        // 1ère patte
        matrModel.PushMatrix(); {

            matrModel.Translate(-0.5, 1, -1.5 / 2);
            matrModel.Rotate(90, 0, 0, 1);
            matrModel.Rotate(45, 1, 0, 0);
            matrModel.Rotate(anglePatte+180 , 0.0, 1, 0);

            matrModel.Scale(largMembre, largMembre, longMembre);
            glUniformMatrix4fv(locmatrModel, 1, GL_FALSE, matrModel);

            glUniformMatrix4fv(locmatrModel, 1, GL_FALSE, matrModel);
            afficherCylindre();
        }matrModel.PopMatrix(); glUniformMatrix4fv(locmatrModel, 1, GL_FALSE, matrModel);

        // 2ème patte
        matrModel.PushMatrix(); {

            matrModel.Translate(0.5, 1, -1.5 / 2);
            matrModel.Rotate(90, 0, 0, 1);
            matrModel.Rotate(-45, 1, 0, 0);
            matrModel.Rotate(-anglePatte - 180, 0.0, -1, 0);

            matrModel.Scale(largMembre, largMembre, longMembre);
            glUniformMatrix4fv(locmatrModel, 1, GL_FALSE, matrModel);

            afficherCylindre();
        }matrModel.PopMatrix(); glUniformMatrix4fv(locmatrModel, 1, GL_FALSE, matrModel);



        // 3ème patte
        matrModel.PushMatrix(); {

            matrModel.Translate(-0.5, 1, 1.5 / 2);
            matrModel.Rotate(90, 0, 0, 1);
            matrModel.Rotate(135, 1, 0, 0);
            matrModel.Rotate(anglePatte - 180, 0.0, 1, 0);

            matrModel.Scale(largMembre, largMembre, longMembre);
            glUniformMatrix4fv(locmatrModel, 1, GL_FALSE, matrModel);

            afficherCylindre();
        }matrModel.PopMatrix(); glUniformMatrix4fv(locmatrModel, 1, GL_FALSE, matrModel);

        // 4ème patte
        matrModel.PushMatrix(); {

            matrModel.Translate(0.5, 1, 1.5 / 2);
            matrModel.Rotate(90, 0, 0, 1);
            matrModel.Rotate(225, 1, 0, 0);
            matrModel.Rotate(anglePatte - 180, 0.0, 1, 0);

            matrModel.Scale(largMembre, largMembre, longMembre);
            glUniformMatrix4fv(locmatrModel, 1, GL_FALSE, matrModel);

            afficherCylindre();
        }matrModel.PopMatrix(); glUniformMatrix4fv(locmatrModel, 1, GL_FALSE, matrModel);
    }

    void afficher()
    {
        // afficherRepereCourant( ); // débogage: montrer le repère à la position courante
        matrModel.PushMatrix(); { // sauvegarder la transformation courante

            // ajouter une ou des transformations
            // L'hélicoptère
            //   est placé à la position courante « position[] »,
            //   est orienté selon l'angle « angleCorps » et
            //   est de taille ( taille, taille, taille ),

            matrModel.Translate(position.x, position.y, position.z);
            matrModel.Rotate(angleCorps, 0, 1, 0);
            matrModel.Scale(taille, taille, taille);

            // afficher le corps
            afficherCorps();

            // afficher les pales
            afficherPales();

            // afficher les quatre pattes
            afficherPattes();

        }matrModel.PopMatrix(); glUniformMatrix4fv(locmatrModel, 1, GL_FALSE, matrModel);
        glUniformMatrix4fv(locmatrModel, 1, GL_FALSE, matrModel); // informer ...
    }

    void calculerPhysique()
    {
        if (Etat::enmouvement)
        {
            static int sens[6] = { +1, +1, +1, +1, +1, +1 };
            glm::vec3 vitesse(0.03, 0.02, 0.05);
            // mouvement en X
            if (position.x - taille <= -0.5 * Etat::dimBoite) sens[0] = +1;
            else if (position.x + taille >= 0.5 * Etat::dimBoite) sens[0] = -1;
            position.x += 60 * Etat::dt * vitesse.x * sens[0];
            // mouvement en Y
            if (position.y - taille <= 0.0) sens[2] = +1;
            else if (position.y + taille >= Etat::dimBoite) sens[2] = -1;
            position.y += 60 * Etat::dt * vitesse.y * sens[2];
            // mouvement en Z
            if (position.z - taille <= -0.5 * Etat::dimBoite) sens[1] = +1;
            else if (position.z + taille >= 0.5 * Etat::dimBoite) sens[1] = -1;
            position.z += 60 * Etat::dt * vitesse.z * sens[1];

            // rotation du corps
            if (angleCorps > 360.0) angleCorps -= 360.0;
            angleCorps += 60 * Etat::dt * 0.35;

            // rotation des pales
            anglePale += 60 * Etat::dt * 8.0 * sens[4];

            // angle des pattes et des pales
            if (anglePatte <= 45.0) sens[3] = +1;
            else if (anglePatte >= 90.0) sens[3] = -1;
            anglePatte += 60 * Etat::dt * 1.0 * sens[3];

            // taille du corps
            if (taille <= 0.25) sens[5] = +1;
            else if (taille >= 1.0) sens[5] = -1;
            taille += 60 * Etat::dt * 0.005 * sens[5];

        }
    }

    // partie 2: utilisation de vbo et vao
    GLuint vao = 0;
    GLuint vboTheiereSommets = 0;
    GLuint vboTheiereConnec = 0;
    GLint locVertex = -1;
    GLint locColor = -1;

    glm::vec3 position;       // position courante de l'hélicoptère
    GLfloat taille;           // facteur d'échelle pour la taille globale du modèle
    GLfloat angleCorps;       // angle de rotation (en degrés) du corps de l'hélicoptère
    GLfloat anglePale;        // angle de rotation (en degrés) des pales
    GLfloat anglePatte;       // angle de rotation (en degrés) des pattes
    const GLfloat longMembre = 2.0;  // longueur des membres
    const GLfloat largMembre = 0.1;  // largeur des membres
};

#endif
