import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/payment_type_model.dart';
import '../config.dart';
import 'http_client.dart';

class PaymentTypeProvider extends ChangeNotifier {
  List<PaymentType> _paymentTypes = [];
  bool _isLoading = false;
  String? _errorMessage;
  final _httpClient = HttpClient();

  List<PaymentType> get paymentTypes => _paymentTypes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  PaymentTypeProvider() {
    _httpClient.initialize(null);
    _loadPaymentTypes();
  }

  Future<void> _loadPaymentTypes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _httpClient.get(
        '${AppConfig.baseUrl}/api/delivery/payment_types'
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        _paymentTypes = data.map((item) => PaymentType.fromJson(item.toString())).toList();
      } else {
        _errorMessage = 'Ошибка загрузки способов оплаты: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('Connection timed out')) {
      return 'Превышено время ожидания подключения к серверу. Проверьте интернет-соединение.';
    } else if (error.toString().contains('SocketException')) {
      return 'Ошибка подключения к серверу. Проверьте интернет-соединение.';
    } else if (error.toString().contains('Нет подключения к интернету')) {
      return 'Нет подключения к интернету. Проверьте настройки сети.';
    } else {
      return 'Ошибка загрузки способов оплаты. Попробуйте позже.';
    }
  }

  Future<void> retry() async {
    await _loadPaymentTypes();
  }
}





