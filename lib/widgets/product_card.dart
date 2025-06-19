import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../style/styles.dart';
import '../services/cart_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/menu_model.dart';

class ProductCard extends StatefulWidget {
  final String id;
  final String imageUrl;
  final String title;
  final String description;
  final String price;
  final List<Map<String, dynamic>> sizes;

  const ProductCard({
    Key? key,
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.price,
    required this.sizes,
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
  bool isFavorite = false;

  bool get hasValidSizes => widget.sizes.isNotEmpty;

  @override
  void initState() {
    super.initState();
    
    if (hasValidSizes) {
      selectedSizeId = widget.sizes.first['id'] as String;
      currentPrice = widget.sizes.first['price']?.toString() ?? widget.price;
    } else {
      // Для товаров без порций используем ID самого товара
      selectedSizeId = widget.id;
      currentPrice = widget.sizes.isNotEmpty 
          ? widget.sizes.first['price']?.toString() ?? widget.price
          : widget.price;
    }
  }

  void _updatePrice(String sizeId) {
    if (!hasValidSizes) return;
    
    try {
      final selectedSize = widget.sizes.firstWhere(
        (size) => size['id'] == sizeId,
      );
      setState(() {
        currentPrice = selectedSize['price']?.toString() ?? widget.price;
      });
    } catch (e) {
      // В случае ошибки оставляем текущую цену без изменений
    }
  }

  String formatPortion(String portion) {
    int? number = int.tryParse(portion);
    if (number == null) return portion;
    return '$number шт.';
  }

  void _addToCart() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    
    if (hasValidSizes) {
      Map<String, dynamic> selectedSize;
      try {
        selectedSize = widget.sizes.firstWhere(
          (size) => size['id'] == selectedSizeId,
        );
      } catch (e) {
        selectedSize = widget.sizes.first;
      }
      
      final product = Product(
        id: widget.id,
        name: widget.title,
        imageLinks: [widget.imageUrl],
        description: widget.description,
        category: Category(id: '', name: ''),
        prices: [
          Price(
            size: Size(
              id: selectedSizeId,
              name: selectedSize['name'] as String,
              isDefault: true
            ),
            price: int.tryParse(currentPrice) ?? 0,
            count: int.tryParse(selectedSize['count'].toString()) ?? 1,
          )
        ],
      );
      
      cartProvider.addToCart(product, selectedSizeId, 1);
    } else {
      // Для товаров без порций используем ID товара
      final product = Product(
        id: widget.id,
        name: widget.title,
        imageLinks: [widget.imageUrl],
        description: widget.description,
        category: Category(id: '', name: ''),
        prices: [
          Price(
            size: Size(
              id: widget.id,
              name: 'Стандартная порция',
              isDefault: true
            ),
            price: int.tryParse(currentPrice) ?? 0,
            count: 1
          )
        ],
      );
      
      cartProvider.addToCart(product, widget.id, 1);
    }
  }

  Widget _buildProductImage() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(_borderRadius)),
      child: AspectRatio(
        aspectRatio: 1,
        child: widget.imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: widget.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: _darkBlueColor,
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
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
            border: Border.all(
              color: _goldColor,
              width: _borderWidth,
            ),
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
    // Проверяем, есть ли у товара порции (кроме стандартной)
    bool hasPortions = widget.sizes.any((size) => 
      size['id'] != widget.id && 
      (int.tryParse(size['count'].toString()) ?? 0) > 0
    );

    if (!hasPortions) return const SizedBox(width: 8);

    // Фильтруем размеры
    final validSizes = widget.sizes.where((size) => 
      size['id'] != widget.id && 
      (int.tryParse(size['count'].toString()) ?? 0) > 0
    ).toSet().toList();

    // Если текущий выбранный размер не в списке валидных, выбираем первый валидный
    if (!validSizes.any((size) => size['id'] == selectedSizeId)) {
      selectedSizeId = validSizes.first['id'] as String;
      _updatePrice(selectedSizeId);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _goldColor, width: _borderWidth),
      ),
      child: DropdownButton<String>(
        value: selectedSizeId,
        items: validSizes.map((size) {
          return DropdownMenuItem<String>(
            value: size['id'] as String,
            child: Text(
              '${size['count']} шт.',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              selectedSizeId = value;
            });
            _updatePrice(value);
          }
        },
        dropdownColor: _darkBlueColor,
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down, color: _goldColor),
        isDense: true,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPrice() {
    return Text(
      '$currentPrice ₽',
      style: const TextStyle(
        fontSize: _priceFontSize,
        fontFamily: 'HattoriHanzo',
        color: _goldColor,
      ),
    );
  }

  Widget _buildCartControls(int cartItemCount) {
    if (cartItemCount > 0) {
      return Container(
        decoration: const BoxDecoration(
          color: _goldColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  Provider.of<CartProvider>(context, listen: false)
                      .updateQuantity(widget.id, selectedSizeId, cartItemCount - 1);
                },
                child: const Center(
                  child: Icon(Icons.remove, color: Colors.white),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '$cartItemCount',
                  style: AppTextStyles.Subtitle.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: _addToCart,
                child: const Center(
                  child: Icon(Icons.add, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ElevatedButton(
      onPressed: _addToCart,
      style: ElevatedButton.styleFrom(
        backgroundColor: _goldColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
        ),
      ),
      child: const Text(
        'Добавить',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final cartItemCount = cartProvider.getItemCount(widget.id, selectedSizeId);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_borderRadius),
        gradient: const LinearGradient(
          colors: [_darkBlueColor, _blackColor],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
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
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(widget.title, style: AppTextStyles.Title),
                const SizedBox(height: 4),
                Text(
                  widget.description,
                  style: AppTextStyles.Body.copyWith(color: _grayColor),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSizeSelector(),
                    _buildPrice(),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: _buildCartControls(cartItemCount),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
