import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signci/pages/user/nasandratra/login_page.dart';
import '../../providers/theme_provider.dart';
import '../../services/firebase_service.dart';
import '../../services/supabase_service.dart';
import 'profil.dart';

class ParametrePage extends StatefulWidget {
  const ParametrePage({super.key});

  @override
  State<ParametrePage> createState() => _ParametrePageState();
}

class _ParametrePageState extends State<ParametrePage> {
  bool notifications = true;
  String langue = "Français";
  bool isSyncing = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Paramètres"),
        centerTitle: true,
      ),

      body: ListView(
        children: [
          /// 👤 Profil
          ListTile(
            leading: const Icon(Icons.person, color: Color(0xFF0275D8)),
            title: const Text("Profil"),
            subtitle: const Text("Voir et modifier votre profil"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilPage()),
              );
            },
          ),

          const Divider(),

          /// 🌙 Mode sombre
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode, color: Color(0xFF0275D8)),
            title: const Text("Mode sombre"),
            subtitle: const Text("Basculer l'interface en mode nuit"),
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider.toggleTheme(value);
            },
          ),

          /// 🔔 Notifications FCM
          SwitchListTile(
            secondary: const Icon(Icons.notifications, color: Color(0xFF0275D8)),
            title: const Text("Notifications"),
            subtitle: const Text("Recevoir des alertes sur le statut de vos signalements"),
            value: notifications,
            onChanged: (value) {
              setState(() {
                notifications = value;
              });
            },
          ),

          const Divider(),

          /// ☁️ Synchronisation Firebase
          ListTile(
            leading: const Icon(Icons.cloud_sync, color: Color(0xFF0275D8)),
            title: const Text("Synchronisation Cloud (Firebase)"),
            subtitle: const Text("Envoyer les données locales vers la base partagée"),
            trailing: isSyncing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.sync),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              setState(() => isSyncing = true);
              int count = await FirebaseService.syncPendingSignalements();
              setState(() => isSyncing = false);

              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(content: Text(count > 0 ? "$count signalement(s) synchronisé(s) vers Firebase cloud" : "Toutes les données sont déjà synchronisées")),
                );
              }
            },
          ),

          const Divider(),

          /// 🌍 Langue
          ListTile(
            leading: const Icon(Icons.language, color: Color(0xFF0275D8)),
            title: const Text("Langue"),
            subtitle: Text(langue),
            onTap: () {
              _choisirLangue();
            },
          ),

          const Divider(),

          /// 🗑️ Supprimer données
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text("Supprimer tous les signalements"),
            onTap: () {
              _confirmDelete();
            },
          ),

          const Divider(),

          /// ℹ️ À propos
          ListTile(
            leading: const Icon(Icons.info, color: Color(0xFF0275D8)),
            title: const Text("À propos de SignCi AI"),
            subtitle: const Text("Version 2.0 • Propulsé par l'IA"),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: "SignCi - Signalement Citoyen IA",
                applicationVersion: "2.0 Pro",
                children: const [
                  Text("SignCi est une application citoyenne professionnelle dotée d'une Intelligence Artificielle intégrée pour l'analyse, la catégorisation, la priorisation et la détection des doublons de signalements."),
                ],
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Déconnexion"),
            subtitle: const Text("Quitter la session actuelle"),
            onTap: () {
              confirmdeconect();
            },
          )
        ],
      ),
    );
  }

  /// 🔤 Choix langue
  void _choisirLangue() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Choisir la langue"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("Français"),
              onTap: () {
                setState(() => langue = "Français");
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text("Malagasy"),
              onTap: () {
                setState(() => langue = "Malagasy");
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text("English"),
              onTap: () {
                setState(() => langue = "English");
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 🗑️ Confirmation suppression
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Voulez-vous vraiment supprimer tous les signalements ?"),
        actions: [
          TextButton(
            child: const Text("Annuler"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
            onPressed: () async {
              try {
                await SupabaseService.deleteAll();
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Toutes les données ont été supprimées")),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("$e")),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void confirmdeconect() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Voulez-vous vous déconnecter ?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Non"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            child: const Text("Oui", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
