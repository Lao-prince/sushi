import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/menu_provider.dart';
import '../widgets/product_card.dart';
import '../style/styles.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _categoryKeys = {};

  void _scrollToCategory(String categoryId) {
    final keyContext = _categoryKeys[categoryId]?.currentContext;
    if (keyContext != null) {
      Scrollable.ensureVisible(
        keyContext,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = Provider.of<MenuProvider>(context);
    final categories = menuProvider.categories;
    final categorizedProducts = menuProvider.categorizedProducts;
    final isLoading = menuProvider.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
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
              const SizedBox(height: 25),
              // Горизонтальный список категорий
              Consumer<MenuProvider>(
                builder: (context, menuProvider, child) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: menuProvider.categories.map((category) {
                        final products = menuProvider.categorizedProducts[category.id] ?? [];
                        String? firstImageUrl = products.isNotEmpty && products.first.imageLinks.isNotEmpty
                            ? products.first.imageLinks.first
                            : null;

                        // Разделяем название категории по словам
                        List<String> words = category.name.split(' ');
                        String longestWord = words.reduce((a, b) => a.length > b.length ? a : b);
                        double textWidth = longestWord.length * 10.0;

                        return GestureDetector(
                          onTap: () => _scrollToCategory(category.id), // Теперь скроллит к категории
                          child: Padding(
                            padding: const EdgeInsets.only(right: 20),
                            child: Column(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: const Color(0xFF3A435B),
                                  ),
                                  child: firstImageUrl != null
                                      ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      firstImageUrl,
                                      fit: BoxFit.cover,
                                      width: 52,
                                      height: 52,
                                    ),
                                  )
                                      : Center(
                                    child: Text(
                                      category.name[0],
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: textWidth > 52 ? textWidth : 52,
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                      words.join('\n'),
                                      style: AppTextStyles.Body.copyWith(),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
              const Divider(thickness: 2, color: Color(0xFF4D4D4D)),
              // Список категорий и продуктов
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController, // Применяем контроллер
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: isLoading
                        ? [const Center(child: CircularProgressIndicator())]
                        : categories.map((category) {
                      _categoryKeys.putIfAbsent(category.id, () => GlobalKey());

                      final products = categorizedProducts[category.id] ?? [];
                      return Column(
                        key: _categoryKeys[category.id], // Применяем ключ для прокрутки
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 25),
                          Text(
                            category.name,
                            style: AppTextStyles.H2.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              double cardWidth = (constraints.maxWidth - 10) / 2;
                              return Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: products.map((product) {
                                  return SizedBox(
                                    width: cardWidth,
                                    child: ProductCard(
                                      imageUrl: product.imageLinks.isNotEmpty ? product.imageLinks[0] : '',
                                      title: product.name,
                                      description: product.description,
                                      price: product.prices
                                          .firstWhere((price) => price.size.isDefault, orElse: () => product.prices[0])
                                          .price
                                          .toString(),
                                      options: product.prices.map((price) => price.size.name).toList(),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}