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
  int _page = 1;
  String? _selectedCategoryId;

  List<Category> get categories => _categories;
  Map<String, List<Product>> get categorizedProducts => _categorizedProducts;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreData => _hasMoreData;
  String? get selectedCategoryId => _selectedCategoryId;
  bool get isLoadingCategories => _isLoading;

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
      final response = await http.get(
        Uri.parse('http://89.223.122.180:10000/api/menu/?page=$_page')
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));

        if (data.isEmpty) {
          _hasMoreData = false;
        } else {
          // Если это первая загрузка, очищаем списки
          if (!isLoadMore) {
            _categories = [];
            _categorizedProducts = {};
          }

          for (var item in data) {
            final category = Category(
              id: item['category']['id'].toString(),
              name: item['category']['name'],
            );

            if (!_categories.any((c) => c.id == category.id)) {
              // Добавляем новые категории в начало списка
              _categories.insert(0, category);
            }

            List<Product> products = (item['products'] as List<dynamic>)
                .map((product) => Product.fromJson(product))
                .toList();

            if (!isLoadMore) {
              _categorizedProducts[category.id] = products;
            } else {
              _categorizedProducts[category.id] ??= [];
              _categorizedProducts[category.id]!.addAll(products);
            }
          }

          if (_selectedCategoryId == null && _categories.isNotEmpty) {
            _selectedCategoryId = _categories[0].id;
          }

          _page++;
        }
      }
    } catch (error) {
      print('Ошибка загрузки данных: $error');
    }

    _isLoading = false;
    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> setSelectedCategory(String categoryId) async {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  Future<void> loadMoreProducts() async {
    await _fetchMenuData(isLoadMore: true);
  }

  Future<void> refreshMenu() async {
    _categories = [];
    _categorizedProducts = {};
    _page = 1;
    _hasMoreData = true;
    await _fetchMenuData();
  }
}
