import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';

class AdresseField extends StatefulWidget {
  final TextEditingController controller;

  const AdresseField({super.key, required this.controller});

  @override
  State<AdresseField> createState() => _AdresseFieldState();
}

class _AdresseFieldState extends State<AdresseField> {
  List<String> suggestions = [];
  final List<String> _cache = [];

  /// CHECK INTERNET
  Future<bool> hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// API OpenStreetMap
  Future<List<String>> searchAPI(String query) async {
    try {
      final url = Uri.parse(
          "https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5");

      final httpClient = HttpClient();
      final request = await httpClient.getUrl(url);
      final response = await request.close();

      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final data = jsonDecode(body) as List;
        return data.map<String>((e) => e["display_name"].toString()).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  InputDecoration inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          decoration: inputStyle("Adresse"),
          onChanged: (value) async {
            if (value.isEmpty) {
              setState(() => suggestions.clear());
              return;
            }

            bool online = await hasInternet();

            if (online) {
              final result = await searchAPI(value);
              suggestions = result;
              for (var s in result) {
                if (!_cache.contains(s)) _cache.add(s);
              }
            } else {
              final q = value.toLowerCase();
              suggestions = _cache.where((s) => s.toLowerCase().contains(q)).toList();
            }

            setState(() {});
          },
        ),
        const SizedBox(height: 8),
        if (suggestions.isNotEmpty)
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey),
            ),
            child: ListView.builder(
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(suggestions[index]),
                  onTap: () {
                    widget.controller.text = suggestions[index];
                    suggestions.clear();
                    setState(() {});
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}