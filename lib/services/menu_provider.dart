import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/menu_model.dart';

class MenuProvider extends ChangeNotifier {
  List<Category> _categories = [];
  Map<String, List<Product>> _categorizedProducts = {};
  bool _isLoading = true;

  List<Category> get categories => _categories;
  Map<String, List<Product>> get categorizedProducts => _categorizedProducts;
  bool get isLoading => _isLoading;

  MenuProvider() {
    _fetchMenuData();
  }

  Future<void> _fetchMenuData() async {
    try {
      final response = await http.get(Uri.parse('http://89.223.122.180:9000/api/menu/'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));

        Map<String, List<Product>> tempCategorizedProducts = {};
        List<Category> tempCategories = [];

        for (var item in data) {
          final category = Category(
            id: item['category']['id'].toString(),
            name: item['category']['name'],
          );
          tempCategories.add(category);

          List<Product> products = (item['products'] as List<dynamic>).map((product) {
            return Product.fromJson(product);
          }).toList();

          tempCategorizedProducts[category.id] = products;
        }

        _categories = tempCategories;
        _categorizedProducts = tempCategorizedProducts;
        _isLoading = false;
        notifyListeners();
      } else {
        throw Exception('Ошибка загрузки данных');
      }
    } catch (error) {
      print('Ошибка: $error');
      _isLoading = false;
      notifyListeners();
    }
  }
}
