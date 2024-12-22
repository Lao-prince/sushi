import 'package:flutter/material.dart';
import '../style/styles.dart';
import 'cart_checkout_page.dart';

class CartPage extends StatelessWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const double circleRadius = 15; // Circle radius
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Page title
            Text(
              'Корзина',
              style: AppTextStyles.H1.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 20),
            // Steps alignment
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _stepIndicator('1', 'Мой заказ', true),
                  _dottedLineBetweenCircles(isActive: true, circleRadius: circleRadius),
                  _stepIndicator('2', 'Оформление', false),
                  _dottedLineBetweenCircles(isActive: false, circleRadius: circleRadius),
                  _stepIndicator('3', 'Заказ принят', false),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Sample cart item
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _cartItem(
                    title: 'Ролл "Феникс"',
                    subtitle: '4 штуки',
                    price: '630 ₽',
                    imagePath: 'assets/sushi.png',
                  ),
                  const Divider(color: Color(0xFFD1930D), thickness: 1),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD1930D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartCheckoutPage()),
                  );
                },
                child: const Text('К доставке и оплате', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
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

  Widget _cartItem({
    required String title,
    required String subtitle,
    required String price,
    required String imagePath,
  }) {
    return Row(
      children: [
        Image.asset(imagePath, width: 60, height: 60),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white)),
              Text(subtitle, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        Text(price, style: const TextStyle(color: Colors.white)),
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
