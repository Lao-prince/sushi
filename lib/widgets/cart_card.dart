import 'package:flutter/material.dart';
import '../style/styles.dart';

class CartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;
  final String imagePath;

  const CartCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.imagePath,
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
              height: 100, // Высота для прямоугольного изображения
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
                    // Иконка удаления
                    SizedBox(
                      width: 25,
                      height: 25,
                      child: IconButton(
                        padding: EdgeInsets.zero, // Убираем внутренние отступы
                        constraints: const BoxConstraints(),
                        onPressed: () {},
                        icon: const Icon(
                          Icons.delete_outlined,
                          color: const Color(0xFFEB8B8D),
                          size: 25, // Устанавливаем размер иконки
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4), // Отступ 4px между заголовком и описанием
                // Описание
                Text(
                  subtitle,
                  style: AppTextStyles.Body.copyWith(color: const Color(0xFF848484)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24), // Отступ между описанием и блоком порций
                // Блок порций и цены
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Контейнер с кнопками минус и плюс
                    Container(
                      height: 24, // Устанавливаем высоту блока
                      decoration: const BoxDecoration(
                        color: Color(0xFFD1930D), // Золотой фон
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(25), // Закругление верхнего левого угла
                          bottomRight: Radius.circular(25), // Закругление нижнего правого угла
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {},
                            icon: const Icon(Icons.remove, color: Colors.white), // Белая иконка
                          ),
                          Text(
                            '1',
                            style: AppTextStyles.Subtitle.copyWith(color: Colors.white), // Белый текст
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {},
                            icon: const Icon(Icons.add, color: Colors.white), // Белая иконка
                          ),
                        ],
                      ),
                    ),
                    // Цена
                    Text(
                      price,
                      style: AppTextStyles.H3.copyWith(color: Color(0xFFD1930D)),
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
