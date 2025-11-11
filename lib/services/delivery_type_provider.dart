import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/delivery_type_model.dart';
import '../config.dart';
import 'http_client.dart';

class DeliveryTypeProvider extends ChangeNotifier {
  List<DeliveryType> _deliveryTypes = [];
  bool _isLoading = false;
  String? _errorMessage;
  final _httpClient = HttpClient();

  List<DeliveryType> get deliveryTypes => _deliveryTypes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  DeliveryTypeProvider() {
    _httpClient.initialize(null);
    _loadDeliveryTypes();
  }

  Future<void> _loadDeliveryTypes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _httpClient.get(
        '${AppConfig.baseUrl}/api/delivery/order_types'
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        
        _deliveryTypes = data.map((item) {
          return DeliveryType.fromJson(item);
        }).toList();
        
        // Фильтруем "Обычный заказ" из списка
        _deliveryTypes = _deliveryTypes.where((type) => 
          !type.name.toLowerCase().contains('обычный заказ')
        ).toList();
      } else {
        _errorMessage = 'Ошибка загрузки типов доставки: ${response.statusCode}';
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
      return 'Ошибка загрузки типов доставки. Попробуйте позже.';
    }
  }

  Future<void> retry() async {
    await _loadDeliveryTypes();
  }
}
