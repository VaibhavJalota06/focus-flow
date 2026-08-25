import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final int iconCodePoint;
  final int colorValue;
  final bool isDefault;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
    this.isDefault = false,
  });

  IconData get icon {
    switch (id) {
      case 'work':
        return Icons.work_rounded;
      case 'personal':
        return Icons.person_rounded;
      case 'study':
        return Icons.school_rounded;
      case 'fitness':
        return Icons.fitness_center_rounded;
      case 'health':
        return Icons.favorite_rounded;
      case 'finance':
        return Icons.account_balance_wallet_rounded;
      case 'shopping':
        return Icons.shopping_cart_rounded;
      case 'ideas':
        return Icons.lightbulb_rounded;
      case 'other':
      default:
        return Icons.category_rounded;
    }
  }
  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
      'isDefault': isDefault ? 1 : 0,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      iconCodePoint: map['iconCodePoint'] as int,
      colorValue: map['colorValue'] as int,
      isDefault: (map['isDefault'] as int? ?? 0) == 1,
    );
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    int? iconCodePoint,
    int? colorValue,
    bool? isDefault,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  static List<CategoryModel> get defaultCategories => [
        CategoryModel(
          id: 'work',
          name: 'Work',
          iconCodePoint: Icons.work_rounded.codePoint,
          colorValue: 0xFF60A5FA, // Light Blue
          isDefault: true,
        ),
        CategoryModel(
          id: 'personal',
          name: 'Personal',
          iconCodePoint: Icons.person_rounded.codePoint,
          colorValue: 0xFFC084FC, // Light Purple
          isDefault: true,
        ),
        CategoryModel(
          id: 'study',
          name: 'Study',
          iconCodePoint: Icons.school_rounded.codePoint,
          colorValue: 0xFFFBBF24, // Bright Amber
          isDefault: true,
        ),
        CategoryModel(
          id: 'health',
          name: 'Health',
          iconCodePoint: Icons.favorite_rounded.codePoint,
          colorValue: 0xFFF43F5E, // Bright Coral Red
          isDefault: true,
        ),
        CategoryModel(
          id: 'fitness',
          name: 'Fitness',
          iconCodePoint: Icons.fitness_center_rounded.codePoint,
          colorValue: 0xFF10B981, // Emerald Green
          isDefault: true,
        ),
        CategoryModel(
          id: 'finance',
          name: 'Finance',
          iconCodePoint: Icons.account_balance_wallet_rounded.codePoint,
          colorValue: 0xFF2DD4BF, // Vibrant Teal
          isDefault: true,
        ),
        CategoryModel(
          id: 'shopping',
          name: 'Shopping',
          iconCodePoint: Icons.shopping_bag_rounded.codePoint,
          colorValue: 0xFFFB923C, // Bright Orange
          isDefault: true,
        ),
        CategoryModel(
          id: 'other',
          name: 'Other',
          iconCodePoint: Icons.grid_view_rounded.codePoint,
          colorValue: 0xFF818CF8, // Vibrant Periwinkle/Indigo
          isDefault: true,
        ),
      ];
}
