import 'package:flutter/material.dart';

class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  Future<Map<String, dynamic>> loadUser() async {
    return {
      'pseudo': 'Citoyen SignCi',
      'email': 'Mode public sans compte',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: loadUser(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Aucun utilisateur connecté"));
          }

          var user = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              children: [

                // 🔵 COVER + PROFILE IMAGE
                Stack(
                  alignment: Alignment.center,
                  children: [

                    // Cover (toy ny Facebook)
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF26164A), Color(0xFF701460), Color(0xFF154EA6)],
                        ),
                      ),
                    ),

                    Positioned(
                      bottom: -50,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: AssetImage("assets/image/avatar.png"), // soloy raha misy
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 60),

                // 👤 NOM
                Text(
                  user['pseudo'],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                // 📧 EMAIL
                Text(
                  user['email'],
                  style: const TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 20),

                // 📦 CARD INFOS
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        children: [

                          ListTile(
                            leading: const Icon(Icons.person),
                            title: const Text("Pseudo"),
                            subtitle: Text(user['pseudo']),
                          ),

                          const Divider(),

                          ListTile(
                            leading: const Icon(Icons.email),
                            title: const Text("Email"),
                            subtitle: Text(user['email']),
                          ),

                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 🔘 BOUTON (edit ohatra)
                ElevatedButton(
                  onPressed: () {},
                  child: const Text("Modifier le profil"),
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}