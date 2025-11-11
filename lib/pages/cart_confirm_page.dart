import 'package:flutter/material.dart';
import '../style/styles.dart';

class CartConfirmPage extends StatelessWidget {
  final String orderId;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String address;
  final double totalPrice;
  final String deliveryTime;
  
  const CartConfirmPage({
    Key? key,
    required this.orderId,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.address,
    required this.totalPrice,
    required this.deliveryTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const double circleRadius = 15; // Circle radius
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView( // Оборачиваем все содержимое в SingleChildScrollView для прокрутки
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Блок с шагами
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _stepIndicator('1', 'Мой заказ', true),
                    _dottedLineBetweenCircles(isActive: true, circleRadius: circleRadius),
                    _stepIndicator('2', 'Оформление', true),
                    _dottedLineBetweenCircles(isActive: true, circleRadius: circleRadius),
                    _stepIndicator('3', 'Заказ принят', true),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Основной контейнер с подтверждением
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFFD1930D), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Первый вложенный контейнер
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle, color: Color(0xFFD1930D), size: 50),
                          const SizedBox(width: 16),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Заказ #$orderId',
                                    style: AppTextStyles.Subtitle.copyWith(color: const Color(0xFF4D4D4D)),
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Спасибо большое за заказ!',
                                  style: AppTextStyles.Title.copyWith(color: const Color(0xFFFDFDFD)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Линия
                    const Divider(color: Color(0xFF4D4D4D), thickness: 1),

                    // Второй вложенный контейнер
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ваш заказ подтвержден',
                            style: AppTextStyles.H3.copyWith(color: const Color(0xFFFDFDFD)),
                          ),
                          const SizedBox(height: 30),
                          Text(
                            'Мы приняли ваш заказ и готовим его. Письмо с подтверждением отправлено по адресу.',
                            style: AppTextStyles.Title.copyWith(color: const Color(0xFF848484)),
                          ),
                        ],
                      ),
                    ),

                    // Линия
                    const Divider(color: Color(0xFF4D4D4D), thickness: 1),

                    // Третий вложенный контейнер с информацией о клиенте
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Заголовок блока "Информация о клиенте"
                          Text(
                            'Информация о клиенте',
                            style: AppTextStyles.H3.copyWith(color: const Color(0xFFFDFDFD)),
                          ),
                          const SizedBox(height: 10),

                          // Вложенный контейнер для информации
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Блок с фамилией и именем
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Фамилия и имя',
                                        style: AppTextStyles.Title.copyWith(color: const Color(0xFFFDFDFD)),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        customerName,
                                        style: AppTextStyles.Title.copyWith(color: const Color(0xFF848484)),
                                      ),
                                    ],
                                  ),
                                ),

                                // Новый блок "Телефон"
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Телефон',
                                        style: AppTextStyles.Title.copyWith(color: const Color(0xFFFDFDFD)),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        customerPhone,
                                        style: AppTextStyles.Title.copyWith(color: const Color(0xFF848484)),
                                      ),
                                    ],
                                  ),
                                ),

                                // Новый блок "Адрес"
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Адрес',
                                        style: AppTextStyles.Title.copyWith(color: const Color(0xFFFDFDFD)),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          address,
                                          style: AppTextStyles.Title.copyWith(color: const Color(0xFF848484)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Новый блок "Время доставки"
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Время доставки',
                                        style: AppTextStyles.Title.copyWith(color: const Color(0xFFFDFDFD)),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          deliveryTime,
                                          style: AppTextStyles.Title.copyWith(color: const Color(0xFF848484)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Новый блок "Итоговая стоимость"
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Итоговая стоимость',
                                        style: AppTextStyles.Title.copyWith(color: const Color(0xFFFDFDFD)),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${totalPrice.toInt()} ₽',
                                        style: AppTextStyles.Title.copyWith(
                                          color: const Color(0xFFD1930D),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Кнопка "Вернуться в меню"
              ElevatedButton(
                onPressed: () {
                  // Возвращаемся на главную страницу (меню)
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD1930D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.restaurant_menu,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text('Вернуться в меню', style: AppTextStyles.Subtitle.copyWith(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ),
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

