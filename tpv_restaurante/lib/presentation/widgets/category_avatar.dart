import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/models/models.dart';
import '../../data/services/image_storage_service.dart';

class CategoryAvatar extends StatelessWidget {
  final CategoriaProducto categoria;
  final double size;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const CategoryAvatar({
    super.key,
    required this.categoria,
    this.size = 24,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final imagenUrl = categoria.imagenUrl;
    final imageWidth = width ?? size;
    final imageHeight = height ?? size;

    if (imagenUrl != null && imagenUrl.isNotEmpty) {
      if (imagenUrl.startsWith('data:')) {
        final base64Match = RegExp(r'base64,(.+)').firstMatch(imagenUrl);
        if (base64Match != null) {
          try {
            final base64Data = base64Match.group(1)!;
            return ClipRRect(
              borderRadius: borderRadius ?? BorderRadius.circular(4),
              child: Image.memory(
                base64Decode(base64Data),
                width: imageWidth,
                height: imageHeight,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFallback(),
              ),
            );
          } catch (_) {
            return _buildFallback();
          }
        }
      }
      if (imagenUrl.startsWith('http')) {
        return ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.circular(4),
          child: Image.network(
            imagenUrl,
            width: imageWidth,
            height: imageHeight,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFallback(),
          ),
        );
      }
      if (imagenUrl.startsWith('categories/')) {
        final base64 = imageStorageService.getBase64FromPath(imagenUrl);
        if (base64.isNotEmpty) {
          return ClipRRect(
            borderRadius: borderRadius ?? BorderRadius.circular(4),
            child: Image.memory(
              base64Decode(base64),
              width: imageWidth,
              height: imageHeight,
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
    final fallbackSize = width ?? size;
    if (categoria.icono.isNotEmpty) {
      return SizedBox(
        width: fallbackSize,
        height: fallbackSize,
        child: Center(
          child: Text(
            categoria.icono,
            style: TextStyle(fontSize: fallbackSize * 0.65),
          ),
        ),
      );
    }
    return SizedBox(
      width: fallbackSize,
      height: fallbackSize,
      child: Icon(
        Icons.category,
        size: fallbackSize * 0.7,
        color: categoria.color,
      ),
    );
  }
}
