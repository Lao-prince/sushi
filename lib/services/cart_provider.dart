import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/cart_model.dart';
import '../models/menu_model.dart';
import 'package:flutter/foundation.dart';

class CartProvider with ChangeNotifier {
  Cart? _cart;
  bool _isLoading = false;
  String? _sessionCookie;
  // Добавляем Map для хранения данных о товарах
  final Map<String, Map<String, String>> _itemsData = {};

  Cart? get cart => _cart;
  bool get isLoading => _isLoading;
  List<CartItem> get items => _cart?.items ?? [];
  double get totalPrice => _cart?.totalPrice ?? 0;

  // Получение корзины
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
            // Фильтруем товары с нулевым количеством
            data['Items'] = (data['Items'] as List)
                .where((item) => (item['amount'] as num) > 0)
                .toList();
            
            // Добавляем данные о товарах из _itemsData
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
      if (product.id.isEmpty || amount <= 0) {
        return;
      }

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (_sessionCookie != null) {
        headers['Cookie'] = _sessionCookie!;
      }

      // Для товаров без порций sizeId будет пустой строкой, превращаем его в null для сервера
      final effectiveSizeId = sizeId.isEmpty ? null : sizeId;

      // Находим соответствующий Price object.
      // Для товаров без порций ищем по пустой строке в ID размера.
      final priceInfo = product.prices.firstWhere(
        (p) => (sizeId.isEmpty && p.size.id.isEmpty) || p.size.id == sizeId,
        orElse: () => product.prices.first,
      );

      String sizeName = priceInfo.size.mapped_name ?? priceInfo.size.name;
      if (priceInfo.count > 1) {
        sizeName += ' (${priceInfo.count} шт.)';
      }

      final itemKey = product.id + (effectiveSizeId ?? '');
      _itemsData[itemKey] = {
        'productName': product.name,
        'productImage': product.imageLinks.isNotEmpty ? product.imageLinks.first : '',
        'sizeName': sizeName,
      };

      final Map<String, dynamic> requestBody = {
        'productId': product.id,
        'productSizeId': effectiveSizeId,
        'amount': amount,
        'price': priceInfo.price,
        'comment': '',
        'productName': product.name,
        'productImage': product.imageLinks.isNotEmpty ? product.imageLinks.first : '',
        'sizeName': sizeName,
      };

      print('Отправляем запрос на добавление в корзину:');
      print('requestBody: $requestBody');

      final response = await http.post(
        Uri.parse('http://89.223.122.180:10000/api/cart/add'),
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.headers['set-cookie'] != null) {
        _sessionCookie = response.headers['set-cookie']!.split(';')[0];
      }

      print('Статус ответа: ${response.statusCode}');
      print('Тело ответа: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Получен ответ от сервера: $data');
        
        if (data['Items'] != null) {
          // Фильтруем товары с нулевым количеством
          data['Items'] = (data['Items'] as List)
              .where((item) => (item['amount'] as num) > 0)
              .toList();
          
          // Восстанавливаем данные о товарах
          for (var item in data['Items']) {
            final itemKey = item['productId'] + (item['productSizeId'] ?? '');
            if (_itemsData.containsKey(itemKey)) {
              item['productName'] = _itemsData[itemKey]!['productName'];
              item['productImage'] = _itemsData[itemKey]!['productImage'];
              item['sizeName'] = _itemsData[itemKey]!['sizeName'];
            }
          }
          _cart = Cart.fromJson(data);
          notifyListeners();
        }
      } else {
        print('Ошибка при добавлении в корзину. Статус: ${response.statusCode}');
        print('Тело ответа: ${response.body}');
        throw Exception('Ошибка при добавлении в корзину: ${response.body}');
      }
    } catch (e) {
      print('Ошибка при добавлении в корзину: $e');
      rethrow;
    }
  }

  // Обновление количества товара в корзине
  Future<void> updateQuantity(String productId, String? sizeId, int quantity) async {
    try {
      if (quantity < 0) {
        throw Exception('Количество не может быть отрицательным');
      }

      if (_cart == null) {
        throw Exception('Корзина не инициализирована');
      }

      // Для товаров без порций используем null как productSizeId
      final effectiveSizeId = sizeId?.isEmpty == true ? null : sizeId;

      // Находим товар в корзине
      final currentItem = _cart!.items.firstWhere(
        (item) => item.productId == productId && 
                  ((effectiveSizeId == null && item.productSizeId == null) || 
                   (effectiveSizeId != null && item.productSizeId == effectiveSizeId)),
        orElse: () {
          print('Товар не найден в корзине:');
          print('productId: $productId');
          print('sizeId: $effectiveSizeId');
          print('Текущие товары в корзине:');
          for (var item in _cart!.items) {
            print('${item.productId} - ${item.productSizeId}');
          }
          throw Exception('Товар не найден в корзине');
        },
      );

      // Сохраняем данные о товаре перед обновлением
      final itemKey = productId + (effectiveSizeId ?? '');
      if (!_itemsData.containsKey(itemKey)) {
        _itemsData[itemKey] = {
          'productName': currentItem.productName,
          'productImage': currentItem.productImage,
          'sizeName': currentItem.sizeName,
        };
      }

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (_sessionCookie != null) {
        headers['Cookie'] = _sessionCookie!;
      }

      // Определяем, увеличиваем или уменьшаем количество
      final isIncreasing = quantity > currentItem.amount;
      final amountChange = isIncreasing ? 1 : -1;

      final Map<String, dynamic> requestBody = {
        'productId': productId,
        'productSizeId': effectiveSizeId,
        'amount': amountChange,
        'comment': '',
        'productName': currentItem.productName,
        'productImage': currentItem.productImage,
        'sizeName': currentItem.sizeName,
      };

      final response = await http.post(
        Uri.parse('http://89.223.122.180:10000/api/cart/add'),
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.headers['set-cookie'] != null) {
        _sessionCookie = response.headers['set-cookie']!.split(';')[0];
      }

      print('Статус ответа: ${response.statusCode}');
      print('Тело ответа: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Получен ответ от сервера: $data');
        
        if (data['Items'] != null) {
          // Фильтруем товары с нулевым количеством
          data['Items'] = (data['Items'] as List)
              .where((item) => (item['amount'] as num) > 0)
              .toList();
          
          // Восстанавливаем данные о товарах
          for (var item in data['Items']) {
            final itemKey = item['productId'] + (item['productSizeId'] ?? '');
            if (_itemsData.containsKey(itemKey)) {
              item['productName'] = _itemsData[itemKey]!['productName'];
              item['productImage'] = _itemsData[itemKey]!['productImage'];
              item['sizeName'] = _itemsData[itemKey]!['sizeName'];
            }
          }
          _cart = Cart.fromJson(data);
          notifyListeners();
        }
      } else if (response.statusCode == 422) {
        final data = json.decode(response.body);
        print('Ошибка валидации: $data');
        throw Exception('Ошибка валидации: ${data['message']}');
      } else {
        print('Неизвестная ошибка. Статус: ${response.statusCode}');
        print('Тело ответа: ${response.body}');
        throw Exception('Неизвестная ошибка: ${response.body}');
      }
    } catch (e) {
      print('Ошибка при обновлении количества: $e');
      rethrow;
    }
  }

  // Удаление товара из корзины
  Future<void> removeFromCart(String productId, String? sizeId) async {
    try {
      if (_cart == null || _cart!.items.isEmpty) {
        print('Корзина пуста');
        return;
      }

      // Для товаров без порций используем null как productSizeId
      final effectiveSizeId = sizeId?.isEmpty == true ? null : sizeId;

      // Находим товар в корзине
      final currentItem = _cart!.items.firstWhere(
        (item) => item.productId == productId && 
                  ((effectiveSizeId == null && item.productSizeId == null) || 
                   (effectiveSizeId != null && item.productSizeId == effectiveSizeId)),
      );

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (_sessionCookie != null) {
        headers['Cookie'] = _sessionCookie!;
      }

      // Отправляем запрос на удаление с отрицательным количеством
      final Map<String, dynamic> requestBody = {
        'productId': productId,
        'productSizeId': effectiveSizeId,
        'amount': -currentItem.amount, // Отрицательное количество для удаления
        'comment': '',
        'productName': currentItem.productName,
        'productImage': currentItem.productImage,
        'sizeName': currentItem.sizeName,
      };

      print('Отправляем запрос на удаление из корзины:');
      print('requestBody: $requestBody');

      final response = await http.post(
        Uri.parse('http://89.223.122.180:10000/api/cart/add'),
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.headers['set-cookie'] != null) {
        _sessionCookie = response.headers['set-cookie']!.split(';')[0];
      }

      print('Статус ответа: ${response.statusCode}');
      print('Тело ответа: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Получен ответ от сервера: $data');
        
        if (data['Items'] != null) {
          // Фильтруем товары с нулевым количеством
          data['Items'] = (data['Items'] as List)
              .where((item) => (item['amount'] as num) > 0)
              .toList();
          
          // Восстанавливаем данные о товарах
          for (var item in data['Items']) {
            final itemKey = item['productId'] + (item['productSizeId'] ?? '');
            if (_itemsData.containsKey(itemKey)) {
              item['productName'] = _itemsData[itemKey]!['productName'];
              item['productImage'] = _itemsData[itemKey]!['productImage'];
              item['sizeName'] = _itemsData[itemKey]!['sizeName'];
            }
          }
          _cart = Cart.fromJson(data);
          notifyListeners();
        }
      } else if (response.statusCode == 422) {
        final data = json.decode(response.body);
        print('Ошибка валидации: $data');
        throw Exception('Ошибка валидации: ${data['message']}');
      } else {
        print('Неизвестная ошибка. Статус: ${response.statusCode}');
        print('Тело ответа: ${response.body}');
        throw Exception('Неизвестная ошибка: ${response.body}');
      }
    } catch (e) {
      print('Ошибка при удалении из корзины: $e');
      rethrow;
    }
  }

  // Получение количества товара в корзине
  int getItemCount(String productId, String sizeId) {
    if (_cart == null) return 0;
    
    final effectiveSizeId = sizeId.isEmpty ? null : sizeId;
    
    final count = _cart!.items
        .where((item) => 
            item.productId == productId && 
            (item.productSizeId == effectiveSizeId))
        .fold(0, (sum, item) => sum + item.amount);
    
    print('Найдено количество: $count');
    return count;
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
