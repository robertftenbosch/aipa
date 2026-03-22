import 'package:flutter/material.dart';
import '../models/task_category.dart';

class CategoryButton extends StatelessWidget {
  final TaskCategory category;
  final VoidCallback onTap;

  const CategoryButton({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isChat = category.id == 'kletsen';
    final iconColor = isChat
        ? const Color(0xFFE91E63)
        : Theme.of(context).colorScheme.primary;
    final bgColor = isChat ? const Color(0xFFFCE4EC) : Colors.white;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: iconColor.withAlpha(30),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                category.icon,
                size: 56,
                color: iconColor,
              ),
              const SizedBox(height: 12),
              Text(
                category.label,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
