import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'auth_provider.dart';

class HttpClient {
  static final HttpClient _instance = HttpClient._internal();
  AuthProvider? _authProvider;
  
  factory HttpClient() {
    return _instance;
  }

  HttpClient._internal();

  void initialize(AuthProvider? authProvider) {
    _authProvider = authProvider;
  }

  Future<http.Response> get(String url) async {
    return _sendRequest(() => http.get(
      Uri.parse(url),
      headers: _getHeaders(),
    ).timeout(const Duration(seconds: 30)));
  }

  Future<http.Response> post(String url, {dynamic body}) async {
    return _sendRequest(() => http.post(
      Uri.parse(url),
      headers: _getHeaders(),
      body: body is String ? body : json.encode(body),
    ).timeout(const Duration(seconds: 30)));
  }

  Future<http.Response> put(String url, {dynamic body}) async {
    return _sendRequest(() => http.put(
      Uri.parse(url),
      headers: _getHeaders(),
      body: body is String ? body : json.encode(body),
    ).timeout(const Duration(seconds: 30)));
  }

  Future<http.Response> patch(String url, {dynamic body}) async {
    return _sendRequest(() => http.patch(
      Uri.parse(url),
      headers: _getHeaders(),
      body: body is String ? body : json.encode(body),
    ).timeout(const Duration(seconds: 30)));
  }

  Future<http.Response> delete(String url) async {
    return _sendRequest(() => http.delete(
      Uri.parse(url),
      headers: _getHeaders(),
    ).timeout(const Duration(seconds: 30)));
  }

  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (_authProvider?.accessToken != null) {
      headers['Authorization'] = 'Bearer ${_authProvider!.accessToken}';
    }

    return headers;
  }

  Future<http.Response> _sendRequest(Future<http.Response> Function() request) async {
    // Проверяем подключение к интернету
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      throw Exception('Нет подключения к интернету');
    }
    
    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        final response = await request();

        if (response.statusCode == 401 && _authProvider != null) {
          final success = await _authProvider!.refreshTokens();
          if (success) {
            // Повторяем запрос с новым токеном
            return await request();
          }
        }

        return response;
      } catch (e) {
        retryCount++;
        
        if (retryCount >= maxRetries) {
          rethrow;
        }
        
        // Ждем перед следующей попыткой (экспоненциальная задержка)
        await Future.delayed(Duration(seconds: retryCount * 2));
      }
    }
    
    throw Exception('Не удалось выполнить запрос после $maxRetries попыток');
  }
} 