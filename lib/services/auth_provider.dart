import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/auth_model.dart';
import 'http_client.dart';

class AuthProvider with ChangeNotifier {
  static const String _baseUrl = 'http://89.223.122.180:10000';
  final _httpClient = HttpClient();
  
  String? _accessToken;
  String? _refreshToken;
  String? _phoneNumber;
  String? _name;
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;
  String? get phoneNumber => _phoneNumber;
  String? get name => _name;
  String? get accessToken => _accessToken;

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
    _phoneNumber = prefs.getString('phone_number');
    _name = prefs.getString('name');
    _isAuthenticated = _accessToken != null;
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (_accessToken != null) await prefs.setString('access_token', _accessToken!);
    if (_refreshToken != null) await prefs.setString('refresh_token', _refreshToken!);
    if (_phoneNumber != null) await prefs.setString('phone_number', _phoneNumber!);
    if (_name != null) await prefs.setString('name', _name!);
  }

  Future<bool> login(String phone, String password) async {
    try {
      // Форматируем номер телефона
      String formattedPhone = phone;
      if (!phone.startsWith('+7') && !phone.startsWith('8')) {
        formattedPhone = '+7$phone';
      } else if (phone.startsWith('8')) {
        formattedPhone = '+7${phone.substring(1)}';
      }

      print('Отправка запроса входа с номером: $formattedPhone');
      final response = await _httpClient.post(
        '$_baseUrl/api/users/login',
        body: {
          'phone': formattedPhone,
          'password': password,
        },
      );
      print('Ответ входа: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final tokenResponse = TokenResponse.fromJson(json.decode(response.body));
        _accessToken = tokenResponse.accessToken;
        _refreshToken = tokenResponse.refreshToken;
        _phoneNumber = formattedPhone;
        
        // Получаем данные пользователя
        final userResponse = await _httpClient.get('$_baseUrl/api/users/me');
        print('Ответ /api/users/me: ${userResponse.body}');

        if (userResponse.statusCode == 200) {
          final userData = json.decode(userResponse.body);
          _name = userData['name'];
        }

        _isAuthenticated = true;
        await _saveToPrefs();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Ошибка при входе: $e');
      return false;
    }
  }

  Future<String?> startRegistration(String phone, String password) async {
    try {
      // Форматируем номер телефона
      String formattedPhone = phone;
      if (!phone.startsWith('+7') && !phone.startsWith('8')) {
        formattedPhone = '+7$phone';
      } else if (phone.startsWith('8')) {
        formattedPhone = '+7${phone.substring(1)}';
      }

      print('Отправка запроса регистрации с номером: $formattedPhone');
      final response = await _httpClient.post(
        '$_baseUrl/api/users/registration',
        body: {
          'phone': formattedPhone,
          'password': password,
        },
      );
      print('Ответ регистрации: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final userId = json.decode(response.body);
        return userId.toString();
      }
      return null;
    } catch (e) {
      print('Ошибка при начале регистрации: $e');
      return null;
    }
  }

  Future<bool> completeRegistration(String userId, String code) async {
    try {
      print('Отправка кода подтверждения для userId: $userId, код: $code');
      final response = await _httpClient.post(
        '$_baseUrl/api/users/registration/$userId/accept',
        body: {
          'code': code,
        },
      );
      print('Ответ подтверждения: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final tokenResponse = TokenResponse.fromJson(json.decode(response.body));
        _accessToken = tokenResponse.accessToken;
        _refreshToken = tokenResponse.refreshToken;
        
        // Получаем данные пользователя
        final userResponse = await _httpClient.get('$_baseUrl/api/users/me');
        print('Ответ /api/users/me: ${userResponse.body}');

        if (userResponse.statusCode == 200) {
          final userData = json.decode(userResponse.body);
          _phoneNumber = userData['phone'];
          _name = userData['name'];
          
          _isAuthenticated = true;
          await _saveToPrefs();
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Ошибка при завершении регистрации: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      if (_accessToken != null) {
        await _httpClient.post('$_baseUrl/api/users/logout');
      }
    } catch (e) {
      print('Ошибка при выходе: $e');
    } finally {
      _accessToken = null;
      _refreshToken = null;
      _phoneNumber = null;
      _name = null;
      _isAuthenticated = false;
      
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
          'refresh_token': _refreshToken,
        },
      );

      if (response.statusCode == 200) {
        final tokenResponse = TokenResponse.fromJson(json.decode(response.body));
        _accessToken = tokenResponse.accessToken;
        _refreshToken = tokenResponse.refreshToken;
        await _saveToPrefs();
        return true;
      }
      return false;
    } catch (e) {
      print('Ошибка при обновлении токенов: $e');
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    try {
      print('Начало процесса удаления аккаунта');
      // Получаем данные пользователя для получения ID
      final userResponse = await _httpClient.get('$_baseUrl/api/users/me');
      print('Ответ /api/users/me: ${userResponse.body}');

      if (userResponse.statusCode == 200) {
        final userData = json.decode(userResponse.body);
        final userId = userData['id'];
        print('Получен ID пользователя: $userId');

        // Удаляем аккаунт
        final response = await _httpClient.delete('$_baseUrl/api/users/$userId');
        print('Ответ удаления: ${response.statusCode} - ${response.body}');

        if (response.statusCode == 200) {
          print('Аккаунт успешно удален');
          // Очищаем данные пользователя после успешного удаления
          _accessToken = null;
          _refreshToken = null;
          _phoneNumber = null;
          _name = null;
          _isAuthenticated = false;
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          
          notifyListeners();
          return true;
        }
        print('Ошибка при удалении: ${response.statusCode}');
      }
      print('Ошибка получения данных пользователя: ${userResponse.statusCode}');
      return false;
    } catch (e) {
      print('Ошибка при удалении аккаунта: $e');
      return false;
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      // Получаем данные пользователя для получения ID
      final userResponse = await _httpClient.get('$_baseUrl/api/users/me');
      print('Ответ /api/users/me: ${userResponse.body}');

      if (userResponse.statusCode == 200) {
        final userData = json.decode(userResponse.body);
        final userId = userData['id'];
        print('Получен ID пользователя: $userId');

        // Отправляем запрос на смену пароля
        final response = await _httpClient.post(
          '$_baseUrl/api/users/$userId/change_password',
          body: {
            'old_password': oldPassword,
            'new_password': newPassword,
          },
        );
        print('Ответ смены пароля: ${response.statusCode} - ${response.body}');

        return response.statusCode == 200;
      }
      return false;
    } catch (e) {
      print('Ошибка при смене пароля: $e');
      return false;
    }
  }

  AuthProvider() {
    _loadFromPrefs();
  }
} 