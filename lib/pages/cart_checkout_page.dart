import 'package:flutter/material.dart';
import '../style/styles.dart';
import 'cart_confirm_page.dart';

class CartCheckoutPage extends StatefulWidget {
  const CartCheckoutPage({Key? key}) : super(key: key);

  @override
  _CartCheckoutPageState createState() => _CartCheckoutPageState();
}

class _CartCheckoutPageState extends State<CartCheckoutPage> {
  bool isDelivery = true; // Track the selected mode (Delivery or Pickup)

  @override
  Widget build(BuildContext context) {
    const double circleRadius = 15; // Circle radius
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Заголовок "Корзина"
              Center(
                child: Text(
                  'Корзина',
                  style: AppTextStyles.H1.copyWith(color: Colors.white),
                ),
              ),
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
                    _dottedLineBetweenCircles(isActive: false, circleRadius: circleRadius),
                    _stepIndicator('3', 'Заказ принят', false),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Контейнер с заголовком "Оформление заказа" и личными данными
              Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Заголовок "Оформление заказа"
                    Text(
                      'Оформление заказа',
                      style: AppTextStyles.H2.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 20),

                    // Блок "Личные данные"
                    _buildSection('Личные данные', [
                      _buildLabeledInputField('Имя', 'Иван'),
                      _buildLabeledInputField('E-mail', 'example@mail.ru'),
                      _buildLabeledInputField('Телефон', '+7 (___) ___-__-__'),
                    ]),

                    const SizedBox(height: 32),

                    // Переключатель между доставкой и самовывозом
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Доставка',
                          style: TextStyle(color: Colors.white),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isDelivery = !isDelivery;
                            });
                          },
                          child: Container(
                            width: 160,
                            height: 40,
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: const Color(0xFF4D4D4D), width: 1.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 140,
                                  height: 30,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: isDelivery ? const Color(0xFFD1930D) : Colors.grey,
                                  ),
                                  child: Center(
                                    child: Text(
                                      isDelivery ? 'Доставка' : 'Самовывоз',
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Блок "Адрес доставки", показывается только при доставке
                    if (isDelivery)
                      _buildSection('Адрес доставки', [
                        _buildLabeledInputField('Город', 'Москва'),
                        _buildLabeledInputField('Улица', 'ул. Пушкина'),
                        _buildLabeledInputField('Дом', '10'),
                        _buildLabeledInputField('Квартира', '20'),
                      ]),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Кнопки
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Вернуться в корзину', style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD1930D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CartConfirmPage()),
                      );
                    },
                    child: const Text('Оформить заказ'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
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

  Widget _buildLabeledInputField(String label, String hintText) {
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
          _buildInputField(hintText),
        ],
      ),
    );
  }

  Widget _buildInputField(String hintText) {
    return TextField(
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
