import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/services/image_storage_service.dart';
import '../providers/providers.dart';

class ProductCard extends ConsumerWidget {
  final Producto producto;
  final VoidCallback onTap;
  final bool showEditIcon;

  const ProductCard({
    super.key,
    required this.producto,
    required this.onTap,
    this.showEditIcon = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(imageRefreshTriggerProvider);

    return GestureDetector(
      onTap: producto.estaAgotado ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.zero,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildProductImage(),
                  if (producto.estaAgotado)
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.zero,
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.block, color: Colors.white, size: 32),
                            SizedBox(height: 4),
                            Text(
                              'AGOTADO',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (producto.stockBajo)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade700,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.warning,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Stock: ${producto.stockActual}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (showEditIcon)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.zero,
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  if (producto.esAlergenico)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          borderRadius: BorderRadius.zero,
                        ),
                        child: const Icon(
                          Icons.warning_amber,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        producto.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (producto.descripcion != null)
                      Text(
                        producto.descripcion!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _formatearPrecio(producto),
                            style: TextStyle(
                              fontSize: producto.tieneRangoPrecios
                                  ? 12
                                  : (producto.precioExtras > 0 ? 14 : 18),
                              fontWeight: FontWeight.bold,
                              color: producto.precioExtras > 0
                                  ? Colors.purple.shade700
                                  : AppColors.secondary,
                            ),
                          ),
                        ),
                        if (producto.tieneOpciones)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (producto.ingredientes?.isNotEmpty ?? false)
                                  Icon(
                                    Icons.restaurant_menu,
                                    size: 12,
                                    color: Colors.green.shade700,
                                  ),
                                if (producto.extras?.isNotEmpty ?? false) ...[
                                  if (producto.ingredientes?.isNotEmpty ??
                                      false)
                                    const SizedBox(width: 4),
                                  Icon(
                                    Icons.add_circle,
                                    size: 12,
                                    color: Colors.purple.shade700,
                                  ),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    if (producto.imagenUrl != null && producto.imagenUrl!.isNotEmpty) {
      if (producto.imagenUrl!.startsWith('products/')) {
        final base64 = imageStorageService.getBase64FromPath(
          producto.imagenUrl!,
        );
        if (base64.isNotEmpty) {
          return Image.memory(
            base64Decode(base64),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => _buildPlaceholder(),
          );
        }
      } else if (producto.imagenUrl!.startsWith('http')) {
        return Image.network(
          producto.imagenUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        );
      }
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.primary.withOpacity(0.1),
      child: const Center(
        child: Icon(Icons.restaurant, size: 40, color: AppColors.primary),
      ),
    );
  }

  String _formatearPrecio(Producto producto) {
    if (producto.esVariable &&
        producto.variantes != null &&
        producto.variantes!.length > 1) {
      final precios = producto.variantes!.map((v) => v.precio).toList()..sort();
      return '${precios.first.toStringAsFixed(2)}€ - ${precios.last.toStringAsFixed(2)}€';
    }
    return '${producto.precioTotal.toStringAsFixed(2)} €';
  }
}

extension _ProductoExtension on Producto {
  bool get tieneOpciones =>
      (ingredientes?.isNotEmpty ?? false) || (extras?.isNotEmpty ?? false);

  bool get tieneRangoPrecios =>
      esVariable && variantes != null && variantes!.isNotEmpty;
}
