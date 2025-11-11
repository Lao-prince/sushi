import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/cart_model.dart';
import '../models/menu_model.dart';
import '../config.dart';
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
  String? get sessionCookie => _sessionCookie;

  // Получение корзины
  Future<void> fetchCart() async {
    _isLoading = true;
    notifyListeners();

    try {
      print('[DEBUG] _fetchCart: Загружаем корзину с сервера...');
      final headers = {
        'Accept': 'application/json',
      };
      
      if (_sessionCookie != null) {
        headers['Cookie'] = _sessionCookie!;
        final cookiePreview = _sessionCookie!.length > 50 ? '${_sessionCookie!.substring(0, 50)}...' : _sessionCookie!;
        print('[DEBUG] _fetchCart: Используем cookie: $cookiePreview');
      } else {
        print('[DEBUG] _fetchCart: Cookie отсутствует');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/cart/get'),
        headers: headers,
      );

      print('[DEBUG] _fetchCart: Ответ сервера: statusCode=${response.statusCode}');

      if (response.headers['set-cookie'] != null) {
        _sessionCookie = response.headers['set-cookie']!.split(';')[0];
        print('[DEBUG] _fetchCart: Получен новый cookie');
      }

      if (response.statusCode == 200) {
        final bodyPreview = response.body.length > 200 ? '${response.body.substring(0, 200)}...' : response.body;
        print('[DEBUG] _fetchCart: Тело ответа: $bodyPreview');
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
            // Игнорируем ошибку
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
          print('[DEBUG] _fetchCart: Загружена корзина: ${_cart?.items.length ?? 0} товаров, сумма: ${_cart?.totalPrice ?? 0}');
        } else {
          _cart = Cart(items: [], totalPrice: 0);
          print('[DEBUG] _fetchCart: Корзина пуста (cartData == null)');
        }
      }
    } catch (e) {
      print('[DEBUG] _fetchCart: Ошибка при загрузке корзины: $e');
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

      // Отправляем только те поля, которые ожидает API
      final Map<String, dynamic> requestBody = {
        'productId': product.id,
        'productSizeId': effectiveSizeId,
        'amount': amount,
        'comment': '',
      };

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/cart/add'),
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.headers['set-cookie'] != null) {
        _sessionCookie = response.headers['set-cookie']!.split(';')[0];
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
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
        throw Exception('Ошибка при добавлении в корзину: ${response.body}');
      }
    } catch (e) {
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

      // Если новое количество будет 0, удаляем товар полностью
      if (quantity == 0) {
        print('[DEBUG] updateQuantity: Количество стало 0, удаляем товар ${productId}');
        await removeFromCart(productId, sizeId);
        return;
      }
      
      // Определяем, увеличиваем или уменьшаем количество
      final isIncreasing = quantity > currentItem.amount;
      final amountChange = isIncreasing ? 1 : -1;

      print('[DEBUG] updateQuantity: ${isIncreasing ? "Увеличиваем" : "Уменьшаем"} количество товара ${productId} на $amountChange (текущее: ${currentItem.amount}, новое: $quantity)');

      // Отправляем только те поля, которые ожидает API
      final Map<String, dynamic> requestBody = {
        'productId': productId,
        'productSizeId': effectiveSizeId,
        'amount': amountChange,
        'comment': '',
      };

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/cart/add'),
        headers: headers,
        body: json.encode(requestBody),
      );
      
      print('[DEBUG] updateQuantity: Ответ сервера: statusCode=${response.statusCode}');

      if (response.headers['set-cookie'] != null) {
        _sessionCookie = response.headers['set-cookie']!.split(';')[0];
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
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
        throw Exception('Ошибка валидации: ${data['message']}');
      } else {
        throw Exception('Неизвестная ошибка: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Удаление товара из корзины
  Future<void> removeFromCart(String productId, String? sizeId) async {
    try {
      if (_cart == null || _cart!.items.isEmpty) {
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

      // Используем DELETE /api/cart/{productId}/clear для полного удаления товара
      print('[DEBUG] removeFromCart: Удаляем товар productId=${productId} через DELETE /api/cart/{id}/clear');
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/api/cart/${productId}/clear'),
        headers: headers,
      );

      print('[DEBUG] removeFromCart: Ответ сервера: statusCode=${response.statusCode}');
      print('[DEBUG] removeFromCart: Тело ответа: ${response.body}');

      if (response.headers['set-cookie'] != null) {
        _sessionCookie = response.headers['set-cookie']!.split(';')[0];
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('[DEBUG] removeFromCart: Товары в корзине после удаления: ${data['Items']}');
        
        if (data['Items'] != null) {
          final originalCount = (data['Items'] as List).length;
          // Фильтруем товары с нулевым количеством
          data['Items'] = (data['Items'] as List)
              .where((item) => (item['amount'] as num) > 0)
              .toList();
          final filteredCount = (data['Items'] as List).length;
          
          print('[DEBUG] removeFromCart: Отфильтровано товаров: было $originalCount, осталось $filteredCount');
          
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
        throw Exception('Ошибка валидации: ${data['message']}');
      } else {
        throw Exception('Неизвестная ошибка: ${response.body}');
      }
    } catch (e) {
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
    
    return count;
  }

  // Очистка корзины
  Future<void> clearCart() async {
    try {
      final headers = <String, String>{
        'Accept': 'application/json',
      };
      
      if (_sessionCookie != null) {
        headers['Cookie'] = _sessionCookie!;
      }
      
      // Сначала пробуем стандартный эндпоинт
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/api/cart/clear'),
        headers: headers,
      );

      print('[DEBUG] clearCart: DELETE /api/cart/clear statusCode=${response.statusCode}, body=${response.body}');

      // Альтернативный подход: если корзина не пуста, удаляем товары через DELETE /api/cart/{id}/clear
      if (_cart != null && _cart!.items.isNotEmpty) {
        print('[DEBUG] clearCart: Удаляем ${_cart!.items.length} товаров через DELETE /api/cart/{id}/clear...');
        final itemsToRemove = List.from(_cart!.items); // Создаем копию списка
        
        for (var item in itemsToRemove) {
          try {
            print('[DEBUG] clearCart: Удаляем товар с productId=${item.productId}');
            
            final deleteResponse = await http.delete(
              Uri.parse('${AppConfig.baseUrl}/api/cart/${item.productId}/clear'),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                if (_sessionCookie != null) 'Cookie': _sessionCookie!,
              },
            );
            print('[DEBUG] clearCart: Товар ${item.productId} удален через /clear, statusCode=${deleteResponse.statusCode}, body=${deleteResponse.body}');
          } catch (e) {
            print('[DEBUG] clearCart: Ошибка при удалении товара ${item.productId}: $e');
          }
        }
      }

      // Сбрасываем сессию (cookie), чтобы создать новую чистую корзину
      print('[DEBUG] clearCart: Сбрасываем cookie для создания новой сессии');
      _sessionCookie = null;
      
      // Очищаем локальную корзину
      _cart = Cart(items: [], totalPrice: 0);
      notifyListeners();
      print('[DEBUG] clearCart: Локальная корзина очищена, сессия сброшена');
    } catch (e) {
      print('[DEBUG] clearCart: Ошибка: $e');
      // При ошибке сети всё равно очищаем локальную корзину
      _cart = Cart(items: [], totalPrice: 0);
      notifyListeners();
    }
  }
}
