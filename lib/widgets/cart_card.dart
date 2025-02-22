import 'package:flutter/material.dart';
import '../style/styles.dart';

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
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                image: DecorationImage(
                  image: AssetImage(imagePath),
                  fit: BoxFit.cover,
                ),
              ),
              height: 100,
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
                      decoration: const BoxDecoration(
                        color: Color(0xFFD1930D),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(25),
                          bottomRight: Radius.circular(25),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: onRemove, // Теперь `onRemove` только уменьшает количество
                            icon: const Icon(Icons.remove, color: Colors.white),
                          ),
                          Text(
                            '$quantity',
                            style: AppTextStyles.Subtitle.copyWith(color: Colors.white),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: onAdd,
                            icon: const Icon(Icons.add, color: Colors.white),
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
