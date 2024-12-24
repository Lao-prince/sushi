import 'package:flutter/material.dart';
import '../style/styles.dart';
import 'cart_confirm_page.dart';

class CartCheckoutPage extends StatefulWidget {
  const CartCheckoutPage({Key? key}) : super(key: key);

  @override
  _CartCheckoutPageState createState() => _CartCheckoutPageState();
}

class _CartCheckoutPageState extends State<CartCheckoutPage> {
  bool isDeliverySelected = true;
  String _selectedPaymentMethod = 'Не выбрано';
  final List<String> paymentOptions = ['Наличные', 'Картой', 'Онлайн'];

  void _showPaymentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Выберите способ оплаты',
                style: AppTextStyles.H2.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 16),
              for (String option in paymentOptions)
                ListTile(
                  onTap: () {
                    setState(() {
                      _selectedPaymentMethod = option;
                    });
                    Navigator.pop(context);
                  },
                  leading: const Icon(
                    Icons.payment,
                    color: Colors.white,
                  ),
                  title: Text(
                    option,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
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
              Center(
                child: Text(
                  'Корзина',
                  style: AppTextStyles.H1.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              _buildOrderSteps(),
              const SizedBox(height: 40),

              // Личные данные
              _buildSection('Личные данные', [
                _buildLabeledInputField('Имя', 'Иван'),
                _buildLabeledInputField('E-mail', 'example@mail.ru'),
                _buildLabeledInputField('Телефон', '+7 (___) ___-__-__'),
              ]),

              const SizedBox(height: 32),

              // Доставка/Самовывоз
              _buildDeliveryToggle(),

              const SizedBox(height: 32),

              if (isDeliverySelected)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Поле для адреса
                    _buildLabeledInputField(
                      'Адрес для доставки',
                      'Введите полный адрес...',
                      maxLines: 5,
                    ),
                    const SizedBox(height: 16),

                    // Поле для времени доставки
                    _buildLabeledInputField(
                      'Время доставки',
                      'Например: 12:00 - 13:00',
                    ),

                    // Поле для комментариев
                    _buildLabeledInputField(
                      'Комментарии к заказу',
                      'Введите дополнительные пожелания...',
                      maxLines: 3,
                    ),

                    const SizedBox(height: 16),
                  ],
                ),

              // Выбор способа оплаты
              _buildPaymentMethodBlock(),

              const SizedBox(height: 20),

              // Кнопки
              _buildButtons(),
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
          _dottedLineBetweenCircles(isActive: true),
          _stepIndicator('2', 'Оформление', true),
          _dottedLineBetweenCircles(isActive: false),
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

  Widget _dottedLineBetweenCircles({required bool isActive}) {
    return CustomPaint(
      size: const Size(50, 2),
      painter: DottedLinePainter(color: isActive ? const Color(0xFFD1930D) : const Color(0xFF848484)),
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

  Widget _buildLabeledInputField(String label, String hintText, {int maxLines = 1}) {
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
            maxLines: maxLines,
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

  Widget _buildDeliveryOption(String label, bool isSelected) {
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            isDeliverySelected = label == 'Доставка';
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isDeliverySelected == (label == 'Доставка')
                ? const Color(0xFFD1930D)
                : Colors.transparent,
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.Title.copyWith(
                color: isDeliverySelected == (label == 'Доставка')
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

  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Кнопка "Вернуться"
        GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
            decoration: BoxDecoration(
              color: const Color(0xFF4D4D4D),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Вернуться',
                  style: AppTextStyles.Subtitle.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),

        // Кнопка "Оформить заказ"
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartConfirmPage()),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 48),
            decoration: BoxDecoration(
              color: const Color(0xFFD1930D),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Оформить заказ',
                  style: AppTextStyles.Subtitle.copyWith(color: Colors.white),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 18,
                ),
              ],
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
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
