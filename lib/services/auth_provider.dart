import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _phoneNumber;
  String? _name;

  bool get isAuthenticated => _isAuthenticated;
  String? get phoneNumber => _phoneNumber;
  String? get name => _name;

  AuthProvider() {
    _loadAuthState();
  }

  Future<void> _loadAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    _isAuthenticated = prefs.getBool('isAuthenticated') ?? false;
    _phoneNumber = prefs.getString('phoneNumber');
    _name = prefs.getString('name');
    notifyListeners();
  }

  Future<bool> login(String phoneNumber, String password) async {
    // В реальном приложении здесь должен быть запрос к API
    // Для демонстрации просто проверяем, что пароль не пустой
    if (password.isNotEmpty) {
      _isAuthenticated = true;
      _phoneNumber = phoneNumber;
      _name = 'Пользователь'; // В реальном приложении имя должно приходить с сервера
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isAuthenticated', true);
      await prefs.setString('phoneNumber', phoneNumber);
      await prefs.setString('name', _name!);
      
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> register(String phoneNumber, String password, String name) async {
    // В реальном приложении здесь должен быть запрос к API
    if (password.isNotEmpty && name.isNotEmpty) {
      _isAuthenticated = true;
      _phoneNumber = phoneNumber;
      _name = name;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isAuthenticated', true);
      await prefs.setString('phoneNumber', phoneNumber);
      await prefs.setString('name', name);
      
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _phoneNumber = null;
    _name = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAuthenticated', false);
    await prefs.remove('phoneNumber');
    await prefs.remove('name');
    
    notifyListeners();
  }
} 