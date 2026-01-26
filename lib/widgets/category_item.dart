import 'package:flutter/material.dart';

class CategoryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;

  const CategoryItem({
    super.key, 
    required this.icon, 
    required this.label, 
    this.isPrimary = false
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isPrimary ? const Color(0xFF3E8B98) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: isPrimary ? null : Border.all(color: Colors.grey.shade100),
          ),
          child: Icon(icon, color: isPrimary ? Colors.white : const Color(0xFF3E8B98)),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}