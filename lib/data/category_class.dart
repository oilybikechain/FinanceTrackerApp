// lib/data/category_class.dart
import 'package:flutter/material.dart';

class Category {
  final int? id;
  final String name;
  final int colorValue;
  final bool isSystemDefault;

  static const int defaultColorValue = 0xFFB0BEC5;

  Category({
    this.id,
    required this.name,
    this.colorValue = defaultColorValue,
    this.isSystemDefault = false,
  });

  // Helper getter to easily get a Flutter Color object
  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color_value': colorValue,
      'is_system_default': isSystemDefault ? 1 : 0,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      colorValue: map['color_value'] as int? ?? defaultColorValue,
      isSystemDefault: (map['is_system_default'] as int? ?? 0) == 1,
    );
  }

  Category copyWith({
    int? id,
    String? name,
    int? colorValue,
    bool? isSystemDefault,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      isSystemDefault: isSystemDefault ?? this.isSystemDefault,
    );
  }

  @override
  String toString() {
    return 'Category(id: $id, name: "$name", colorValue: $colorValue, isSystemDefault: $isSystemDefault)';
  }

  // For equality checks if using Categories in Sets or as Map keys
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category &&
        other.id == id &&
        other.name == name &&
        other.colorValue == colorValue &&
        other.isSystemDefault == isSystemDefault;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      colorValue.hashCode ^
      isSystemDefault.hashCode;
}
