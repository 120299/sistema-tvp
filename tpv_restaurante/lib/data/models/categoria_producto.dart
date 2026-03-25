import 'package:flutter/material.dart';

class CategoriaProducto {
  final String id;
  final String nombre;
  final String icono;
  final Color color;
  final String? imagenUrl;
  final int orden;

  const CategoriaProducto({
    required this.id,
    required this.nombre,
    required this.icono,
    required this.color,
    this.imagenUrl,
    this.orden = 0,
  });

  CategoriaProducto copyWith({
    String? id,
    String? nombre,
    String? icono,
    Color? color,
    String? imagenUrl,
    int? orden,
  }) {
    return CategoriaProducto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      icono: icono ?? this.icono,
      color: color ?? this.color,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      orden: orden ?? this.orden,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'icono': icono,
      'color': color.toHex(),
      'imagenUrl': imagenUrl,
      'orden': orden,
    };
  }

  factory CategoriaProducto.fromJson(Map<String, dynamic> json) {
    return CategoriaProducto(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      icono: json['icono'] as String,
      color: HexColor.fromHex(json['color'] as String),
      imagenUrl: json['imagenUrl'] as String?,
      orden: json['orden'] as int? ?? 0,
    );
  }

  static const List<CategoriaProducto> defaultCategories = [
    CategoriaProducto(
      id: 'cafes',
      nombre: 'Cafés',
      icono: '☕',
      color: Color(0xFF8B4513),
      imagenUrl:
          'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=400',
    ),
    CategoriaProducto(
      id: 'bebidas',
      nombre: 'Bebidas',
      icono: '🥤',
      color: Color(0xFF2196F3),
      imagenUrl:
          'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=400',
    ),
    CategoriaProducto(
      id: 'comidas',
      nombre: 'Comidas',
      icono: '🍽️',
      color: Color(0xFFFF5722),
      imagenUrl:
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400',
    ),
    CategoriaProducto(
      id: 'postres',
      nombre: 'Postres',
      icono: '🍰',
      color: Color(0xFFE91E63),
      imagenUrl:
          'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=400',
    ),
    CategoriaProducto(
      id: 'vinos',
      nombre: 'Vinos',
      icono: '🍷',
      color: Color(0xFF7B1FA2),
      imagenUrl:
          'https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=400',
    ),
    CategoriaProducto(
      id: 'cervezas',
      nombre: 'Cervezas',
      icono: '🍺',
      color: Color(0xFFFFC107),
      imagenUrl:
          'https://images.unsplash.com/photo-1535958636474-b021ee887b13?w=400',
    ),
    CategoriaProducto(
      id: 'cockteles',
      nombre: 'Cócteles',
      icono: '🍹',
      color: Color(0xFF00BCD4),
      imagenUrl:
          'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?w=400',
    ),
    CategoriaProducto(
      id: 'snacks',
      nombre: 'Snacks',
      icono: '🥜',
      color: Color(0xFF795548),
      imagenUrl:
          'https://images.unsplash.com/photo-1599490659213-e2b9527bd087?w=400',
    ),
  ];
}

extension HexColor on Color {
  String toHex() =>
      '#${(toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  static Color fromHex(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }
}
