import 'package:flutter/material.dart';

class CartProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items => _items;

  void addItem(String title, String description, String price, String imageUrl, String selectedOption) {
    _items.add({
      'title': title,
      'description': description,
      'price': double.parse(price), // Преобразуем цену в число
      'imageUrl': imageUrl,
      'selectedOption': selectedOption,
      'quantity': 1,
    });
    notifyListeners();
  }

  void removeItem(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  void updateQuantity(int index, int newQuantity) {
    if (newQuantity > 0) {
      _items[index]['quantity'] = newQuantity;
    } else {
      _items.removeAt(index);
    }
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // Метод для подсчета общей стоимости
  double get totalPrice {
    return _items.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));
  }
}
