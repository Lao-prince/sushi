import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cart_provider.dart';
import '../style/styles.dart';
import 'cart_checkout_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/cart_model.dart';
import '../widgets/cart_card.dart';

class DottedLinePainter extends CustomPainter {
  final Color color;

  DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;

    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = 0;
    final double y = size.height / 2;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, y),
        Offset(startX + dashWidth, y),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class CartPage extends StatelessWidget {
  const CartPage({Key? key}) : super(key: key);

  String getPortionText(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return '$count порция';
    } else if ([2, 3, 4].contains(count % 10) && ![12, 13, 14].contains(count % 100)) {
      return '$count порции';
    } else {
      return '$count порций';
    }
  }

  Widget _stepIndicator(String number, String label, bool isActive) {
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
              number,
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
      size: const Size(50, 2),
      painter: DottedLinePainter(color: isActive ? const Color(0xFFD1930D) : const Color(0xFF848484)),
    );
  }

  Widget _topCartSummary(CartProvider cartProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Заказ',
              style: AppTextStyles.H2.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 20),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cartProvider.items.length,
              separatorBuilder: (context, index) => Column(
                children: [
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFF4D4D4D), thickness: 1),
                  const SizedBox(height: 12),
                ],
              ),
              itemBuilder: (context, index) {
                final item = cartProvider.items[index];
                // Получаем текст с порциями
                String portionText = '';
                if (item.sizeName != null) {
                  final portions = int.tryParse(item.sizeName!) ?? 0;
                  if (portions > 0) {
                    if (portions % 10 == 1 && portions % 100 != 11) {
                      portionText = '$portions порция';
                    } else if ([2, 3, 4].contains(portions % 10) && ![12, 13, 14].contains(portions % 100)) {
                      portionText = '$portions порции';
                    } else {
                      portionText = '$portions порций';
                    }
                  }
                }
                return CartCard(
                  title: item.productName ?? 'Название недоступно',
                  subtitle: portionText,
                  price: '${item.price} ₽',
                  imagePath: item.productImage ?? '',
                  quantity: item.amount,
                  onRemove: () => cartProvider.updateQuantity(item.uuid, item.amount - 1),
                  onAdd: () => cartProvider.updateQuantity(item.uuid, item.amount + 1),
                  onDelete: () => cartProvider.removeItem(item.uuid),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomOrderDetails(BuildContext context) {
    var cartProvider = Provider.of<CartProvider>(context);
    double total = cartProvider.totalPrice;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
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
                        Text('${total % 1 == 0 ? total.toInt() : total} \u20BD', style: AppTextStyles.H3.copyWith(color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Divider(color: Color(0xFF4D4D4D), thickness: 1),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Итого', style: AppTextStyles.H3.copyWith(color: const Color(0xFFD1930D), fontWeight: FontWeight.bold)),
                        Text('${total % 1 == 0 ? total.toInt() : total} \u20BD', style: AppTextStyles.H3.copyWith(color: const Color(0xFFD1930D), fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    const double circleRadius = 15;
    var cartProvider = Provider.of<CartProvider>(context);
    var cartItems = cartProvider.items;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
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
              // Top block with items
              cartItems.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 100),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/sushi.png',
                            width: 150,
                            height: 150,
                            fit: BoxFit.contain,
                          ),
                          Center(
                            child: Text(
                              'Ваша корзина пуста',
                              style: AppTextStyles.H2.copyWith(color: const Color(0xFF555555)),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _topCartSummary(cartProvider),
              const SizedBox(height: 20),
              if (cartItems.isNotEmpty) _bottomOrderDetails(context),
            ],
          ),
        ),
      ),
    );
  }
}
