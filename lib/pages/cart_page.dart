import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cart_provider.dart';
import '../style/styles.dart';
import 'cart_checkout_page.dart';

import '../widgets/cart_card.dart';

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

class CartPage extends StatelessWidget {
  const CartPage({super.key});


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
      size: Size(circleRadius * 3, circleRadius),
      painter: DottedLinePainter(
        color: isActive ? const Color(0xFFD1930D) : const Color(0xFF848484),
      ),
    );
  }

  Widget _topCartSummary(CartProvider cartProvider) {
    final cart = cartProvider.cart;
    if (cart == null) return const SizedBox.shrink();

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
              itemCount: cart.items.length,
              separatorBuilder: (context, index) => Column(
                children: [
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFF4D4D4D), thickness: 1),
                  const SizedBox(height: 12),
                ],
              ),
              itemBuilder: (context, index) {
                final item = cart.items[index];
                return CartCard(
                  title: item.productName,
                  subtitle: item.sizeName,
                  price: '${item.price.toInt()} ₽',
                  imagePath: item.productImage,
                  quantity: item.amount,
                  onRemove: () => cartProvider.updateQuantity(
                    item.productId,
                    item.productSizeId,
                    item.amount - 1,
                  ),
                  onAdd: () => cartProvider.updateQuantity(
                    item.productId,
                    item.productSizeId,
                    item.amount + 1,
                  ),
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
    final cart = cartProvider.cart;
    if (cart == null) return const SizedBox.shrink();
    
    double total = cart.totalPrice;

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
    final cart = cartProvider.cart;
    final cartItems = cart?.items ?? [];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
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
