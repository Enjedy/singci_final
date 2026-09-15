import 'dart:convert';
import 'package:http/http.dart' as http;



Future<List<String>> searchAPI(String query) async {
  final url = Uri.parse(
      "https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5");

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = json.decode(response.body);

    return data.map<String>((e) => e["display_name"].toString()).toList();
  } else {
    return [];
  }
}
