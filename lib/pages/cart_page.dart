import 'package:flutter/material.dart';
import '../style/styles.dart';

class CartPage extends StatelessWidget {
  CartPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Заголовок "Корзина"
              Center(
                child: Text(
                  'Корзина',
                  style: AppTextStyles.H1.copyWith(),
                ),
              ),
              const SizedBox(height: 30),
              // Здесь можно добавить элементы корзины
              Expanded(
                child: ListView(
                  children: [
                    CartItem(
                      title: 'Суши',
                      price: '500 ₽',
                      quantity: 2,
                    ),
                    CartItem(
                      title: 'Роллы',
                      price: '400 ₽',
                      quantity: 1,
                    ),
                    // Добавьте другие элементы корзины по аналогии
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Строка с итоговой суммой и кнопкой
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Итого: 1400 ₽',
                      style: AppTextStyles.Body.copyWith(fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Действие при нажатии на кнопку (например, переход к оформлению заказа)
                      },
                      child: const Text('Оформить заказ'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CartItem extends StatelessWidget {
  final String title;
  final String price;
  final int quantity;

  const CartItem({
    Key? key,
    required this.title,
    required this.price,
    required this.quantity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      title: Text(
        title,
        style: AppTextStyles.Body.copyWith(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '$price × $quantity',
        style: AppTextStyles.Body.copyWith(color: Colors.grey),
      ),
      trailing: Text(
        '${int.parse(price.split(' ')[0]) * quantity} ₽',
        style: AppTextStyles.Body.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
