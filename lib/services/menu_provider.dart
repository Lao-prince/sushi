import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/menu_model.dart';
import '../config.dart';
import 'http_client.dart';

class MenuProvider extends ChangeNotifier {
  List<Category> _categories = [];
  List<Product> _products = [];
  Map<String, List<Product>> _categorizedProducts = {};
  bool _isLoading = true;
  String? _selectedCategoryId;
  String? _errorMessage;
  final _httpClient = HttpClient();

  List<Category> get categories => _categories;
  List<Product> get products => _products;
  Map<String, List<Product>> get categorizedProducts => _categorizedProducts;
  bool get isLoading => _isLoading;
  String? get selectedCategoryId => _selectedCategoryId;
  bool get isLoadingCategories => _isLoading;
  String? get errorMessage => _errorMessage;

  MenuProvider() {
    // Инициализируем HttpClient с пустым AuthProvider для базовых запросов
    _httpClient.initialize(null);
    _fetchMenuData();
  }

  Future<void> _fetchMenuData() async {
      _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Загружаем категории и товары параллельно
      final categoriesResponse = await _httpClient.get(
        '${AppConfig.baseUrl}/api/menu/categories'
      );
      
      final productsResponse = await _httpClient.get(
        '${AppConfig.baseUrl}/api/menu/products'
      );

      if (categoriesResponse.statusCode == 200 && productsResponse.statusCode == 200) {
        // Парсим категории
        final List<dynamic> categoriesData = json.decode(utf8.decode(categoriesResponse.bodyBytes));
        final allCategories = categoriesData.map((item) => Category.fromJson(item)).toList();

        // Парсим товары
        final List<dynamic> productsData = json.decode(utf8.decode(productsResponse.bodyBytes));
        _products = productsData
            .map((item) => Product.fromJson(item))
            .where((product) => !product.disabled) // Фильтруем отключенные товары (disabled: true)
                .toList();

        // Группируем товары по категориям
        _categorizedProducts = {};
        for (var category in allCategories) {
          final categoryProducts = _products
              .where((product) => product.category.id == category.id)
                  .toList();
          
          // Добавляем категорию только если в ней есть доступные товары
          if (categoryProducts.isNotEmpty) {
            _categorizedProducts[category.id] = categoryProducts;
            }
          }

        // Формируем список категорий только с доступными товарами
        _categories = allCategories
            .where((category) => _categorizedProducts.containsKey(category.id))
            .toList();

        // Устанавливаем первую категорию по умолчанию
          if (_selectedCategoryId == null && _categories.isNotEmpty) {
            _selectedCategoryId = _categories[0].id;
        }
      } else {
        _errorMessage = 'Ошибка загрузки данных меню';
      }
    } catch (error) {
      _errorMessage = _getErrorMessage(error);
    }

    _isLoading = false;
    notifyListeners();
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('Connection timed out')) {
      return 'Превышено время ожидания подключения к серверу. Проверьте интернет-соединение.';
    } else if (error.toString().contains('SocketException')) {
      return 'Ошибка подключения к серверу. Проверьте интернет-соединение.';
    } else if (error.toString().contains('Нет подключения к интернету')) {
      return 'Нет подключения к интернету. Проверьте настройки сети.';
    } else {
      return 'Ошибка загрузки данных. Попробуйте позже.';
    }
  }

  Future<void> retry() async {
    _errorMessage = null;
    await _fetchMenuData();
  }

  Future<void> setSelectedCategory(String categoryId) async {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  Future<void> refreshMenu() async {
    _categories = [];
    _products = [];
    _categorizedProducts = {};
    await _fetchMenuData();
  }
}
