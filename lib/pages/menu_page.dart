import 'package:flutter/material.dart';
import '../widgets/product_card.dart';
import '../style/styles.dart';

class MenuPage extends StatelessWidget {
  MenuPage({Key? key}) : super(key: key);

  final List<Product> products = [
    Product(
      imageUrl: 'https://via.placeholder.com/150',
      title: 'Суши',
      description: 'Вкусные суши с рисом и рыбой',
      price: '500 ₽',
      options: ['8 порций', '4 порции', '2 порции'],
    ),
    Product(
      imageUrl: 'https://via.placeholder.com/150',
      title: 'Роллы',
      description: 'Роллы с авокадо и сыром',
      price: '400 ₽',
      options: ['8 порций', '4 порции', '2 порции'],
    ),
    Product(
      imageUrl: 'https://via.placeholder.com/150',
      title: 'Роллы',
      description: 'Роллы с авокадо и сыром',
      price: '400 ₽',
      options: ['8 порций', '4 порции', '2 порции'],
    ),
    // Добавьте другие товары
  ];

  final List<Category> categories = [
    Category(name: 'Суши', imageUrl: 'https://via.placeholder.com/42'),
    Category(name: 'Роллы', imageUrl: 'https://via.placeholder.com/42'),
    Category(name: 'Супы', imageUrl: 'https://via.placeholder.com/42'),
    // Добавьте другие категории
  ];

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
              Center(
                child: Text(
                  'Меню',
                  style: AppTextStyles.H1.copyWith(),
                ),
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((category) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(category.imageUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category.name,
                            style: AppTextStyles.Caption.copyWith(),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
              // Горизонтальная линия по всей ширине
              const Divider(
                thickness: 1,
                color: Color(0xFF4D4D4D),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return ProductCard(
                      imageUrl: products[index].imageUrl,
                      title: products[index].title,
                      description: products[index].description,
                      price: products[index].price,
                      options: products[index].options,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Product {
  final String imageUrl;
  final String title;
  final String description;
  final String price;
  final List<String> options;

  Product({
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.price,
    required this.options,
  });
}

class Category {
  final String name;
  final String imageUrl;

  Category({required this.name, required this.imageUrl});
}
