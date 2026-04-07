import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/services/image_storage_service.dart';

class CategoryChip extends StatelessWidget {
  final CategoriaProducto categoria;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.categoria,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? categoria.color : Theme.of(context).cardColor,
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: isSelected
                ? categoria.color
                : Colors.grey.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: categoria.color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildAvatar(),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                categoria.nombre,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final imagenUrl = categoria.imagenUrl;

    if (imagenUrl != null && imagenUrl.isNotEmpty) {
      if (imagenUrl.startsWith('data:')) {
        final base64Match = RegExp(r'base64,(.+)').firstMatch(imagenUrl);
        if (base64Match != null) {
          try {
            final base64Data = base64Match.group(1)!;
            return ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.memory(
                base64Decode(base64Data),
                width: 32,
                height: 24,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildIcon(),
              ),
            );
          } catch (_) {
            return _buildIcon();
          }
        }
      }
      if (imagenUrl.startsWith('http')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.network(
            imagenUrl,
            width: 32,
            height: 24,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildIcon(),
          ),
        );
      }
      if (imagenUrl.startsWith('categories/')) {
        final base64 = imageStorageService.getBase64FromPath(imagenUrl);
        if (base64.isNotEmpty) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.memory(
              base64Decode(base64),
              width: 32,
              height: 24,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildIcon(),
            ),
          );
        }
      }
    }
    return _buildIcon();
  }

  Widget _buildIcon() {
    if (categoria.icono.isNotEmpty) {
      return Center(
        child: Text(categoria.icono, style: const TextStyle(fontSize: 16)),
      );
    }
    return Icon(
      Icons.category,
      size: 16,
      color: isSelected ? Colors.white : categoria.color,
    );
  }
}
