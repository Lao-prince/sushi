import 'package:flutter/material.dart';
import '../style/styles.dart';
import 'cart_checkout_page.dart';
import '../widgets/cart_card.dart';

class CartPage extends StatelessWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const double circleRadius = 15; // Circle radius
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView( // Оборачиваем в SingleChildScrollView для прокрутки
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
              // Верхний блок с товарами
              _topCartSummary(context),
              const SizedBox(height: 20),
              // Новый блок "Приборы"
              _instrumentsBlock(context),
              const SizedBox(height: 20),
              // Новый блок "Дополнительно"
              _additionalBlock(context),
              const SizedBox(height: 20),
              // Bottom block with order details and button
              _bottomOrderDetails(context),
            ],
          ),
        ),
      ),
    );
  }

  // Новый блок "Приборы"
  Widget _instrumentsBlock(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFD1930D), width: 1.5),
          gradient: const LinearGradient(
            colors: [Color(0xFF3A435B), Color(0xFF0A0A0A)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Приборы',
              style: AppTextStyles.H2.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 15),
            // Добавим картинку или товар для прибора
            const CartCard(
              title: 'Прибор "Ложка для суши"',
              subtitle: '1 шт',
              price: '150 ₽',
              imagePath: 'assets/images/sushi.jpg',
            ),
          ],
        ),
      ),
    );
  }

  // Новый блок "Дополнительно"
  Widget _additionalBlock(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFD1930D), width: 1.5),
          gradient: const LinearGradient(
            colors: [Color(0xFF3A435B), Color(0xFF0A0A0A)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Дополнительно',
              style: AppTextStyles.H2.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 15),
            // Добавим товары для дополнительных товаров
            const CartCard(
              title: 'Соус "Соевый"',
              subtitle: '1 шт',
              price: '50 ₽',
              imagePath: 'assets/images/sushi.jpg',
            ),
            const SizedBox(height: 15),
            const CartCard(
              title: 'Имбирь',
              subtitle: '1 шт',
              price: '30 ₽',
              imagePath: 'assets/images/zaglushka.png',
            ),
          ],
        ),
      ),
    );
  }

  Widget _topCartSummary(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFD1930D), width: 1.5),
          gradient: const LinearGradient(
            colors: [Color(0xFF3A435B), Color(0xFF0A0A0A)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Заказ',
              style: AppTextStyles.H2.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 15),
            // Использование CartCard
            const CartCard(
              title: 'Суши "Спайси Унаги Гриль"',
              subtitle: '6 штук',
              price: '530 ₽',
              imagePath: 'assets/images/sushi.jpg',
            ),
            const SizedBox(height: 8),
            const Divider(color: Color(0xFF4D4D4D), thickness: 1),
            const SizedBox(height: 8),
            const CartCard(
              title: 'Сет "Ассорти"',
              subtitle: '12 штук',
              price: '1250 ₽',
              imagePath: 'assets/images/zaglushka.png',
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomOrderDetails(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15), // Отступы по 15px от краев приложения
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
          ),
          border: Border.all(color: const Color(0xFFD1930D), width: 1.5),
          gradient: const LinearGradient(
            colors: [Color(0xFF3A435B), Color(0xFF0A0A0A)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Стоимость заказа',
                  style: AppTextStyles.H2.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Сумма заказа', style: AppTextStyles.H3.copyWith(color: Colors.grey)),
                        Text('630 ₽', style: AppTextStyles.H3.copyWith(color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Divider(color: Color(0xFF4D4D4D), thickness: 1),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Итого', style: AppTextStyles.H3.copyWith(color: const Color(0xFFD1930D), fontWeight: FontWeight.bold)),
                        Text('630 ₽', style: AppTextStyles.H3.copyWith(color: const Color(0xFFD1930D), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('К доставке и оплате', style: AppTextStyles.Subtitle.copyWith(color: Colors.white)),
                ],
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
