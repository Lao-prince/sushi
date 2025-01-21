import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/menu_model.dart';

class MenuService {
  static const String baseUrl = 'http://89.223.122.180:9000/api/menu/';

  Future<List<Menu>> fetchMenu() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final List<dynamic> menuJson = jsonDecode(response.body);
      return menuJson.map((json) => Menu.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load menu');
    }
  }
}