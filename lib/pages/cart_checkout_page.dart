import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../style/styles.dart';
import '../services/delivery_cost_provider.dart';
import '../services/cart_provider.dart';
import '../services/auth_provider.dart';
import '../services/http_client.dart';
import '../config.dart';
import 'dart:convert';
import 'cart_confirm_page.dart';
import '../utils/phone_input_formatter.dart';

class CartCheckoutPage extends StatefulWidget {
  const CartCheckoutPage({Key? key}) : super(key: key);

  @override
  _CartCheckoutPageState createState() => _CartCheckoutPageState();
}

class _CartCheckoutPageState extends State<CartCheckoutPage> {
  bool isDeliverySelected = true;
  String _selectedPaymentMethod = 'Не выбрано';
  String? _selectedCity;
  double _deliveryCost = 0.0;
  
  // Время доставки/самовывоза
  bool _asSoonAsPossible = false;
  bool _tomorrow = false;
  String? _selectedDeliveryHour;
  String? _selectedDeliveryMinute;
  
  // Данные из API для времени
  int _makeTimeDelivery = 0;
  int _makeTimePickup = 0;
  int _period = 0;
  
  // Согласие с условиями обработки персональных данных
  bool _agreedToTerms = false;

  // Контроллеры для полей
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController(text: '+7 (9');
  final _emailController = TextEditingController();
  final _streetController = TextEditingController();
  final _houseController = TextEditingController();
  final _entranceController = TextEditingController();
  final _floorController = TextEditingController();
  final _apartmentController = TextEditingController();
  final _commentController = TextEditingController();

  final _httpClient = HttpClient();

  Future<void> _loadUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (!authProvider.isAuthenticated) {
      return;
    }
    
    try {
      final userData = await authProvider.getUserData();
      
      if (userData != null && mounted) {
        setState(() {
          // Заполняем личные данные
          _nameController.text = userData['first_name'] ?? '';
          _emailController.text = userData['email'] ?? '';
          final rawPhone = userData['phone'] ?? '';
          // Форматируем телефон для отображения
          _phoneController.text = _formatPhoneForUI(rawPhone);
          
          // Заполняем адрес, если есть
          if (userData['addresses'] != null && (userData['addresses'] as List).isNotEmpty) {
            final firstAddress = userData['addresses'][0];
            final city = firstAddress['city'];
            
            setState(() {
              _selectedCity = city ?? _selectedCity;
              _streetController.text = firstAddress['street'] ?? '';
              _houseController.text = firstAddress['house'] ?? '';
              _entranceController.text = firstAddress['entrance'] ?? '';
              _floorController.text = firstAddress['floor'] ?? '';
              _apartmentController.text = firstAddress['doorphone'] ?? '';
              
              // Обновляем стоимость доставки для автоматически заполненного города
              if (city != null && isDeliverySelected) {
                final deliveryCostProvider = Provider.of<DeliveryCostProvider>(context, listen: false);
                _deliveryCost = deliveryCostProvider.getDeliveryCost(city);
                print('[DEBUG] Автозаполнение: город=$city, стоимость доставки=$_deliveryCost');
              }
            });
          }
        });
      }
    } catch (e) {
      // Игнорируем ошибку
    }
  }

  String _formatPhoneForUI(String phone) {
    // Убираем все нечисловые символы
    String digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Если номер начинается с 7, убираем её
    if (digits.startsWith('7')) {
      digits = digits.substring(1);
    }
    
    // Форматируем как +7 (9XX) XXX-XX-XX (10 цифр после 7)
    if (digits.length == 10 && digits.startsWith('9')) {
      return '+7 (${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6, 8)}-${digits.substring(8)}';
    }
    
    return '+7 (9'; // Возвращаем префикс по умолчанию
  }

  bool _validateForm() {
    // Проверяем имя
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, введите имя'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    
    // Проверяем телефон
    if (!PhoneInputFormatter.isValidNumber(_phoneController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, введите корректный номер телефона'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    
    // Проверяем email
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, введите email'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    
    // Проверяем город
    if (_selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, выберите город'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    
    // Проверяем адрес только для доставки
    if (isDeliverySelected) {
      if (_streetController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Пожалуйста, введите улицу'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
      
      if (_houseController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Пожалуйста, введите номер дома'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }
    
    // Проверяем время доставки
    if (!_asSoonAsPossible && !_tomorrow && (_selectedDeliveryHour == null || _selectedDeliveryMinute == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, выберите время доставки или отметьте "Как можно раньше"'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    
    // Проверяем способ оплаты
    if (_selectedPaymentMethod == 'Не выбрано') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, выберите способ оплаты'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    
    // Проверяем согласие с условиями (только для неавторизованных пользователей)
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated && !_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, ознакомьтесь с условиями обработки персональных данных'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    
    return true;
  }

  Future<void> _submitOrder() async {
    if (!_validateForm()) {
      return;
    }

    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      
      // Проверяем, что в корзине есть товары
      if (cartProvider.items.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Корзина пуста. Добавьте товары для оформления заказа.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // Проверяем, что все товары имеют количество > 0
      final invalidItems = cartProvider.items.where((item) => item.amount <= 0).toList();
      if (invalidItems.isNotEmpty) {
        print('[DEBUG] _submitOrder: Найдены товары с нулевым количеством: ${invalidItems.length}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Обнаружены некорректные товары в корзине. Попробуйте обновить страницу.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      print('[DEBUG] _submitOrder: Корзина содержит ${cartProvider.items.length} товаров, общая сумма: ${cartProvider.totalPrice}');
      
      // Хардкодим ID типов доставки в зависимости от выбора пользователя
      // Эти ID получены из GET /api/delivery/order_types
      String orderTypeId;
      
      if (isDeliverySelected) {
        // Доставка курьером (DeliveryByCourier)
        orderTypeId = '76067ea3-356f-eb93-9d14-1fa00d082c4e';
      } else {
        // Самовывоз (DeliveryPickUp)
        orderTypeId = '5b1508f9-fe5b-d6af-cb8d-043af587d5c2';
      }
      
      // Формируем complete_before (время доставки)
      DateTime completeBefore;
      if (_asSoonAsPossible) {
        final now = DateTime.now();
        int minutesToAdd = isDeliverySelected ? _makeTimeDelivery : _makeTimePickup;
        final estimatedTime = now.add(Duration(minutes: minutesToAdd));
        final todayEnd = DateTime(now.year, now.month, now.day, 22, 50);
        
        // Если расчетное время позже 22:50, заказ на следующий день
        if (estimatedTime.isAfter(todayEnd)) {
          final tomorrow = now.add(const Duration(days: 1));
          final tomorrowStart = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 12, 0);
          completeBefore = tomorrowStart.add(Duration(minutes: minutesToAdd));
        }
        // Если сейчас ночь (00:00 - 12:00), заказ сегодня с 12:00
        else if (now.hour < 12) {
          final todayStart = DateTime(now.year, now.month, now.day, 12, 0);
          completeBefore = todayStart.add(Duration(minutes: minutesToAdd));
        }
        // Обычное время
        else {
          completeBefore = estimatedTime;
        }
      } else if (_tomorrow) {
        // Если выбрано "На завтра" и указано время, используем его, иначе 12:00
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final hour = int.parse(_selectedDeliveryHour ?? '12');
        final minute = int.parse(_selectedDeliveryMinute ?? '00');
        completeBefore = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, hour, minute);
      } else {
        final now = DateTime.now();
        final hour = int.parse(_selectedDeliveryHour ?? '12');
        final minute = int.parse(_selectedDeliveryMinute ?? '00');
        completeBefore = DateTime(now.year, now.month, now.day, hour, minute);
      }
      
      // Формируем адрес
      String fullAddress = '';
      if (isDeliverySelected) {
        fullAddress = '$_selectedCity, ${_streetController.text}, ${_houseController.text}';
        if (_entranceController.text.isNotEmpty) fullAddress += ', п. ${_entranceController.text}';
        if (_floorController.text.isNotEmpty) fullAddress += ', эт. ${_floorController.text}';
        if (_apartmentController.text.isNotEmpty) fullAddress += ', кв. ${_apartmentController.text}';
      } else {
        fullAddress = 'г. Ступино, Приокский переулок, 9, корп. 1';
      }
      
      // Формируем данные заказа (товары берутся из корзины на сервере)
      
      // ВАЖНО: Сервер игнорирует часовой пояс и всегда добавляет +3 часа к полученному времени
      // Поэтому отправляем время минус 3 часа (UTC), чтобы на сервере получилось правильное московское время
      final completeBeforeUtc = completeBefore.subtract(const Duration(hours: 3));
      final completeBeforeStr = '${completeBeforeUtc.year}-${completeBeforeUtc.month.toString().padLeft(2, '0')}-${completeBeforeUtc.day.toString().padLeft(2, '0')}T${completeBeforeUtc.hour.toString().padLeft(2, '0')}:${completeBeforeUtc.minute.toString().padLeft(2, '0')}:00.000';
      
      print('[DEBUG] Желаемое время доставки (МСК): ${completeBefore.hour.toString().padLeft(2, '0')}:${completeBefore.minute.toString().padLeft(2, '0')}');
      print('[DEBUG] Отправляем на сервер (UTC-3): ${completeBeforeUtc.hour.toString().padLeft(2, '0')}:${completeBeforeUtc.minute.toString().padLeft(2, '0')}');
      print('[DEBUG] Строка complete_before: $completeBeforeStr');
      
      final orderData = {
        'delivery_data': {
          'city': isDeliverySelected ? _selectedCity : 'Ступино',
          'street': isDeliverySelected ? _streetController.text : 'Приокский переулок',
          'house': isDeliverySelected ? _houseController.text : '9',
          'entrance': isDeliverySelected ? _entranceController.text : '',
          'floor': isDeliverySelected ? _floorController.text : '',
          'doorphone': isDeliverySelected ? _apartmentController.text : '',
          'comment': _commentController.text,
          'order_type_id': orderTypeId,
          'guest_count': 0,
          'complete_before': completeBeforeStr,
          'payment_type': _selectedPaymentMethod,
          'odd_money': 0,
          'delivery_cost': _deliveryCost.toInt(),
        },
        'customer_data': {
          'name': _nameController.text,
          'phone': PhoneInputFormatter.formatForApi(_phoneController.text),
          'email': _emailController.text,
        },
        'delivery_cost': _deliveryCost.toInt(),
      };

      // Получаем session cookie из CartProvider для передачи на сервер
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      // ВАЖНО: Добавляем cookie из корзины, чтобы сервер знал, какую корзину использовать
      if (cartProvider.sessionCookie != null) {
        headers['Cookie'] = cartProvider.sessionCookie!;
      }
      
      // Делаем прямой HTTP запрос с cookie вместо использования HttpClient
      print('[DEBUG] Отправка заказа на ${AppConfig.baseUrl}/api/delivery/create');
      print('[DEBUG] Headers: $headers');
      print('[DEBUG] Body: ${json.encode(orderData)}');
      
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/delivery/create'),
        headers: headers,
        body: json.encode(orderData),
      );

      print('[DEBUG] Ответ сервера при создании заказа: statusCode=${response.statusCode}');
      print('[DEBUG] Тело ответа: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final orderData = json.decode(utf8.decode(response.bodyBytes));
        print('[DEBUG] Распарсенный ответ: $orderData');
        final orderId = orderData['id'] ?? orderData['external_number'] ?? 'неизвестно';
        print('[DEBUG] ID заказа: $orderId');
        
        // Формируем строку времени доставки для отображения
        String deliveryTimeStr;
        final completeBeforeFromServer = orderData['complete_before'];
        if (completeBeforeFromServer != null) {
          try {
            final dt = DateTime.parse(completeBeforeFromServer);
            deliveryTimeStr = '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} в ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
          } catch (e) {
            deliveryTimeStr = completeBeforeFromServer.toString();
          }
        } else {
          deliveryTimeStr = 'Не указано';
        }
        
        // Сохраняем итоговую стоимость ДО очистки корзины
        final finalTotalPrice = cartProvider.totalPrice + _deliveryCost;
        print('[DEBUG] Сохранена итоговая стоимость: $finalTotalPrice (товары: ${cartProvider.totalPrice}, доставка: $_deliveryCost)');
        
        // Очищаем корзину после успешного оформления
        print('[DEBUG] Начинаем очистку корзины...');
        await cartProvider.clearCart();
        print('[DEBUG] Корзина очищена (локально)');
        
        // Проверяем, что корзина действительно очищена на сервере
        print('[DEBUG] Проверка локальной корзины: cartProvider.totalPrice=${cartProvider.totalPrice}, items.length=${cartProvider.items.length}');
        
        // Перезагружаем корзину с сервера для проверки
        print('[DEBUG] Проверяем очистку на сервере...');
        await cartProvider.fetchCart();
        print('[DEBUG] После fetchCart: items.length=${cartProvider.items.length}');
        
        if (cartProvider.items.isNotEmpty) {
          print('[DEBUG] ВНИМАНИЕ: Корзина не очистилась на сервере! Очищаем повторно...');
          await cartProvider.clearCart();
          await cartProvider.fetchCart();
          print('[DEBUG] После повторной очистки: items.length=${cartProvider.items.length}');
        }
        
        // Переходим на страницу подтверждения
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CartConfirmPage(
              orderId: orderId.toString(),
              customerName: _nameController.text,
              customerPhone: _phoneController.text,
              customerEmail: _emailController.text,
              address: fullAddress,
              totalPrice: finalTotalPrice,
              deliveryTime: deliveryTimeStr,
            ),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка при оформлении заказа: ${response.statusCode} - ${response.body}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при оформлении заказа: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Устанавливаем значения по умолчанию после загрузки данных
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final deliveryCostProvider = Provider.of<DeliveryCostProvider>(context, listen: false);
      
      // Устанавливаем Ступино по умолчанию после загрузки городов
      if (deliveryCostProvider.deliveryCosts.isNotEmpty) {
        deliveryCostProvider.setDefaultCity();
        setState(() {
          _selectedCity = 'Ступино';
          _deliveryCost = deliveryCostProvider.getDeliveryCost('Ступино');
        });
      }
      
      // Загружаем данные времени
      _loadOrderTiming();
      
      // Загружаем данные пользователя, если авторизован
      await _loadUserData();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _streetController.dispose();
    _houseController.dispose();
    _entranceController.dispose();
    _floorController.dispose();
    _apartmentController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _showPaymentOptions() {
    // Хардкодим два способа оплаты
    final paymentMethods = ['Наличными', 'Картой'];
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      backgroundColor: const Color(0xFF0C1F36),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 15),
          decoration: BoxDecoration(
            color: const Color(0xFF0C1F36),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.25),
                blurRadius: 6,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Выберите способ оплаты',
                style: AppTextStyles.H2.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 16),
              for (int i = 0; i < paymentMethods.length; i++) ...[
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPaymentMethod = paymentMethods[i];
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Flexible(
                          child: Row(
                            children: [
                              Icon(
                                Icons.payment,
                                color: _selectedPaymentMethod == paymentMethods[i]
                                    ? Colors.white
                                    : const Color(0xFF848484),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                paymentMethods[i],
                                style: AppTextStyles.H3.copyWith(
                                  color: _selectedPaymentMethod == paymentMethods[i]
                                      ? Colors.white
                                      : const Color(0xFF848484),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selectedPaymentMethod == paymentMethods[i]
                                  ? const Color(0xFFD1930D)
                                  : const Color(0xFF848484),
                              width: 1.5,
                            ),
                          ),
                          child: _selectedPaymentMethod == paymentMethods[i]
                              ? Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFFD1930D),
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
                if (i < paymentMethods.length - 1) ...[
                  const SizedBox(height: 4),
                  const Divider(
                    color: Color(0xFF4D4D4D),
                    thickness: 1,
                  ),
                  const SizedBox(height: 4),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadOrderTiming() async {
    try {
      final response = await _httpClient.get('${AppConfig.baseUrl}/api/delivery/order_timing');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _makeTimeDelivery = data['make_time_delivery'] ?? 0;
          _makeTimePickup = data['make_time_pickup'] ?? 0;
          _period = data['period'] ?? 0;
        });
      }
    } catch (e) {
      // Игнорируем ошибку
    }
  }

  String _getAsSoonAsPossibleTime() {
    final now = DateTime.now();
    int minutesToAdd = isDeliverySelected ? _makeTimeDelivery : _makeTimePickup;
    final estimatedTime = now.add(Duration(minutes: minutesToAdd));
    
    DateTime deliveryTime;
    String prefix = '';
    
    // Определяем конец рабочего дня (22:50)
    final todayEnd = DateTime(now.year, now.month, now.day, 22, 50);
    
    // Если расчетное время после 22:50, заказ на следующий день
    if (estimatedTime.isAfter(todayEnd)) {
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowStart = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 12, 0);
      deliveryTime = tomorrowStart.add(Duration(minutes: minutesToAdd));
      prefix = 'Завтра ';
    }
    // Если сейчас ночь (00:00 - 12:00), заказ сегодня с 12:00
    else if (now.hour < 12) {
      final todayStart = DateTime(now.year, now.month, now.day, 12, 0);
      deliveryTime = todayStart.add(Duration(minutes: minutesToAdd));
    }
    // Обычное время в рабочие часы
    else {
      deliveryTime = estimatedTime;
    }
    
    String startHour = deliveryTime.hour.toString().padLeft(2, '0');
    String startMinute = deliveryTime.minute.toString().padLeft(2, '0');
    
    if (_period == 0) {
      return '$prefix$startHour:$startMinute';
    }
    
    final endTime = deliveryTime.add(Duration(minutes: _period));
    String endHour = endTime.hour.toString().padLeft(2, '0');
    String endMinute = endTime.minute.toString().padLeft(2, '0');
    
    return '$prefix$startHour:$startMinute - $endHour:$endMinute';
  }

  DateTime _getMinimumDeliveryTime() {
    final now = DateTime.now();
    int minutesToAdd = isDeliverySelected ? _makeTimeDelivery : _makeTimePickup;
    final estimatedTime = now.add(Duration(minutes: minutesToAdd));
    
    // Определяем конец рабочего дня (22:50)
    final todayEnd = DateTime(now.year, now.month, now.day, 22, 50);
    
    // Если расчетное время позже 22:50, переносим на следующий день
    if (estimatedTime.isAfter(todayEnd)) {
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowStart = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 12, 0);
      return tomorrowStart.add(Duration(minutes: minutesToAdd));
    }
    
    // Если сейчас ночь (00:00 - 12:00), минимальное время сегодня с 12:00
    if (now.hour < 12) {
      final todayStart = DateTime(now.year, now.month, now.day, 12, 0);
      return todayStart.add(Duration(minutes: minutesToAdd));
    }
    
    return estimatedTime;
  }
  
  bool _canOrderToday() {
    final now = DateTime.now();
    int minutesToAdd = isDeliverySelected ? _makeTimeDelivery : _makeTimePickup;
    final estimatedTime = now.add(Duration(minutes: minutesToAdd));
    
    // Определяем конец рабочего дня (22:50)
    final todayEnd = DateTime(now.year, now.month, now.day, 22, 50);
    
    // Можно заказать на сегодня, если расчетное время до 22:50
    return !estimatedTime.isAfter(todayEnd);
  }

  List<String> _getAvailableHours() {
    // Если выбрано "На завтра", показываем все часы работы ресторана
    if (_tomorrow) {
      return List.generate(11, (index) => (index + 12).toString().padLeft(2, '0'));
    }
    
    // Если нельзя заказать на сегодня (слишком поздно), возвращаем пустой список
    if (!_canOrderToday()) {
      return [];
    }
    
    final minTime = _getMinimumDeliveryTime();
    // Только часы работы ресторана с 12:00 до 22:00 включительно
    final allHours = List.generate(11, (index) => (index + 12).toString().padLeft(2, '0'));
    
    // Фильтруем часы
    if (_selectedDeliveryHour == null) {
      // Если час не выбран, показываем только будущие часы в диапазоне работы ресторана
      return allHours.where((hour) {
        final hourInt = int.parse(hour);
        return hourInt >= 12 && hourInt < 23 && (hourInt > minTime.hour || (hourInt == minTime.hour && minTime.minute < 50));
      }).toList();
    } else {
      // Если час выбран, показываем все часы работы ресторана для удобства переключения
      return allHours;
    }
  }

  List<String> _getAvailableMinutes() {
    // Если выбрано "На завтра", показываем все минуты
    if (_tomorrow) {
      return ['00', '10', '20', '30', '40', '50'];
    }
    
    // Если нельзя заказать на сегодня, возвращаем пустой список
    if (!_canOrderToday()) {
      return [];
    }
    
    final minTime = _getMinimumDeliveryTime();
    final allMinutes = ['00', '10', '20', '30', '40', '50'];
    
    if (_selectedDeliveryHour == null) {
      return allMinutes;
    }
    
    final selectedHourInt = int.parse(_selectedDeliveryHour!);
    
    // Если выбранный час равен минимальному времени, фильтруем минуты
    if (selectedHourInt == minTime.hour) {
      // Округляем минимальные минуты вверх до ближайшего кратного 10
      int minMinute = minTime.minute;
      if (minMinute % 10 != 0) {
        minMinute = (minMinute ~/ 10 + 1) * 10;
      }
      
      return allMinutes.where((minute) {
        return int.parse(minute) >= minMinute;
      }).toList();
    } else if (selectedHourInt < minTime.hour) {
      // Если выбран час раньше минимального, возвращаем пустой список
      return [];
    } else {
      // Если выбран час позже минимального, показываем все минуты
      return allMinutes;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildOrderSteps(),
              const SizedBox(height: 40),

              // Личные данные с измененным порядком полей
              _buildSection('Личные данные', [
                _buildLabeledInputField('Имя*', 'Иван', controller: _nameController),
                _buildLabeledInputField('Телефон*', '+7 (9XX) XXX-XX-XX', controller: _phoneController, inputFormatters: [PhoneInputFormatter()], keyboardType: TextInputType.phone),
                _buildLabeledInputField('E-mail*', 'example@mail.ru', controller: _emailController),
              ]),

              const SizedBox(height: 32),

              // Доставка/Самовывоз
              _buildDeliveryToggle(),

              const SizedBox(height: 32),

              if (isDeliverySelected)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Новые поля для адреса
                    _buildCityDropdown(),
                    _buildLabeledInputField('Улица*', 'Введите улицу', controller: _streetController),
                    _buildLabeledInputField('Дом*', 'Введите номер дома', controller: _houseController),
                    _buildLabeledInputField('Подъезд', 'Введите номер подъезда', controller: _entranceController, inputFormatters: [FilteringTextInputFormatter.digitsOnly], keyboardType: TextInputType.number),
                    _buildLabeledInputField('Этаж', 'Введите этаж', controller: _floorController, inputFormatters: [FilteringTextInputFormatter.digitsOnly], keyboardType: TextInputType.number),
                    _buildLabeledInputField('Квартира', 'Введите номер квартиры', controller: _apartmentController, inputFormatters: [FilteringTextInputFormatter.digitsOnly], keyboardType: TextInputType.number),
                    const SizedBox(height: 16),

                    // Свитчи "Как можно раньше" и "На завтра" и поле для времени доставки
                    _buildDeliveryTimeSwitches(),
                    if (!_asSoonAsPossible)
                      _buildTimePicker('Время доставки*'),

                    // Поле для комментариев
                    _buildLabeledInputField(
                      'Комментарии к заказу',
                      'Введите дополнительные пожелания...',
                      controller: _commentController,
                      maxLines: 3,
                    ),

                    const SizedBox(height: 16),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Поля для самовывоза: только адрес, время и комментарии
                    _buildPickupAddress(),
                    const SizedBox(height: 16),

                    // Свитчи "Как можно раньше" и "На завтра" и поле для времени самовывоза
                    _buildDeliveryTimeSwitches(),
                    if (!_asSoonAsPossible)
                      _buildTimePicker('Время самовывоза*'),

                    // Поле для комментариев
                    _buildLabeledInputField(
                      'Комментарии к заказу',
                      'Введите дополнительные пожелания...',
                      controller: _commentController,
                      maxLines: 3,
                    ),

                    const SizedBox(height: 16),
                  ],
                ),

              // Выбор способа оплаты
              _buildPaymentMethodBlock(),

              const SizedBox(height: 20),

              // Чекбокс с условиями обработки персональных данных (только для неавторизованных)
              Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  if (!authProvider.isAuthenticated) {
                    return Column(
                      children: [
                        _buildPrivacyCheckbox(),
                        const SizedBox(height: 20),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // Общая стоимость с доставкой
              _buildTotalCost(),

              const SizedBox(height: 20),

              // Кнопки
              _buildBottomButtons(context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSteps() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _stepIndicator('1', 'Мой заказ', true),
          _dottedLineBetweenCircles(isActive: true, circleRadius: 15),
          _stepIndicator('2', 'Оформление', true),
          _dottedLineBetweenCircles(isActive: false, circleRadius: 15),
          _stepIndicator('3', 'Заказ принят', false),
        ],
      ),
    );
  }

  Widget _stepIndicator(String step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? const Color(0xFFD1930D) : const Color(0xFF848484),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              step,
              style: TextStyle(
                color: isActive ? const Color(0xFFD1930D) : const Color(0xFF848484),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.Caption.copyWith(
            color: isActive ? const Color(0xFFD1930D) : const Color(0xFF848484),
          ),
        ),
      ],
    );
  }

  Widget _dottedLineBetweenCircles({required bool isActive, required double circleRadius}) {
    return CustomPaint(
      size: Size(circleRadius * 3, circleRadius),
      painter: DottedLinePainter(
        color: isActive ? const Color(0xFFD1930D) : const Color(0xFF848484),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.H3.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ],
    );
  }

  Widget _buildCityDropdown() {
    return Consumer<DeliveryCostProvider>(
      builder: (context, deliveryCostProvider, _) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Город*',
                style: AppTextStyles.Title.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 12),
              if (deliveryCostProvider.isLoading)
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2D45),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (deliveryCostProvider.errorMessage != null)
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2D45),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Center(
                    child: Text(
                      'Ошибка загрузки городов',
                      style: AppTextStyles.Body.copyWith(color: Colors.red),
                    ),
                  ),
                )
              else if (deliveryCostProvider.deliveryCosts.isEmpty)
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2D45),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF4D4D4D)),
                  ),
                  child: const Center(
                    child: Text(
                      'Города не найдены',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2D45),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF4D4D4D)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCity != null && 
                             deliveryCostProvider.deliveryCosts.any((cost) => cost.city == _selectedCity)
                          ? _selectedCity 
                          : null,
                      hint: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Выберите город',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      isExpanded: true,
                      menuMaxHeight: 200, // Ограничиваем высоту списка
                      items: deliveryCostProvider.deliveryCosts.map((deliveryCost) {
                        return DropdownMenuItem<String>(
                          value: deliveryCost.city,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Text(
                              deliveryCost.city,
                              style: const TextStyle(color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null && newValue.isNotEmpty) {
                          setState(() {
                            _selectedCity = newValue;
                            // Обновляем стоимость доставки только если выбран тип доставки
                            if (isDeliverySelected) {
                              _deliveryCost = deliveryCostProvider.getDeliveryCost(newValue);
                            }
                          });
                        }
                      },
                      dropdownColor: const Color(0xFF1C2D45),
                      icon: const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Icon(Icons.arrow_drop_down, color: Color(0xFFD1930D)),
                      ),
                    ),
                  ),
                ),
              if (_selectedCity != null && _deliveryCost > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Стоимость доставки: ${_deliveryCost.toInt()} ₽',
                    style: AppTextStyles.Body.copyWith(
                      color: const Color(0xFFD1930D),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPickupAddress() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Адрес самовывоза',
            style: AppTextStyles.Title.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2D45),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4D4D4D)),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFFD1930D), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'г. Ступино, Приокский переулок, 9, корп. 1',
                    style: AppTextStyles.Body.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTimeSwitches() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Как можно раньше',
                      style: AppTextStyles.Title.copyWith(color: Colors.white),
                    ),
                    if (_asSoonAsPossible && (_makeTimeDelivery > 0 || _makeTimePickup > 0))
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _getAsSoonAsPossibleTime(),
                          style: AppTextStyles.Body.copyWith(color: const Color(0xFFD1930D)),
                        ),
                      ),
                  ],
                ),
              ),
              Switch(
                value: _asSoonAsPossible,
                onChanged: (bool value) {
                  setState(() {
                    _asSoonAsPossible = value;
                    if (value) {
                      // Отключаем "На завтра" при включении "Как можно раньше"
                      _tomorrow = false;
                      // Очищаем выбранное время при включении свитча
                      _selectedDeliveryHour = null;
                      _selectedDeliveryMinute = null;
                    }
                  });
                },
                activeColor: const Color(0xFFD1930D),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'На завтра',
                  style: AppTextStyles.Title.copyWith(color: Colors.white),
                ),
              ),
              Switch(
                value: _tomorrow,
                onChanged: (bool value) {
                  setState(() {
                    _tomorrow = value;
                    if (value) {
                      // Отключаем "Как можно раньше" при включении "На завтра"
                      _asSoonAsPossible = false;
                      // Очищаем выбранное время при включении свитча
                      _selectedDeliveryHour = null;
                      _selectedDeliveryMinute = null;
                    }
                  });
                },
                activeColor: const Color(0xFFD1930D),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker(String label) {
    // Получаем доступные часы и минуты с учетом минимального времени из API
    final hours = _getAvailableHours();
    final minutes = _getAvailableMinutes();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.Title.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Выбор часов
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2D45),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF4D4D4D)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedDeliveryHour,
                      hint: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Час',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      isExpanded: true,
                      menuMaxHeight: 200,
                      items: hours.map((hour) {
                        return DropdownMenuItem<String>(
                          value: hour,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Text(
                              hour,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedDeliveryHour = newValue;
                          // Сбрасываем минуты при смене часа, чтобы проверка доступности проходила заново
                          _selectedDeliveryMinute = null;
                        });
                      },
                      dropdownColor: const Color(0xFF1C2D45),
                      icon: const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Icon(Icons.arrow_drop_down, color: Color(0xFFD1930D)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Двоеточие
              const Text(
                ':',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              const SizedBox(width: 12),
              // Выбор минут
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2D45),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF4D4D4D)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedDeliveryMinute,
                      hint: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Мин',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      isExpanded: true,
                      menuMaxHeight: 200,
                      items: minutes.map((minute) {
                        return DropdownMenuItem<String>(
                          value: minute,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Text(
                              minute,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedDeliveryMinute = newValue;
                        });
                      },
                      dropdownColor: const Color(0xFF1C2D45),
                      icon: const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Icon(Icons.arrow_drop_down, color: Color(0xFFD1930D)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Подсказка, если нельзя заказать на сегодня
          if (!_canOrderToday() && !_tomorrow)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C2D45),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD1930D)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFFD1930D), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Слишком поздно для заказа на сегодня. Включите "На завтра" или выберите "Как можно раньше"',
                        style: AppTextStyles.Body.copyWith(color: const Color(0xFFD1930D)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLabeledInputField(String label, String hintText, {TextEditingController? controller, int maxLines = 1, List<TextInputFormatter>? inputFormatters, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.Title.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            maxLines: maxLines,
            inputFormatters: inputFormatters,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF1C2D45),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryToggle() {
    // Хардкодим два варианта доставки
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFF4D4D4D), width: 1.5),
      ),
      child: Row(
        children: [
          _buildDeliveryOption('Доставка', true),
          _buildDeliveryOption('Самовывоз', false),
        ],
      ),
    );
  }

  Widget _buildDeliveryOption(String label, bool isDelivery) {
    final isSelected = isDeliverySelected == isDelivery;
    
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            isDeliverySelected = isDelivery;
            // Обнуляем стоимость доставки при переключении на самовывоз
            if (!isDelivery) {
              _deliveryCost = 0.0;
            } else if (_selectedCity != null) {
              // Восстанавливаем стоимость доставки при переключении на доставку
              final deliveryCostProvider = Provider.of<DeliveryCostProvider>(context, listen: false);
              _deliveryCost = deliveryCostProvider.getDeliveryCost(_selectedCity!);
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isSelected
                ? const Color(0xFFD1930D)
                : Colors.transparent,
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.Title.copyWith(
                color: isSelected
                    ? Colors.white
                    : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodBlock() {
    return GestureDetector(
      onTap: _showPaymentOptions,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF848484), width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.payment, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  _selectedPaymentMethod,
                  style: AppTextStyles.Title.copyWith(color: Colors.white),
                ),
              ],
            ),
            Text(
              'ВЫБРАТЬ',
              style: AppTextStyles.Title.copyWith(color: const Color(0xFFD1930D)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyCheckbox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2D45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4D4D4D)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: _agreedToTerms,
            onChanged: (bool? value) {
              setState(() {
                _agreedToTerms = value ?? false;
              });
            },
            activeColor: const Color(0xFFD1930D),
            checkColor: Colors.white,
            side: const BorderSide(color: Color(0xFF848484), width: 1.5),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: RichText(
                text: TextSpan(
                  style: AppTextStyles.Body.copyWith(color: Colors.white),
                  children: [
                    const TextSpan(text: 'Я ознакомился с '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () async {
                          final url = Uri.parse('https://sushiotsashi.ru/docs/polytics.pdf');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        },
                        child: Text(
                          'условиями обработки персональных данных',
                          style: AppTextStyles.Body.copyWith(
                            color: const Color(0xFFD1930D),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    const TextSpan(text: ' и '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () async {
                          final url = Uri.parse('https://sushiotsashi.ru/docs/security.pdf');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        },
                        child: Text(
                          'политикой безопасности',
                          style: AppTextStyles.Body.copyWith(
                            color: const Color(0xFFD1930D),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCost() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        final cartTotal = cartProvider.totalPrice;
        final totalWithDelivery = cartTotal + _deliveryCost;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1C2D45),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD1930D), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Итого',
                style: AppTextStyles.H3.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Сумма заказа:',
                    style: AppTextStyles.Body.copyWith(color: Colors.grey),
                  ),
                  Text(
                    '${cartTotal.toInt()} ₽',
                    style: AppTextStyles.Body.copyWith(color: Colors.white),
                  ),
                ],
              ),
              if (isDeliverySelected && _deliveryCost > 0) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Доставка:',
                      style: AppTextStyles.Body.copyWith(color: Colors.grey),
                    ),
                    Text(
                      '${_deliveryCost.toInt()} ₽',
                      style: AppTextStyles.Body.copyWith(color: const Color(0xFFD1930D)),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              const Divider(color: Color(0xFF4D4D4D)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'К оплате:',
                    style: AppTextStyles.H3.copyWith(color: Colors.white),
                  ),
                  Text(
                    '${totalWithDelivery.toInt()} ₽',
                    style: AppTextStyles.H2.copyWith(
                      color: const Color(0xFFD1930D),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            label: const Text(
              'Вернуться',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[800],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _submitOrder,
            icon: const Text(
              'Оформить заказ',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            label: const Icon(
              Icons.arrow_forward,
              color: Colors.white,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD1930D),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DottedLinePainter extends CustomPainter {
  final Color color;

  DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const double dashWidth = 10;
    const double dashSpace = 4;
    double startX = 0;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
