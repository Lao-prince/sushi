import 'package:flutter/material.dart';

class CartProvider with ChangeNotifier {
  final List<Map<String, dynamic>> _cartItems = [];

  List<Map<String, dynamic>> get cartItems => _cartItems;

  void addItem(String title, String description, String price, String imageUrl, String option, int quantity) {
    _cartItems.add({
      'title': title,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'option': option,
      'quantity': quantity,
    });
    notifyListeners();
  }
}