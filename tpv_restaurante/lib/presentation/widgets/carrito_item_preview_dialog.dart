import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';

class CarritoItemPreviewDialog extends StatelessWidget {
  final PedidoItem item;
  final VoidCallback? onEditar;
  final VoidCallback? onEliminar;

  const CarritoItemPreviewDialog({
    super.key,
    required this.item,
    this.onEditar,
    this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final tieneModificaciones =
        (item.ingredientesQuitados?.isNotEmpty ?? false) ||
        (item.extrasSeleccionados?.isNotEmpty ?? false) ||
        (item.notas?.isNotEmpty ?? false);

    return Dialog(
      child: Container(
        width: 450,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductoInfo(),
                    if (tieneModificaciones) ...[
                      const SizedBox(height: 20),
                      _buildModificaciones(),
                    ],
                    const SizedBox(height: 20),
                    _buildCantidadPrecio(),
                  ],
                ),
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: AppColors.primary),
      child: Row(
        children: [
          const Icon(Icons.visibility, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Detalle del Producto',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildProductoInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.zero,
              ),
              child: Text(
                'Cantidad: ${item.cantidad}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          item.productoNombre,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (item.varianteId != null) ...[
          const SizedBox(height: 4),
          Text(
            'Variante seleccionada',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ],
    );
  }

  Widget _buildModificaciones() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MODIFICACIONES',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        if (item.ingredientesQuitados?.isNotEmpty ?? false) ...[
          _buildModificacionItem(
            icon: Icons.remove_circle_outline,
            label: 'Ingredientes quitados',
            items: item.ingredientesQuitados!,
            color: Colors.red.shade700,
          ),
          const SizedBox(height: 12),
        ],
        if (item.extrasSeleccionados?.isNotEmpty ?? false) ...[
          _buildModificacionItem(
            icon: Icons.add_circle_outline,
            label: 'Extras añadidos',
            items: item.extrasSeleccionados!
                .map((e) => '${e.nombre} (+${e.precio.toStringAsFixed(2)}€)')
                .toList(),
            color: Colors.purple.shade700,
          ),
          const SizedBox(height: 12),
        ],
        if (item.notas?.isNotEmpty ?? false) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              border: Border.all(color: Colors.amber.shade200),
              borderRadius: BorderRadius.zero,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.amber.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Notas',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(item.notas!, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildModificacionItem({
    required IconData icon,
    required String label,
    required List<String> items,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(left: 24, top: 4),
              child: Text(item, style: const TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCantidadPrecio() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Precio unitario:', style: TextStyle(fontSize: 14)),
              Text(
                '${item.precioUnitario.toStringAsFixed(2)}€',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Extras:', style: TextStyle(fontSize: 14)),
              Text(
                '+${((item.extrasSeleccionados?.fold<double>(0, (sum, e) => sum + e.precio) ?? 0)).toStringAsFixed(2)}€',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SUBTOTAL:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '${item.subtotal.toStringAsFixed(2)}€',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          if (onEliminar != null)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onEliminar?.call();
                },
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                label: const Text(
                  'Eliminar',
                  style: TextStyle(color: AppColors.error),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
            ),
          if (onEliminar != null) const SizedBox(width: 12),
          if (onEditar != null)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onEditar?.call();
                },
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Editar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          if (onEditar == null && onEliminar == null)
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Cerrar'),
              ),
            ),
        ],
      ),
    );
  }
}
