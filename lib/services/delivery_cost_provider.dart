import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/delivery_cost_model.dart';
import '../config.dart';
import 'http_client.dart';

class DeliveryCostProvider extends ChangeNotifier {
  List<DeliveryCost> _deliveryCosts = [];
  bool _isLoading = false;
  String? _errorMessage;
  final _httpClient = HttpClient();

  List<DeliveryCost> get deliveryCosts => _deliveryCosts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  DeliveryCostProvider() {
    _httpClient.initialize(null);
    _loadDeliveryCosts();
  }

  Future<void> _loadDeliveryCosts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _httpClient.get(
        '${AppConfig.baseUrl}/api/delivery/costs'
      );

      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        
        final dynamic data = json.decode(responseBody);
        
        if (data is List) {
          // Если API возвращает массив
          final List<dynamic> dataList = data;
          _deliveryCosts = dataList.map((item) {
            return DeliveryCost.fromJson(Map<String, dynamic>.from(item));
          }).toList();
        } else if (data is Map) {
          // Если API возвращает один объект
          _deliveryCosts = [DeliveryCost.fromJson(Map<String, dynamic>.from(data))];
        } else {
          _deliveryCosts = [];
        }
        
        // Фильтруем дубликаты и пустые значения
        final Map<String, DeliveryCost> uniqueCosts = {};
        for (final cost in _deliveryCosts) {
          if (cost.city.isNotEmpty && !uniqueCosts.containsKey(cost.city)) {
            uniqueCosts[cost.city] = cost;
          }
        }
        _deliveryCosts = uniqueCosts.values.toList();
      } else {
        _errorMessage = 'Ошибка загрузки стоимости доставки: ${response.statusCode}';
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
      return 'Ошибка загрузки стоимости доставки. Попробуйте позже.';
    }
  }

  double getDeliveryCost(String city) {
    final deliveryCost = _deliveryCosts.firstWhere(
      (cost) => cost.city == city,
      orElse: () => DeliveryCost(city: city, value: 0),
    );
    return deliveryCost.value;
  }

  Future<void> retry() async {
    await _loadDeliveryCosts();
  }

  void setDefaultCity() {
    if (_deliveryCosts.isNotEmpty) {
      final stupyinoIndex = _deliveryCosts.indexWhere((cost) => cost.city == 'Ступино');
      if (stupyinoIndex != -1) {
        // Перемещаем Ступино в начало списка
        final stupyino = _deliveryCosts.removeAt(stupyinoIndex);
        _deliveryCosts.insert(0, stupyino);
        notifyListeners();
      }
    }
  }
}
