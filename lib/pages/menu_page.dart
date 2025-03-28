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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);

    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100 &&
        !menuProvider.isLoadingMore &&
        menuProvider.hasMoreData) {
      menuProvider.loadMoreProducts();
    }
  }

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
    final isLoadingMore = menuProvider.isLoadingMore;

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
                          onTap: () {
                            menuProvider.setSelectedCategory(category.id);
                            _scrollToCategory(category.id);
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: menuProvider.selectedCategoryId == category.id 
                                  ? const Color(0xFFD1930D)
                                  : Colors.transparent,
                              ),
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
                                    child: Text(
                                      words.join('\n'),
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.Body.copyWith(
                                        color: menuProvider.selectedCategoryId == category.id 
                                          ? Colors.black
                                          : Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
              // Список категорий и продуктов с ленивой загрузкой
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: isLoading
                        ? [const Center(child: CircularProgressIndicator())]
                        : [
                      for (var category in categories)
                        Column(
                          key: _categoryKeys.putIfAbsent(category.id, () => GlobalKey()),
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
                                  children: (categorizedProducts[category.id] ?? []).map((product) {
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
                        ),
                      if (isLoadingMore)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
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
