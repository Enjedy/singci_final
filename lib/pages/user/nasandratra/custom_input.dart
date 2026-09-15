import 'package:flutter/material.dart';

class CustomInput extends StatelessWidget {
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextEditingController? controller; // ✅ eto

  const CustomInput({
    super.key,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.controller, // ✅ eto
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller, // ✅ connect controller
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}