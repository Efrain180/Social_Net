import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:the_wall/components/my_drawer.dart'; // Importa el Drawer personalizado
import 'package:the_wall/pages/home_page.dart'; // Importa la página de inicio
import 'package:the_wall/pages/wall_post.dart'; // Importa la clase WallPost
import 'package:the_wall/components/my_text_box.dart';
import 'package:the_wall/helper/helper_methods.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key});

  void goToHomePage(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(), // Reemplaza HomePage() con el nombre de tu página de inicio
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;
    final usersCollection = FirebaseFirestore.instance.collection('Users');

    Future<void> editField(String field) async {
      String newValue = '';
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Usa el color de fondo del tema oscuro
          title: Text(
            'Editar $field',
            style: const TextStyle(color: Colors.white),
          ),
          content: TextField(
            autofocus: true,
            style: const TextStyle(
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: 'Introducir nuevo $field',
              hintStyle: const TextStyle(color: Colors.grey),
            ),
            onChanged: (value) {
              newValue = value;
            },
          ),
          actions: [
            //cancel button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
            ),

            //save button
            TextButton(
              onPressed: () async {
                if (newValue.trim().length > 0) {
                  // Solo actualiza si hay algo en el campo de texto
                  await usersCollection
                      .doc(currentUser.email)
                      .update({field: newValue});
                }
                Navigator.of(context).pop();
              },
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text('Pagina de Perfil'),
        backgroundColor: Colors.grey[900],
        actions: [
          // Botón de flecha en la barra de navegación
          IconButton(
            onPressed: () => goToHomePage(context), // Navegar a la página de inicio
            icon: Icon(Icons.arrow_back),
          ),
        ],
      ),
      drawer: MyDrawer(
        onProfileTap: () {}, // Función para abrir el perfil
        onSignOut: () {}, // Función para cerrar sesión
      ),
      body: Theme(
        // Envuelve el contenido con Theme y establece el modo oscuro
        data: ThemeData.dark(),
        child: Column(
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Users')
                  .doc(currentUser.email)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final userData = snapshot.data!.data() as Map<String, dynamic>;
                  return Column(
                    children: [
                      //profile pic
                      const Icon(
                        Icons.person,
                        size: 72,
                      ),

                      //user email
                      Text(
                        currentUser.email!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 50),

                      //user details
                      Padding(
                        padding: const EdgeInsets.only(left: 25.0),
                        child: Text(
                          'Mi Informacion',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),

                      //username
                      MyTextBox(
                        text: userData['username'],
                        sectionName: 'Nombre de Usuario',
                        onPressed: () => editField('username'),
                      ),

                      //bio
                      MyTextBox(
                        text: userData['bio'],
                        sectionName: 'Sobre Mi',
                        onPressed: () => editField('bio'),
                      ),
                      const SizedBox(height: 30.0),

                      //user posts
                      Padding(
                        padding: const EdgeInsets.only(left: 25.0),
                        child: Text(
                          'Mis Publicaciones',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error${snapshot.error}'),
                  );
                }
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('User Posts')
                  .where('UserEmail', isEqualTo: currentUser.email)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final userPosts = snapshot.data!.docs;
                  return Expanded(
                    child: ListView.builder(
                      itemCount: userPosts.length,
                      itemBuilder: (context, index) {
                        final post = userPosts[index].data() as Map<String, dynamic>;
                        return WallPost(
                          message: post['Message'],
                          user: post['UserEmail'],
                          imageURL: post['ImageURL'],
                          postId: userPosts[index].id,
                          likes: List<String>.from(post['Likes'] ?? []),
                          time: formatDate(post['TimeStamp']),
                        );
                      },
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
