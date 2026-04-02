import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/services/image_storage_service.dart';

class ProductImageWidget extends StatelessWidget {
  final Producto producto;
  final CategoriaProducto? categoria;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double placeholderFontSize;

  const ProductImageWidget({
    super.key,
    required this.producto,
    this.categoria,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholderFontSize = 48,
  });

  @override
  Widget build(BuildContext context) {
    if (producto.imagenUrl != null && producto.imagenUrl!.isNotEmpty) {
      if (producto.imagenUrl!.startsWith('products/')) {
        final base64 = imageStorageService.getBase64FromPath(
          producto.imagenUrl!,
        );
        if (base64.isNotEmpty) {
          try {
            return Image.memory(
              base64Decode(base64),
              fit: fit,
              width: width,
              height: height,
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholder();
              },
            );
          } catch (_) {
            return _buildPlaceholder();
          }
        }
      } else if (producto.imagenUrl!.startsWith('http')) {
        return Image.network(
          producto.imagenUrl!,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      }
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    final color = categoria?.color ?? AppColors.primary;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withAlpha(51), color.withAlpha(13)],
        ),
      ),
      child: Center(
        child: Text(
          categoria?.icono ?? '🍽️',
          style: TextStyle(fontSize: placeholderFontSize),
        ),
      ),
    );
  }
}
