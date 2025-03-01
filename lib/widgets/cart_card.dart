import 'package:flutter/material.dart';
import '../style/styles.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;
  final String imagePath;
  final int quantity;
  final VoidCallback onRemove;
  final VoidCallback onAdd;
  final VoidCallback onDelete; // Новый коллбэк для удаления товара

  const CartCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.imagePath,
    required this.quantity,
    required this.onRemove,
    required this.onAdd,
    required this.onDelete, // Передаем коллбэк удаления
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Левый блок: изображение
          Flexible(
            flex: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: SizedBox(
                height: 120,
                width: 120, // Увеличиваем ширину тоже для сохранения пропорций
                child: CachedNetworkImage(
                  imageUrl: imagePath,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFD1930D),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 120,
                    height: 120,
                    child: Image.asset(
                      'assets/images/zaglushka.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  memCacheWidth: 200,
                  memCacheHeight: 200,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Правый блок: детали
          Flexible(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок и иконка удаления
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Заголовок
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.Title.copyWith(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Иконка удаления (теперь вызывает `onDelete`)
                    SizedBox(
                      width: 25,
                      height: 25,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: onDelete, // Вызываем функцию удаления
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFF555555),
                          size: 25,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.Body.copyWith(color: const Color(0xFF848484)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),
                // Блок управления количеством и ценой
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Блок с кнопками `-` и `+`
                    Container(
                      height: 24,
                      width: 100, // Фиксированная минимальная ширина
                      decoration: const BoxDecoration(
                        color: Color(0xFFD1930D),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(25),
                          bottomRight: Radius.circular(25),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: onRemove,
                              icon: const Icon(Icons.remove, color: Colors.white, size: 18),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '$quantity',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.Subtitle.copyWith(color: Colors.white),
                            ),
                          ),
                          Expanded(
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: onAdd,
                              icon: const Icon(Icons.add, color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Цена
                    Text(
                      price,
                      style: AppTextStyles.H3.copyWith(color: const Color(0xFFD1930D)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
