import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/menu_model.dart';

class MenuProvider extends ChangeNotifier {
  List<Category> _categories = [];
  Map<String, List<Product>> _categorizedProducts = {};
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _page = 1; // Начальная страница

  List<Category> get categories => _categories;
  Map<String, List<Product>> get categorizedProducts => _categorizedProducts;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreData => _hasMoreData;

  MenuProvider() {
    _fetchMenuData();
  }

  Future<void> _fetchMenuData({bool isLoadMore = false}) async {
    if (isLoadMore && (!_hasMoreData || _isLoadingMore)) return;

    if (!isLoadMore) {
      _isLoading = true;
    } else {
      _isLoadingMore = true;
    }
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('http://89.223.122.180:9000/api/menu/?page=$_page'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));

        if (data.isEmpty) {
          _hasMoreData = false;
        } else {
          for (var item in data) {
            final category = Category(
              id: item['category']['id'].toString(),
              name: item['category']['name'],
            );

            if (!_categories.any((c) => c.id == category.id)) {
              _categories.add(category);
            }

            List<Product> products = (item['products'] as List<dynamic>).map((product) {
              return Product.fromJson(product);
            }).toList();

            _categorizedProducts[category.id] ??= [];
            _categorizedProducts[category.id]!.addAll(products);
          }

          _page++;
        }
      } else {
        throw Exception('Ошибка загрузки данных');
      }
    } catch (error) {
      print('Ошибка: $error');
    }

    _isLoading = false;
    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> loadMoreProducts() async {
    await _fetchMenuData(isLoadMore: true);
  }
}
