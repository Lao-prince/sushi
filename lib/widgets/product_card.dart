import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../style/styles.dart';
import '../services/cart_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/menu_model.dart';

class ProductCard extends StatefulWidget {
  final Product product;

  const ProductCard({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  _ProductCardState createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  // Константы для цветов
  static const Color _goldColor = Color(0xFFD1930D);
  static const Color _darkBlueColor = Color(0xFF3A435B);
  static const Color _blackColor = Color(0xFF0A0A0A);
  static const Color _grayColor = Color(0xFF555555);

  // Константы для размеров
  static const double _borderRadius = 15.0;
  static const double _borderWidth = 1.5;
  static const double _iconSize = 18.0;
  static const double _priceFontSize = 22.0;

  late String selectedSizeId;
  late String currentPrice;
  late List<Map<String, dynamic>> sizes;
  bool isFavorite = false;
  bool _isExpanded = false;

  bool get hasValidSizes => sizes.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _initializeFromProduct();
  }

  @override
  void didUpdateWidget(covariant ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.product.id != oldWidget.product.id) {
      _initializeFromProduct();
    }
  }

  void _initializeFromProduct() {
    final product = widget.product;
    
    sizes = product.prices.map((price) {
      return <String, dynamic>{
        'id': price.size.id.isEmpty ? product.id : price.size.id,
        'name': price.size.mapped_name ?? price.size.name ?? 'Порция',
        'count': price.count.toString(),
        'price': price.price.toString(),
      };
    }).toList();

    if (sizes.isNotEmpty) {
      final defaultSize = sizes.firstWhere(
        (s) => widget.product.prices.any((p) => p.size.id == s['id'] && p.size.isDefault),
        orElse: () => sizes.first,
      );
      selectedSizeId = defaultSize['id'];
      currentPrice = defaultSize['price'];
    } else {
      selectedSizeId = product.id;
      currentPrice = '0';
    }
  }

  void _updatePrice(String sizeId) {
    final selectedSizeData = sizes.firstWhere((size) => size['id'] == sizeId);
    setState(() {
      currentPrice = selectedSizeData['price'];
    });
  }

  void _addToCart() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // Определяем, есть ли у товара реальные порции (ID размера не пустой и не равен ID товара)
    bool hasRealPortions = widget.product.prices.any((p) => p.size.id.isNotEmpty && p.size.id != widget.product.id);
    
    // Если есть реальные порции, используем выбранный ID. 
    // Если нет (товар без порций), используем ID самого товара как идентификатор в `ProductCard`,
    // но в провайдер отправляем пустую строку, чтобы он понял, что это товар без ID порции.
    final sizeIdForProvider = hasRealPortions ? selectedSizeId : '';

    cartProvider.addToCart(widget.product, sizeIdForProvider, 1);
  }

  Widget _buildProductImage() {
    final imageUrl = widget.product.imageLinks.isNotEmpty ? widget.product.imageLinks.first : '';
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(_borderRadius)),
      child: AspectRatio(
        aspectRatio: 1,
        child: imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: _darkBlueColor,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Image.asset(
                  'assets/images/zaglushka.png',
                  fit: BoxFit.cover,
                ),
              )
            : Image.asset(
                'assets/images/zaglushka.png',
                fit: BoxFit.cover,
              ),
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return Positioned(
      top: 10,
      right: 10,
      child: GestureDetector(
        onTap: () {
          setState(() {
            isFavorite = !isFavorite;
          });
        },
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _goldColor, width: _borderWidth),
            color: isFavorite ? Colors.red : Colors.transparent,
          ),
          child: Icon(
            Icons.favorite,
            color: isFavorite ? Colors.white : _goldColor,
            size: _iconSize,
          ),
        ),
      ),
    );
  }

  Widget _buildSizeSelector() {
    bool hasMoreThanOnePortion = sizes.where((s) => (int.tryParse(s['count']) ?? 0) > 0).length > 1;

    if (!hasMoreThanOnePortion) return const SizedBox.shrink();

    final validSizes = sizes.where((s) => (int.tryParse(s['count']) ?? 0) > 0).toList();

    if (!validSizes.any((s) => s['id'] == selectedSizeId)) {
      final firstValid = validSizes.first;
      selectedSizeId = firstValid['id'];
      currentPrice = firstValid['price'];
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _goldColor, width: _borderWidth),
      ),
      child: DropdownButton<String>(
        isDense: true,
        value: selectedSizeId,
        items: validSizes.map((size) {
          return DropdownMenuItem<String>(
            value: size['id'],
            child: Text(
              '${size['count']} шт.',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              selectedSizeId = value;
              _updatePrice(value);
            });
          }
        },
        icon: const Icon(Icons.arrow_drop_down, color: _goldColor),
        underline: const SizedBox.shrink(),
        dropdownColor: _darkBlueColor,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildCartControls(CartProvider cartProvider) {
    bool hasRealPortions = widget.product.prices.any((p) => p.size.id.isNotEmpty && p.size.id != widget.product.id);
    final sizeIdForCart = hasRealPortions ? selectedSizeId : '';

    final cartItemCount = cartProvider.getItemCount(widget.product.id, sizeIdForCart);

    if (cartItemCount > 0) {
      return Container(
        height: 44,
        decoration: BoxDecoration(
          color: _goldColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                cartProvider.updateQuantity(widget.product.id, sizeIdForCart, cartItemCount - 1);
              },
              icon: const Icon(Icons.remove, color: Colors.white),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            Text(
              '$cartItemCount',
              style: AppTextStyles.H3.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: _addToCart,
              icon: const Icon(Icons.add, color: Colors.white),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        onPressed: _addToCart,
        style: ElevatedButton.styleFrom(
          backgroundColor: _goldColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text('Добавить', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildDescription() {
    final textStyle = AppTextStyles.Body.copyWith(color: _grayColor);
    final moreStyle = AppTextStyles.Body.copyWith(color: _goldColor, fontWeight: FontWeight.bold);

    // Если текст развернут, делаем всю область кликабельной для сворачивания
    if (_isExpanded) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _isExpanded = false;
          });
        },
        child: Text(widget.product.description, style: textStyle),
      );
    }

    // Оборачиваем весь Stack в один GestureDetector
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = true;
        });
      },
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Text(
            widget.product.description,
            style: textStyle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // Этот Positioned нужен, чтобы многоточие не растягивало Stack
          Positioned(
            right: 0,
            bottom: 0,
            child: Text('...', style: moreStyle),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_darkBlueColor, _blackColor],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(_borderRadius),
        border: Border.all(color: _goldColor, width: _borderWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              _buildProductImage(),
              _buildFavoriteButton(),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.name,
                  style: AppTextStyles.H3.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                _buildDescription(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildSizeSelector(),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${double.tryParse(currentPrice)?.toStringAsFixed(0) ?? currentPrice} ₽',
                        style: AppTextStyles.H2.copyWith(
                          color: _goldColor,
                          fontSize: _priceFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildCartControls(cartProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

