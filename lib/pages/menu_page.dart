import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 100) {
      final menuProvider = Provider.of<MenuProvider>(context, listen: false);
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
    return Consumer<MenuProvider>(
      builder: (context, menuProvider, child) {
        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: menuProvider.refreshMenu,
              child: Column(
                children: [
                  Padding(
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
                        if (menuProvider.isLoadingCategories)
                          const Center(child: CircularProgressIndicator())
                        else
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: menuProvider.categories.map((category) {
                                final products = menuProvider.categorizedProducts[category.id] ?? [];
                                String? firstImageUrl = products.isNotEmpty && products.first.imageLinks.isNotEmpty
                                    ? products.first.imageLinks.first
                                    : null;

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
                                                    child: CachedNetworkImage(
                                                      imageUrl: firstImageUrl,
                                                      fit: BoxFit.cover,
                                                      width: 52,
                                                      height: 52,
                                                      placeholder: (context, url) => Container(
                                                        color: const Color(0xFF3A435B),
                                                        child: const Center(
                                                          child: SizedBox(
                                                            width: 24,
                                                            height: 24,
                                                            child: CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      errorWidget: (context, url, error) => Container(
                                                        color: const Color(0xFF3A435B),
                                                        child: const Icon(Icons.error),
                                                      ),
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
                          ),
                        const SizedBox(height: 15),
                        const Divider(thickness: 2, color: Color(0xFF4D4D4D)),
                      ],
                    ),
                  ),
                  // Список всех категорий с продуктами
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (menuProvider.isLoading)
                              const Center(child: CircularProgressIndicator())
                            else
                              ...menuProvider.categories.map((category) {
                                _categoryKeys[category.id] = GlobalKey();
                                final products = menuProvider.categorizedProducts[category.id] ?? [];
                                
                                return Column(
                                  key: _categoryKeys[category.id],
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                            // Преобразуем размеры в нужный формат
                                            List<Map<String, String>> sizes = product.prices.map((price) => {
                                              'id': price.size.id,
                                              'name': price.size.name,
                                            }).toList();

                                            return SizedBox(
                                              width: cardWidth,
                                              child: ProductCard(
                                                id: product.id,
                                                imageUrl: product.imageLinks.isNotEmpty ? product.imageLinks[0] : '',
                                                title: product.name,
                                                description: product.description,
                                                price: product.prices
                                                    .firstWhere((price) => price.size.isDefault, orElse: () => product.prices[0])
                                                    .price
                                                    .toString(),
                                                sizes: sizes,
                                              ),
                                            );
                                          }).toList(),
                                        );
                                      },
                                    ),
                                  ],
                                );
                              }).toList(),
                            if (menuProvider.isLoadingMore)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(child: CircularProgressIndicator()),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
