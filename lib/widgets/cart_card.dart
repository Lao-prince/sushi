import 'package:flutter/material.dart';

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
    return Row(
      children: [
        Image.asset(imagePath, width: 120, height: 80),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white)),
              Text(subtitle, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        Text(price, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}
