import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_provider.dart';

class HttpClient {
  static final HttpClient _instance = HttpClient._internal();
  late AuthProvider _authProvider;
  
  factory HttpClient() {
    return _instance;
  }

  HttpClient._internal();

  void initialize(AuthProvider authProvider) {
    _authProvider = authProvider;
  }

  Future<http.Response> get(String url) async {
    return _sendRequest(() => http.get(
      Uri.parse(url),
      headers: _getHeaders(),
    ));
  }

  Future<http.Response> post(String url, {dynamic body}) async {
    return _sendRequest(() => http.post(
      Uri.parse(url),
      headers: _getHeaders(),
      body: body is String ? body : json.encode(body),
    ));
  }

  Future<http.Response> put(String url, {dynamic body}) async {
    return _sendRequest(() => http.put(
      Uri.parse(url),
      headers: _getHeaders(),
      body: body is String ? body : json.encode(body),
    ));
  }

  Future<http.Response> delete(String url) async {
    return _sendRequest(() => http.delete(
      Uri.parse(url),
      headers: _getHeaders(),
    ));
  }

  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (_authProvider.accessToken != null) {
      headers['Authorization'] = 'Bearer ${_authProvider.accessToken}';
    }

    return headers;
  }

  Future<http.Response> _sendRequest(Future<http.Response> Function() request) async {
    try {
      final response = await request();

      if (response.statusCode == 401) {
        final success = await _authProvider.refreshTokens();
        if (success) {
          // Повторяем запрос с новым токеном
          return await request();
        }
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }
} 