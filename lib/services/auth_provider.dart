import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/auth_model.dart';
import '../config.dart';
import 'http_client.dart';

class AuthProvider with ChangeNotifier {
  static const String _baseUrl = AppConfig.baseUrl;
  final _httpClient = HttpClient();
  
  AuthProvider() {
    _httpClient.initialize(this);
    _loadFromPrefs();
  }
  
  String? _accessToken;
  String? _refreshToken;
  String? _phoneNumber;
  String? _name;
  String? _userId;
  bool _isAuthenticated = false;
  Set<String> _favoriteProductIds = {};

  bool get isAuthenticated => _isAuthenticated;
  String? get phoneNumber => _phoneNumber;
  String? get name => _name;
  String? get accessToken => _accessToken;
  String? get userId => _userId;
  Set<String> get favoriteProductIds => _favoriteProductIds;

  // Утилитная функция для форматирования номера телефона в серверный формат 7-XXX-XXX-XX-XX
  String _formatPhoneForServer(String phone) {
    String formattedPhone = phone.replaceAll(RegExp(r'[^\d]'), ''); // Удаляем все символы кроме цифр
    
    // Если номер начинается с 8, заменяем на 7
    if (formattedPhone.startsWith('8')) {
      formattedPhone = '7${formattedPhone.substring(1)}';
    }
    
    // Если номер правильной длины (11 цифр, начинается с 7)
    if (formattedPhone.startsWith('7') && formattedPhone.length == 11) {
      // Форматируем в нужный серверный формат 7-XXX-XXX-XX-XX
      return '${formattedPhone.substring(0, 1)}-${formattedPhone.substring(1, 4)}-${formattedPhone.substring(4, 7)}-${formattedPhone.substring(7, 9)}-${formattedPhone.substring(9, 11)}';
    } else if (formattedPhone.length == 10) {
      // Если номер без 7/8 в начале, добавляем 7 и форматируем
      return '7-${formattedPhone.substring(0, 3)}-${formattedPhone.substring(3, 6)}-${formattedPhone.substring(6, 8)}-${formattedPhone.substring(8, 10)}';
    }
    
    return formattedPhone; // Возвращаем как есть, если не удалось отформатировать
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
    _phoneNumber = prefs.getString('phone_number');
    _name = prefs.getString('name');
    _userId = prefs.getString('user_id');
    _isAuthenticated = _accessToken != null;
    
    // Загружаем избранные товары если пользователь авторизован
    if (_isAuthenticated && _userId != null) {
      await loadFavoriteProducts();
    }
    
    // Уведомляем слушателей после загрузки всех данных
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (_accessToken != null) await prefs.setString('access_token', _accessToken!);
    if (_refreshToken != null) await prefs.setString('refresh_token', _refreshToken!);
    if (_phoneNumber != null) await prefs.setString('phone_number', _phoneNumber!);
    if (_name != null) await prefs.setString('name', _name!);
    if (_userId != null) await prefs.setString('user_id', _userId!);
  }

  Future<bool> login(String phone, String password) async {
    try {
      // Используем простой числовой формат номера (79775477825)
      String formattedPhone = _formatPhoneAsPlainNumber(phone);
      
      final response = await _httpClient.post(
        '$_baseUrl/api/users/login/',
        body: {
          'phone': formattedPhone,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        // Сохраняем сессию из cookies если есть
        if (response.headers.containsKey('set-cookie')) {
          _accessToken = response.headers['set-cookie']!.split(';')[0];
          _refreshToken = _accessToken;
        }
        
        try {
          final responseData = json.decode(utf8.decode(response.bodyBytes));
          
          // Авторизация на сессиях - получаем phone из ответа
          if (responseData is Map<String, dynamic> && responseData.containsKey('phone')) {
            _phoneNumber = responseData['phone'];
        
            // Получаем user_id по номеру телефона из списка пользователей
            final usersResponse = await _httpClient.get('$_baseUrl/api/users/');
            if (usersResponse.statusCode == 200) {
              final usersList = json.decode(utf8.decode(usersResponse.bodyBytes));
              if (usersList is List) {
                for (var user in usersList) {
                  if (user['phone'] == _phoneNumber) {
                    _userId = user['id'].toString();
                    _name = user['first_name'] ?? user['name'] ?? 'Пользователь';
                    break;
                  }
                }
              }
            }
          }
        } catch (e) {
          // Игнорируем ошибку парсинга
        }
        
        // Если user_id не был получен, устанавливаем имя по умолчанию
        if (_userId == null) {
          _name = 'Пользователь';
        } else if (_name == null) {
          // Если _name еще не установлено, пытаемся получить из API
          try {
            final userResponse = await _httpClient.get('$_baseUrl/api/users/$_userId');
            if (userResponse.statusCode == 200) {
              final userData = json.decode(utf8.decode(userResponse.bodyBytes));
              _name = userData['first_name'] ?? userData['name'] ?? 'Пользователь';
            } else {
              _name = 'Пользователь';
            }
          } catch (e) {
            _name = 'Пользователь';
          }
        }

        _isAuthenticated = true;
        await _saveToPrefs();
        
        // Загружаем избранные товары
        await loadFavoriteProducts();
        
        // Уведомляем слушателей после загрузки всех данных
        notifyListeners();
        
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  // Извлекает user_id из JWT токена (если токен в формате JWT)
  String? _extractUserIdFromToken(String? token) {
    if (token == null) return null;
    
    try {
      // JWT токены состоят из 3 частей, разделенных точками: header.payload.signature
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }
      
      // Декодируем payload (вторая часть)
      // Добавляем padding если нужно
      String payload = parts[1];
      switch (payload.length % 4) {
        case 1:
          payload += '===';
          break;
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }
      
      // Декодируем base64
      final decodedBytes = base64.decode(payload);
      final decodedString = String.fromCharCodes(decodedBytes);
      final payloadMap = json.decode(decodedString);
      
      // Проверяем, есть ли id или sub в payload
      if (payloadMap.containsKey('id')) {
        return payloadMap['id'].toString();
      }
      if (payloadMap.containsKey('sub')) {
        return payloadMap['sub'].toString();
      }
      // Если в токене используется 'user_id' (старая версия API)
      if (payloadMap.containsKey('user_id')) {
        return payloadMap['user_id'].toString();
      }
    } catch (e) {
      // Игнорируем ошибку
    }
    
    return null;
  }

  // Дополнительные функции форматирования
  String _formatPhoneAsPlainNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.startsWith('8')) {
      cleaned = '7${cleaned.substring(1)}';
    }
    if (cleaned.length == 10) {
      cleaned = '7$cleaned';
    }
    return cleaned;
  }

  String _formatPhoneWithPlus(String phone) {
    String cleaned = _formatPhoneAsPlainNumber(phone);
    return '+$cleaned';
  }

  String _formatPhoneWithEight(String phone) {
    String cleaned = _formatPhoneAsPlainNumber(phone);
    if (cleaned.startsWith('7')) {
      return '8${cleaned.substring(1)}';
    }
    return cleaned;
  }

  Future<String?> startRegistration(String phone, String password) async {
    try {
      // Используем простой числовой формат номера (79775477825)
      String formattedPhone = _formatPhoneAsPlainNumber(phone);

      print('[DEBUG] startRegistration: Отправка запроса на регистрацию для $formattedPhone');
      final response = await _httpClient.post(
        '$_baseUrl/api/users/registration/',
        body: {
          'phone': formattedPhone,
          'password': password,
        },
      );

      print('[DEBUG] startRegistration: Ответ сервера: statusCode=${response.statusCode}');
      print('[DEBUG] startRegistration: Тело ответа: ${response.body}');

      if (response.statusCode == 200) {
        final userId = json.decode(utf8.decode(response.bodyBytes));
        print('[DEBUG] startRegistration: Регистрация начата, userId=$userId');
        return userId.toString();
      } else if (response.statusCode == 400 || response.statusCode == 422) {
        // Пользователь уже существует
        print('[DEBUG] startRegistration: Пользователь уже зарегистрирован');
        // Пытаемся получить userId по номеру телефона
        try {
          final usersResponse = await _httpClient.get('$_baseUrl/api/users/');
          if (usersResponse.statusCode == 200) {
            final usersList = json.decode(utf8.decode(usersResponse.bodyBytes));
            if (usersList is List) {
              for (var user in usersList) {
                if (user['phone'] == formattedPhone) {
                  final existingUserId = user['id'].toString();
                  print('[DEBUG] startRegistration: Найден существующий пользователь: userId=$existingUserId');
                  // Возвращаем userId существующего пользователя для повторной отправки кода
                  return existingUserId;
                }
              }
            }
          }
        } catch (e) {
          print('[DEBUG] startRegistration: Ошибка при поиске существующего пользователя: $e');
        }
      }
      return null;
    } catch (e) {
      print('[DEBUG] startRegistration: Исключение: $e');
      return null;
    }
  }

  Future<bool> completeRegistration(String userId, String code) async {
    try {
      print('[DEBUG] completeRegistration: Отправка кода $code для userId=$userId');
      final response = await _httpClient.post(
        '$_baseUrl/api/users/registration/$userId/accept',
        body: {
          'code': code,
        },
      );

      print('[DEBUG] completeRegistration: Ответ сервера: statusCode=${response.statusCode}');
      print('[DEBUG] completeRegistration: Тело ответа: ${response.body}');

      if (response.statusCode == 200) {
        print('[DEBUG] completeRegistration: Код принят, регистрация успешна');
        
        try {
          final tokenResponse = TokenResponse.fromJson(json.decode(utf8.decode(response.bodyBytes)));
          _accessToken = tokenResponse.accessToken;
          _refreshToken = tokenResponse.refreshToken;
          _userId = userId;
          
          // Получаем данные пользователя
          print('[DEBUG] completeRegistration: Получаем данные пользователя...');
          final userResponse = await _httpClient.get('$_baseUrl/api/users/$userId');

          if (userResponse.statusCode == 200) {
            final userData = json.decode(utf8.decode(userResponse.bodyBytes));
            _phoneNumber = userData['phone'];
            _name = userData['first_name'] ?? userData['name'];
            print('[DEBUG] completeRegistration: Данные пользователя получены: phone=$_phoneNumber, name=$_name');
          } else {
            print('[DEBUG] completeRegistration: Не удалось получить данные пользователя, но регистрация успешна');
            // Устанавливаем имя по умолчанию
            _name = 'Пользователь';
          }
          
          _isAuthenticated = true;
          await _saveToPrefs();
          notifyListeners();
          
          // Загружаем избранные товары
          await loadFavoriteProducts();
          
          return true;
        } catch (e) {
          print('[DEBUG] completeRegistration: Ошибка при обработке ответа: $e, но регистрация прошла');
          // Даже если не удалось распарсить ответ, регистрация прошла успешно
          _isAuthenticated = true;
          _userId = userId;
          _name = 'Пользователь';
          await _saveToPrefs();
          notifyListeners();
          return true;
        }
      } else if (response.statusCode == 400 || response.statusCode == 422) {
        print('[DEBUG] completeRegistration: Неверный код подтверждения');
        return false;
      } else {
        print('[DEBUG] completeRegistration: Неожиданный ответ сервера: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('[DEBUG] completeRegistration: Исключение: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      if (_accessToken != null) {
        await _httpClient.post('$_baseUrl/api/users/logout');
      }
    } catch (e) {
      // Игнорируем ошибку
    } finally {
      _accessToken = null;
      _refreshToken = null;
      _phoneNumber = null;
      _name = null;
      _userId = null;
      _isAuthenticated = false;
      _favoriteProductIds.clear();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      notifyListeners();
    }
  }

  Future<bool> refreshTokens() async {
    if (_refreshToken == null) return false;

    try {
      final response = await _httpClient.post(
        '$_baseUrl/api/users/refresh',
        body: {
          'token': _refreshToken, // В API используется 'token', а не 'refresh_token'
        },
      );

      if (response.statusCode == 200) {
        final tokenResponse = TokenResponse.fromJson(json.decode(utf8.decode(response.bodyBytes)));
        _accessToken = tokenResponse.accessToken;
        _refreshToken = tokenResponse.refreshToken;
        await _saveToPrefs();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    try {
      // Получаем user_id из сохраненных данных
      if (_userId == null) {
        final prefs = await SharedPreferences.getInstance();
        _userId = prefs.getString('user_id');
      }
      
      if (_userId == null) {
        return false;
      }
      
      final userId = _userId;

        // Удаляем аккаунт
        final response = await _httpClient.delete('$_baseUrl/api/users/$userId');

        if (response.statusCode == 200) {
          // Очищаем данные пользователя после успешного удаления
          _accessToken = null;
          _refreshToken = null;
          _phoneNumber = null;
          _name = null;
          _isAuthenticated = false;
          _favoriteProductIds.clear();
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          
          notifyListeners();
          return true;
        }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      // Получаем user_id из сохраненных данных
      if (_userId == null) {
        final prefs = await SharedPreferences.getInstance();
        _userId = prefs.getString('user_id');
      }
      
      if (_userId == null) {
        return false;
      }
      
      final userId = _userId;

        // Отправляем запрос на смену пароля
        final requestBody = {'password': newPassword};
        final response = await _httpClient.post(
          '$_baseUrl/api/users/$userId/change_password',
          body: requestBody,
        );

        if (response.statusCode == 200) {
          return true;
        } else {
          return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<void> loadFavoriteProducts() async {
    try {
      if (_userId == null) {
        _favoriteProductIds.clear();
        notifyListeners();
        return;
      }

      final response = await _httpClient.get('$_baseUrl/api/users/$_userId/liked_products?user_id=$_userId');
      
      if (response.statusCode == 200) {
        final List<dynamic> favorites = json.decode(utf8.decode(response.bodyBytes));
        _favoriteProductIds = favorites.map((item) => item['id'].toString()).toSet();
      } else {
        _favoriteProductIds.clear();
      }
      notifyListeners();
    } catch (e) {
      _favoriteProductIds.clear();
      notifyListeners();
    }
  }

  Future<bool> toggleProductLike(String productId) async {
    try {
      if (_userId == null) {
        return false;
      }

      // Проверяем, лайкнут ли уже товар
      final isCurrentlyLiked = _favoriteProductIds.contains(productId);
      final endpoint = isCurrentlyLiked ? '/api/users/dislike_product' : '/api/users/like_product';
      
      final response = await _httpClient.post(
        '$_baseUrl$endpoint',
        body: {
          'user_id': int.parse(_userId!),
          'product_id': productId,
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Обновляем локальный список избранных товаров
        if (isCurrentlyLiked) {
          _favoriteProductIds.remove(productId);
        } else {
          _favoriteProductIds.add(productId);
        }
        
        notifyListeners();
        return !isCurrentlyLiked;
      }
      
      return isCurrentlyLiked;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    try {
      // Проверяем, есть ли user_id
      if (_userId == null) {
        final prefs = await SharedPreferences.getInstance();
        _userId = prefs.getString('user_id');
        
        // Если все еще нет user_id, пытаемся извлечь из токена
        if (_userId == null) {
          _userId = _extractUserIdFromToken(_accessToken);
          if (_userId != null) {
            await _saveToPrefs();
          }
        }
      }
      
      // Если есть user_id, получаем данные по ID
      if (_userId != null) {
        final response = await _httpClient.get('$_baseUrl/api/users/$_userId');
        
        if (response.statusCode == 200) {
          final userData = json.decode(utf8.decode(response.bodyBytes));
          return userData;
        }
      }
      
      // Если нет user_id, пробуем GET /api/users/ и ищем по телефону
      final response = await _httpClient.get('$_baseUrl/api/users/');
      
      if (response.statusCode == 200) {
        final usersList = json.decode(utf8.decode(response.bodyBytes));
        if (usersList is List && usersList.isNotEmpty && _phoneNumber != null) {
          // Ищем пользователя с совпадающим номером телефона
          final formattedPhone = _formatPhoneAsPlainNumber(_phoneNumber!);
          for (var userData in usersList) {
            final userPhone = userData['phone']?.toString() ?? '';
            final formattedUserPhone = _formatPhoneAsPlainNumber(userPhone);
            
            if (formattedPhone == formattedUserPhone) {
              if (_userId == null && userData['id'] != null) {
                _userId = userData['id'].toString();
                await _saveToPrefs();
              }
              return userData;
            }
          }
          
          final userData = usersList[0];
          if (_userId == null && userData['id'] != null) {
            _userId = userData['id'].toString();
            await _saveToPrefs();
      }
          return userData;
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateUserData(Map<String, dynamic> data) async {
    try {
      if (_userId == null) {
        return false;
      }
      
      final response = await _httpClient.patch(
        '$_baseUrl/api/users/$_userId/update',
        body: data,
      );
      
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<int?> addUserAddress(Map<String, dynamic> addressData) async {
    try {
      if (_userId == null) {
        return null;
      }

      final response = await _httpClient.post(
        '$_baseUrl/api/users/$_userId/add_address',
        body: addressData,
      );
      
      if (response.statusCode == 200) {
        // Пробуем распарсить ответ как число (ID адреса)
        try {
          final responseData = json.decode(utf8.decode(response.bodyBytes));
          if (responseData is int) {
            return responseData;
          } else if (responseData is String && int.tryParse(responseData) != null) {
            return int.parse(responseData);
          }
        } catch (e) {
          // Игнорируем ошибку
        }
        return 0; // Возвращаем 0 если не удалось распарсить
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> removeUserAddress(int addressId) async {
    try {
      if (_userId == null) {
        return false;
      }

      final response = await _httpClient.post(
        '$_baseUrl/api/users/$_userId/remove_address',
        body: {'id': addressId},
      );
      
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  Future<bool> setDefaultAddress(int addressId) async {
    try {
      if (_userId == null) {
        return false;
      }

      final response = await _httpClient.post(
        '$_baseUrl/api/users/$_userId/set_default_address',
        body: {'address_id': addressId},
      );
      
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  // Получение заказов пользователя
  Future<List<Map<String, dynamic>>> getUserOrders() async {
    try {
      if (_userId == null) {
        return [];
      }

      final response = await _httpClient.get(
        '$_baseUrl/api/delivery/by_user?user_id=$_userId',
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        
        // API возвращает строку, которую нужно распарсить
        if (data is String) {
          final List<dynamic> orders = json.decode(data);
          return orders.cast<Map<String, dynamic>>();
        } else if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
        
        return [];
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }

} 