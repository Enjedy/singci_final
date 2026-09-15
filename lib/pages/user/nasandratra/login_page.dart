import 'package:flutter/material.dart';
import '../../bienvenue/bienvenue.dart';
import 'registration_page.dart';
import 'custom_button.dart';
import 'custom_input.dart';

class AppColors {
  static const primary = Color(0xFF0275D8);
  static const turquoise = Color(0xFF00A896);
  static const royalBlue = Color(0xFF0275D8);
  static const gold = Color(0xFFFBB03B);
  static const vividOrange = Color(0xFFED1C24);
  static const background = Color(0xFFF6F3EC);
  static const text = Color(0xFF1E1E1E);
  static const grey = Color(0xFF9E9E9E);
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final pseudoController = TextEditingController();
  final passwordController = TextEditingController();
  bool showPassword = false;

  @override
  void dispose() {
    pseudoController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _loginUser() {
    String pseudoOrEmail = pseudoController.text.trim();
    String password = passwordController.text.trim();

    if (pseudoOrEmail.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir tous les champs")),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Bienvenue()),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "SIGNCI",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),
            const Text("Votre ville, votre voix."),
            const SizedBox(height: 30),
            CustomInput(
              hint: "Pseudo ou Email",
              icon: Icons.person,
              controller: pseudoController,
            ),
            const SizedBox(height: 15),
            CustomInput(
              hint: "Mot de passe",
              icon: Icons.lock,
              isPassword: true,
              controller: passwordController,
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: "Se connecter",
              onPressed: _loginUser,
            ),
            const SizedBox(height: 15),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegistrationPage()),
                );
              },
              child: const Text("Créer un compte"),
            ),
          ],
        ),
      ),
    );
  }
}