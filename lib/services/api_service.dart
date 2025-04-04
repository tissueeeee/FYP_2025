import 'dart:convert';
import 'package:http/http.dart' as http;

class APIService {
  final String baseUrl = "https://example.com/api";

  Future<List<dynamic>> fetchProducts() async {
    final response = await http.get(Uri.parse("$baseUrl/products"));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load products');
    }
  }
}
