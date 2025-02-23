import 'package:flutter/material.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, Map<String, dynamic>> _items = {}; // Используем Map

  Map<String, Map<String, dynamic>> get items => _items;

  /// Метод добавления товара в корзину
  void addItem(String title, String description, String price, String imageUrl, String selectedOption) {
    String key = '$title-$selectedOption';

    if (_items.containsKey(key)) {
      // Если товар уже есть, увеличиваем количество
      _items[key]!['quantity'] += 1;
    } else {
      // Если товара нет, добавляем новый
      _items[key] = {
        'title': title,
        'description': description,
        'price': double.parse(price),
        'imageUrl': imageUrl,
        'selectedOption': selectedOption,
        'quantity': 1,
      };
    }
    notifyListeners();
  }

  /// Метод удаления товара
  void removeItem(String title, String selectedOption) {
    String key = '$title-$selectedOption';
    if (_items.containsKey(key)) {
      _items.remove(key);
      notifyListeners();
    }
  }

  /// Метод обновления количества товара
  void updateQuantity(String title, String selectedOption, int newQuantity) {
    String key = '$title-$selectedOption';
    if (_items.containsKey(key)) {
      if (newQuantity > 0) {
        _items[key]!['quantity'] = newQuantity;
      } else {
        _items.remove(key);
      }
      notifyListeners();
    }
  }

  /// Получение количества товара в корзине
  int getItemCount(String title, String selectedOption) {
    String key = '$title-$selectedOption';
    return _items.containsKey(key) ? _items[key]!['quantity'] as int : 0;
  }

  /// Очистка корзины
  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  /// Подсчет общей стоимости
  double get totalPrice {
    return _items.values.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));
  }
}
