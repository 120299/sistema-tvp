import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';

/// Diálogo para seleccionar una variante de un producto variable
class SeleccionVarianteDialog extends StatelessWidget {
  final Producto producto;
  final ValueChanged<VarianteProducto> onVarianteSeleccionada;

  const SeleccionVarianteDialog({
    super.key,
    required this.producto,
    required this.onVarianteSeleccionada,
  });

  @override
  Widget build(BuildContext context) {
    final variantes = producto.variantes ?? [];

    return Dialog(
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: AppColors.primary),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          producto.nombre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Selecciona una variante',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Lista de variantes
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                itemCount: variantes.length,
                itemBuilder: (context, index) {
                  final variante = variantes[index];
                  final diferencia = variante.precio - producto.precio;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    child: InkWell(
                      onTap: () {
                        onVarianteSeleccionada(variante);
                        Navigator.pop(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.zero,
                              ),
                              child: const Icon(
                                Icons.tune,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    variante.nombre,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (variante.precioExtra != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Precio extra: +${variante.precioExtra!.toStringAsFixed(2)} €',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${variante.precio.toStringAsFixed(2)} €',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.secondary,
                                  ),
                                ),
                                if (diferencia != 0)
                                  Text(
                                    diferencia > 0
                                        ? '+${diferencia.toStringAsFixed(2)} €'
                                        : '${diferencia.toStringAsFixed(2)} €',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: diferencia > 0
                                          ? Colors.orange.shade700
                                          : Colors.green.shade700,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Precio base: ${producto.precio.toStringAsFixed(2)} €',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
