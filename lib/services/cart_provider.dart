import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/cart_model.dart';
import '../models/menu_model.dart';

class CartProvider extends ChangeNotifier {
  Cart? _cart;
  bool _isLoading = false;
  String? _sessionCookie;
  // Добавляем Map для хранения данных о товарах
  final Map<String, Map<String, String>> _itemsData = {};

  Cart? get cart => _cart;
  bool get isLoading => _isLoading;
  List<CartItem> get items => _cart?.items ?? [];
  double get totalPrice => _cart?.totalPrice ?? 0;

  // Получение корзины с сервера
  Future<void> fetchCart() async {
    _isLoading = true;
    notifyListeners();

    try {
      final headers = {
        'Accept': 'application/json',
      };
      
      if (_sessionCookie != null) {
        headers['Cookie'] = _sessionCookie!;
      }

      final response = await http.get(
        Uri.parse('http://89.223.122.180:10000/api/cart/get'),
        headers: headers,
      );

      if (response.headers['set-cookie'] != null) {
        _sessionCookie = response.headers['set-cookie']!.split(';')[0];
      }

      if (response.statusCode == 200) {
        String? cartData = response.body.isNotEmpty ? response.body : null;

        if (cartData == null && _sessionCookie != null) {
          try {
            final sessionValue = _sessionCookie!.split('=')[1].split('.')[0];
            final decodedBytes = base64.decode(sessionValue);
            final decodedJson = utf8.decode(decodedBytes);
            final sessionData = json.decode(decodedJson);
            if (sessionData['cart'] != null) {
              cartData = sessionData['cart'];
            }
          } catch (e) {
            print('Ошибка декодирования cookie: $e');
          }
        }

        if (cartData != null) {
          final data = json.decode(cartData);
          if (data['Items'] != null) {
            for (var item in data['Items']) {
              final itemKey = item['productId'] + item['productSizeId'];
              if (_itemsData.containsKey(itemKey)) {
                item['productName'] = _itemsData[itemKey]!['productName'];
                item['productImage'] = _itemsData[itemKey]!['productImage'];
                item['sizeName'] = _itemsData[itemKey]!['sizeName'];
              }
            }
          }
          _cart = Cart.fromJson(data);
        } else {
          _cart = Cart(items: [], totalPrice: 0);
        }
      }
    } catch (e) {
      print('Ошибка при загрузке корзины: $e');
      _cart = Cart(items: [], totalPrice: 0);
    }

    _isLoading = false;
    notifyListeners();
  }

  // Добавление товара в корзину
  Future<void> addToCart(Product product, String sizeId, int amount) async {
    try {
      if (product.id.isEmpty || sizeId.isEmpty || amount <= 0) {
        print('Некорректные данные для добавления в корзину:');
        print('productId: ${product.id}');
        print('sizeId: $sizeId');
        print('amount: $amount');
        return;
      }

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (_sessionCookie != null) {
        headers['Cookie'] = _sessionCookie!;
      }

      final size = product.prices.firstWhere(
        (price) => price.size.id == sizeId,
        orElse: () => product.prices.first,
      );

      // Сохраняем данные о товаре сразу при добавлении
      final productImage = product.imageLinks.isNotEmpty ? product.imageLinks[0] : '';
      _itemsData[product.id + sizeId] = {
        'productName': product.name,
        'productImage': productImage,
        'sizeName': size.size.name,
      };

      final Map<String, dynamic> requestBody = {
        'productId': product.id,
        'productSizeId': sizeId,
        'amount': amount,
        'comment': '',
        'productName': product.name,
        'productImage': productImage,
        'sizeName': size.size.name,
      };

      final response = await http.post(
        Uri.parse('http://89.223.122.180:10000/api/cart/add'),
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.headers['set-cookie'] != null) {
        _sessionCookie = response.headers['set-cookie']!.split(';')[0];
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['Items'] != null) {
          // Обновляем данные для всех товаров в корзине
          for (var item in data['Items']) {
            final itemKey = item['productId'] + item['productSizeId'];
            if (_itemsData.containsKey(itemKey)) {
              item['productName'] = _itemsData[itemKey]!['productName'];
              item['productImage'] = _itemsData[itemKey]!['productImage'];
              item['sizeName'] = _itemsData[itemKey]!['sizeName'];
            }
          }
          _cart = Cart.fromJson(data);
          notifyListeners();
        }
      }
    } catch (e) {
      print('Ошибка при добавлении товара: $e');
    }
  }

  // Получение количества товара в корзине
  int getItemCount(String productId, String sizeId) {
    if (_cart == null) return 0;
    
    return _cart!.items
        .where((item) => 
            item.productId == productId && 
            item.productSizeId == sizeId)
        .fold(0, (sum, item) => sum + item.amount);
  }

  // Обновление количества товара
  Future<void> updateQuantity(String uuid, int newAmount) async {
    try {
      if (newAmount <= 0) {
        await removeItem(uuid);
        return;
      }

      // Находим текущий товар в корзине
      final currentItem = _cart?.items.firstWhere((item) => item.uuid == uuid);
      if (currentItem == null) return;

      print('Обновляем количество товара:');
      print('UUID: $uuid');
      print('Текущее количество: ${currentItem.amount}');
      print('Новое количество: $newAmount');

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (_sessionCookie != null) {
        headers['Cookie'] = _sessionCookie!;
      }

      // Определяем, увеличиваем или уменьшаем количество
      final isIncreasing = newAmount > currentItem.amount;

      final Map<String, dynamic> requestBody = {
        'productId': currentItem.productId,
        'productSizeId': currentItem.productSizeId,
        'amount': isIncreasing ? 1 : -1,
        'comment': currentItem.comment ?? '',
        'productName': currentItem.productName ?? '',
        'productImage': currentItem.productImage ?? '',
        'sizeName': currentItem.sizeName ?? '',
      };

      // Сохраняем данные о товаре перед обновлением
      _itemsData[uuid] = {
        'productName': currentItem.productName ?? '',
        'productImage': currentItem.productImage ?? '',
        'sizeName': currentItem.sizeName ?? '',
      };

      final response = await http.post(
        Uri.parse('http://89.223.122.180:10000/api/cart/add'),
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.headers['set-cookie'] != null) {
        _sessionCookie = response.headers['set-cookie']!.split(';')[0];
      }

      print('Код ответа: ${response.statusCode}');
      print('Тело ответа: ${response.body}');

      if (response.statusCode == 200) {
        await fetchCart();
      } else {
        print('Ошибка обновления количества: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при обновлении количества: $e');
    }
  }

  // Удаление товара из корзины
  Future<void> removeItem(String uuid) async {
    try {
      // Находим текущий товар в корзине
      final currentItem = _cart?.items.firstWhere((item) => item.uuid == uuid);
      if (currentItem == null) return;

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (_sessionCookie != null) {
        headers['Cookie'] = _sessionCookie!;
      }

      // Отправляем запрос на добавление с отрицательным количеством
      final Map<String, dynamic> requestBody = {
        'productId': currentItem.productId,
        'productSizeId': currentItem.productSizeId,
        'amount': -currentItem.amount, // Отрицательное количество для удаления
        'comment': currentItem.comment ?? '',
        'productName': currentItem.productName ?? '',
        'productImage': currentItem.productImage ?? '',
        'sizeName': currentItem.sizeName ?? '',
      };

      final response = await http.post(
        Uri.parse('http://89.223.122.180:10000/api/cart/add'),
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.headers['set-cookie'] != null) {
        _sessionCookie = response.headers['set-cookie']!.split(';')[0];
      }

      print('Код ответа при удалении: ${response.statusCode}');
      print('Тело ответа при удалении: ${response.body}');

      if (response.statusCode == 200) {
        // Удаляем данные о товаре
        _itemsData.remove(uuid);
        // Обновляем локальное состояние корзины, удаляя товар
        if (_cart != null) {
          _cart = Cart(
            items: _cart!.items.where((item) => item.uuid != uuid).toList(),
            totalPrice: _cart!.totalPrice - (currentItem.price * currentItem.amount),
          );
          notifyListeners();
        }
      } else {
        print('Ошибка удаления товара: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при удалении товара: $e');
    }
  }

  // Очистка корзины
  Future<void> clearCart() async {
    try {
      final response = await http.delete(
        Uri.parse('http://89.223.122.180:10000/api/cart/clear'),
      );

      if (response.statusCode == 200) {
        _cart = Cart(items: [], totalPrice: 0);
        notifyListeners();
      } else {
        print('Ошибка очистки корзины: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при очистке корзины: $e');
    }
  }
}
