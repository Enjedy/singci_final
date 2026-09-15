import 'package:flutter/material.dart';
import 'package:signci/pages/user/carte.dart';
import '../user/signal1.dart';
import '../user/historique.dart';
import '../user/parametre.dart';
import '../user/messages/messages_page.dart';
import '../user/agent_conseil/conseil_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Bienvenue(),
    );
  }
}

class Bienvenue extends StatefulWidget {
  const Bienvenue({super.key});

  @override
  State<Bienvenue> createState() => _BienvenueState();
}

class _BienvenueState extends State<Bienvenue> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      buildAccueil(),
      const SignalementPage(),
      const CarteSignalementPage(),
      const HistoriquePage(),
      const ParametrePage(),
    ];

    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF0275D8),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Accueil"),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: "Signaler"),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Carte"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "Historique"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Paramètres"),
        ],
      ),
    );
  }

  // PAGE ACCUEIL
  Widget buildAccueil() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 30, left: 20, right: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF26164A), Color(0xFF701460), Color(0xFF154EA6)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "SignCi AI",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                  ],
                ),
                SizedBox(height: 5),
                Text(
                  "Votre voix intelligente pour améliorer la ville",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 🤖 BANNIÈRE IA INFOS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF0275D8).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFF0275D8).withValues(alpha: 0.35)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.psychology, color: Color(0xFF0275D8), size: 36),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Moteur d'Analyse IA Actif",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0275D8)),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Vérification automatique de la qualité d'image, cohérence avec la catégorie et calcul de gravité en temps réel.",
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () => setState(() => currentIndex = 1), // Signaler
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color ?? Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                ),
                child: const Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Color(0xFF0275D8),
                      child: Icon(Icons.add, color: Colors.white, size: 30),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Signaler un problème",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "La position GPS est récupérée automatiquement. L'IA vérifie la qualité et la cohérence de votre photo et description.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.3,
              children: [
                buildCard(Icons.map, "Carte & Zones Critiques", 2, color: const Color(0xFF0275D8)),
                buildCard(Icons.history, "Historique & Suivi", 3, color: const Color(0xFF701460)),
                buildCardPush(MessagesPage(), "Messages & Alertes", Icons.chat, color: Colors.orange),
                buildCardPush(const ConseilPage(), "Agent de conseil", Icons.smart_toy, color: const Color(0xFF154EA6)),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget buildCard(IconData icon, String title, int index, {required Color color}) {
    return GestureDetector(
      onTap: () => setState(() => currentIndex = index),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            )
          ],
        ),
      ),
    );
  }

  /// Carte qui ouvre une page via Navigator.push (pas un onglet de la barre du bas).
  Widget buildCardPush(Widget destination, String title, IconData icon,
      {required Color color}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => destination),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            )
          ],
        ),
      ),
    );
  }
}