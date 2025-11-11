import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../services/menu_provider.dart';
import '../widgets/product_card.dart';
import '../style/styles.dart';
import 'dart:async';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _topScrollController = ScrollController();
  final Map<String, GlobalKey> _categoryKeys = {};
  final Map<String, GlobalKey> _topCategoryKeys = {};
  String? _visibleCategoryId;
  bool _isProgrammaticScroll = false;
  
  final Map<String, double> _visibleCategoryFractions = {};
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _topScrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    // Логика пагинации больше не нужна - все товары загружаются сразу
  }

  void _scrollToCategory(String categoryId) {
    final keyContext = _categoryKeys[categoryId]?.currentContext;
    if (keyContext != null) {
      setState(() {
        _isProgrammaticScroll = true;
        _visibleCategoryId = categoryId;
      });

      Scrollable.ensureVisible(
        keyContext,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      ).whenComplete(() {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {
              _isProgrammaticScroll = false;
            });
          }
        });
      });
    }
  }

  void _scrollToTopCategory(String categoryId) {
    final keyContext = _topCategoryKeys[categoryId]?.currentContext;
    if (keyContext == null) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final RenderBox box = keyContext.findRenderObject() as RenderBox;
    final position = box.localToGlobal(Offset.zero, ancestor: context.findRenderObject());
    
    final itemOffset = position.dx;
    final itemWidth = box.size.width;

    var scrollOffset = _topScrollController.offset + itemOffset - (screenWidth / 2) + (itemWidth / 2);
    
    scrollOffset = scrollOffset.clamp(
      _topScrollController.position.minScrollExtent,
      _topScrollController.position.maxScrollExtent,
    );

    _topScrollController.animateTo(
      scrollOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildErrorWidget(MenuProvider menuProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Color(0xFFD1930D),
            ),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки',
              style: AppTextStyles.H2.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              menuProvider.errorMessage!,
              style: AppTextStyles.Body.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => menuProvider.retry(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD1930D),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Повторить',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onVisibilityChange(String categoryId, double visibleFraction) {
    _visibleCategoryFractions[categoryId] = visibleFraction;

    if (_isProgrammaticScroll) return;
    
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 50), () {
      if (!mounted || _isProgrammaticScroll) return;
      
      String? bestCandidateId;
      double maxFraction = 0.0;

      _visibleCategoryFractions.forEach((id, fraction) {
        if (fraction > maxFraction) {
          maxFraction = fraction;
          bestCandidateId = id;
        }
      });

      if (bestCandidateId != null && _visibleCategoryId != bestCandidateId) {
        setState(() {
          _visibleCategoryId = bestCandidateId;
        });
        Provider.of<MenuProvider>(context, listen: false).setSelectedCategory(bestCandidateId!);
        _scrollToTopCategory(bestCandidateId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MenuProvider>(
      builder: (context, menuProvider, child) {
        if (_visibleCategoryId == null && menuProvider.categories.isNotEmpty) {
          _visibleCategoryId = menuProvider.categories.first.id;
        }
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
                          child: SizedBox(
                            height: 60,
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),
                        if (menuProvider.isLoadingCategories)
                          const Center(child: CircularProgressIndicator())
                        else
                          SingleChildScrollView(
                            controller: _topScrollController,
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: menuProvider.categories.map((category) {
                                _topCategoryKeys.putIfAbsent(category.id, () => GlobalKey());

                                return GestureDetector(
                                  onTap: () {
                                    _scrollToCategory(category.id);
                                    _scrollToTopCategory(category.id);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: Container(
                                      key: _topCategoryKeys[category.id],
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: _visibleCategoryId == category.id
                                          ? const Color(0xFFD1930D)
                                            : const Color.fromARGB(0, 255, 255, 255),
                                      ),
                                                    child: Text(
                                        category.name,
                                              textAlign: TextAlign.center,
                                        style: AppTextStyles.H3.copyWith(
                                                color: _visibleCategoryId == category.id
                                                    ? const Color.fromARGB(255, 255, 255, 255)
                                                  : Colors.white,
                                              ),
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
                            else if (menuProvider.errorMessage != null)
                              _buildErrorWidget(menuProvider)
                            else
                              ...menuProvider.categories.map((category) {
                                _categoryKeys.putIfAbsent(
                                    category.id, () => GlobalKey());
                                final products = menuProvider
                                        .categorizedProducts[category.id] ??
                                    [];
                                
                                return VisibilityDetector(
                                  key: Key(category.id),
                                  onVisibilityChanged: (visibilityInfo) {
                                    _onVisibilityChange(category.id, visibilityInfo.visibleFraction);
                                  },
                                  child: Column(
                                  key: _categoryKeys[category.id],
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 25),
                                    Text(
                                      category.name,
                                        style: AppTextStyles.H2
                                            .copyWith(color: Colors.white),
                                    ),
                                    const SizedBox(height: 10),
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                          double cardWidth =
                                              (constraints.maxWidth - 10) / 2;
                                        return Wrap(
                                          spacing: 10,
                                          runSpacing: 10,
                                          children: products.map((product) {
                                            return SizedBox(
                                              width: cardWidth,
                                                child: ProductCard(product: product),
                                            );
                                          }).toList(),
                                        );
                                      },
                                    ),
                                  ],
                                  ),
                                );
                              }).toList(),
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
