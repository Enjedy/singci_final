import 'package:flutter/material.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Signalement")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField(
              items: [
                DropdownMenuItem(value: "route", child: Text("Route")),
                DropdownMenuItem(value: "batîments", child: Text("batîments")),
              ],
              onChanged: (value) {},
              decoration: InputDecoration(
                labelText: "Catégorie",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 20),

            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Décrire le problème...",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {},
              child: Text("Envoyer"),
            )
          ],
        ),
      ),
    );
  }
}