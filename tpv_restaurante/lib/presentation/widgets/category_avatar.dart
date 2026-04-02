import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/models/models.dart';
import '../../data/services/image_storage_service.dart';

class CategoryAvatar extends StatelessWidget {
  final CategoriaProducto categoria;
  final double size;
  final BorderRadius? borderRadius;

  const CategoryAvatar({
    super.key,
    required this.categoria,
    this.size = 24,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (categoria.imagenUrl != null && categoria.imagenUrl!.isNotEmpty) {
      if (categoria.imagenUrl!.startsWith('http')) {
        return ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.circular(4),
          child: Image.network(
            categoria.imagenUrl!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFallback(),
          ),
        );
      }
      if (categoria.imagenUrl!.startsWith('categories/')) {
        final base64 = imageStorageService.getBase64FromPath(
          categoria.imagenUrl!,
        );
        if (base64.isNotEmpty) {
          return ClipRRect(
            borderRadius: borderRadius ?? BorderRadius.circular(4),
            child: Image.memory(
              base64Decode(base64),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildFallback(),
            ),
          );
        }
      }
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
    if (categoria.icono.isNotEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(categoria.icono, style: TextStyle(fontSize: size * 0.65)),
        ),
      );
    }
    return SizedBox(
      width: size,
      height: size,
      child: Icon(Icons.category, size: size * 0.7),
    );
  }
}
