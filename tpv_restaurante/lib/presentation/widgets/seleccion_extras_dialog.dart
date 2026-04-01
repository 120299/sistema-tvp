import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';

class SeleccionExtrasDialog extends StatefulWidget {
  final Producto producto;
  final VarianteProducto? variante;

  const SeleccionExtrasDialog({
    super.key,
    required this.producto,
    this.variante,
  });

  @override
  State<SeleccionExtrasDialog> createState() => _SeleccionExtrasDialogState();
}

class _SeleccionExtrasDialogState extends State<SeleccionExtrasDialog> {
  final Set<String> _ingredientesQuitados = {};
  final Set<String> _extrasSeleccionados = {};

  double get _precioBase {
    if (widget.variante != null) {
      return widget.variante!.precio;
    }
    return widget.producto.precio;
  }

  double get _precioExtras {
    double total = 0;
    for (final extra in widget.producto.extras ?? []) {
      if (_extrasSeleccionados.contains(extra.id)) {
        total += extra.precio;
      }
    }
    return total;
  }

  double get _precioTotal => _precioBase + _precioExtras;

  bool get _tieneIngredientes =>
      widget.producto.ingredientes != null &&
      widget.producto.ingredientes!.isNotEmpty;

  bool get _tieneExtras =>
      widget.producto.extras != null && widget.producto.extras!.isNotEmpty;

  bool get _tieneOpciones => _tieneIngredientes || _tieneExtras;

  @override
  Widget build(BuildContext context) {
    final nombreVariante = widget.variante?.nombre;

    return Dialog(
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(nombreVariante),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_tieneIngredientes) _buildIngredientesSection(),
                    if (_tieneIngredientes && _tieneExtras)
                      const SizedBox(height: 20),
                    if (_tieneExtras) _buildExtrasSection(),
                    if (!_tieneOpciones) _buildSinOpciones(),
                  ],
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String? nombreVariante) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.producto.imagenUrl != null)
                Container(
                  width: 60,
                  height: 60,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.zero,
                    color: Colors.white,
                    image: DecorationImage(
                      image: _getProductImage(),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.producto.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (nombreVariante != null)
                      Text(
                        'Variante: $nombreVariante',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
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
        ],
      ),
    );
  }

  Widget _buildIngredientesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.restaurant_menu,
                color: Colors.green.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'INGREDIENTES (quitar los que no quiera)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.producto.ingredientes!.map((ingrediente) {
              final estaQuitado = _ingredientesQuitados.contains(
                ingrediente.id,
              );
              return FilterChip(
                label: Text(
                  ingrediente.nombre,
                  style: TextStyle(
                    color: estaQuitado ? Colors.grey : Colors.green.shade700,
                    decoration: estaQuitado ? TextDecoration.lineThrough : null,
                  ),
                ),
                selected: !estaQuitado,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _ingredientesQuitados.remove(ingrediente.id);
                    } else {
                      _ingredientesQuitados.add(ingrediente.id);
                    }
                  });
                },
                selectedColor: Colors.green.shade100,
                checkmarkColor: Colors.green.shade700,
                backgroundColor: Colors.white,
              );
            }).toList(),
          ),
          if (_ingredientesQuitados.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.zero,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.remove_circle,
                    color: Colors.red.shade700,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sin ${_getIngredientesQuitadosTexto()}',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExtrasSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add_circle, color: Colors.purple.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'EXTRAS (añadir con coste adicional)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...widget.producto.extras!.map((extra) {
            final seleccionado = _extrasSeleccionados.contains(extra.id);
            return InkWell(
              onTap: () {
                setState(() {
                  if (seleccionado) {
                    _extrasSeleccionados.remove(extra.id);
                  } else {
                    _extrasSeleccionados.add(extra.id);
                  }
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: seleccionado ? Colors.purple.shade100 : Colors.white,
                  borderRadius: BorderRadius.zero,
                  border: Border.all(
                    color: seleccionado
                        ? Colors.purple.shade400
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      seleccionado
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: Colors.purple.shade700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        extra.nombre,
                        style: TextStyle(
                          color: Colors.purple.shade700,
                          fontWeight: seleccionado
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade700,
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Text(
                        '+${extra.precio.toStringAsFixed(2)}€',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          if (_extrasSeleccionados.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Extras seleccionados: ${_getExtrasSeleccionadosTexto()}',
              style: TextStyle(
                color: Colors.purple.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSinOpciones() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.zero,
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.info_outline, color: Colors.grey.shade400, size: 48),
            const SizedBox(height: 12),
            Text(
              'Este producto no tiene ingredientes ni extras configurados',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.zero,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.zero,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Precio base:', style: TextStyle(fontSize: 14)),
                    Text(
                      '${_precioBase.toStringAsFixed(2)}€',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                if (_extrasSeleccionados.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Extras (${_extrasSeleccionados.length}):',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.purple.shade700,
                        ),
                      ),
                      Text(
                        '+${_precioExtras.toStringAsFixed(2)}€',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.purple.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_precioTotal.toStringAsFixed(2)}€',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _confirmar,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Añadir al pedido'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmar() {
    List<ExtraProducto> extrasSeleccionados = [];
    if (_extrasSeleccionados.isNotEmpty) {
      extrasSeleccionados = widget.producto.extras!
          .where((e) => _extrasSeleccionados.contains(e.id))
          .toList();
    }

    List<String> ingredientesQuitados = [];
    if (_ingredientesQuitados.isNotEmpty) {
      ingredientesQuitados = widget.producto.ingredientes!
          .where((i) => _ingredientesQuitados.contains(i.id))
          .map((i) => i.nombre)
          .toList();
    }

    final item = PedidoItem(
      id: 'item_${const Uuid().v4()}',
      productoId: widget.producto.id,
      varianteId: widget.variante?.id,
      productoNombre: widget.producto.nombre,
      cantidad: 1,
      precioUnitario: _precioBase,
      ingredientesQuitados: ingredientesQuitados.isNotEmpty
          ? ingredientesQuitados
          : null,
      extrasSeleccionados: extrasSeleccionados.isNotEmpty
          ? extrasSeleccionados
          : null,
    );

    Navigator.pop(context, item);
  }

  String _getIngredientesQuitadosTexto() {
    return widget.producto.ingredientes!
        .where((i) => _ingredientesQuitados.contains(i.id))
        .map((i) => i.nombre)
        .join(', ');
  }

  String _getExtrasSeleccionadosTexto() {
    return widget.producto.extras!
        .where((e) => _extrasSeleccionados.contains(e.id))
        .map((e) => '+${e.nombre}')
        .join(', ');
  }

  ImageProvider _getProductImage() {
    if (widget.producto.imagenUrl == null) {
      return const AssetImage('assets/images/placeholder.png');
    }

    if (widget.producto.imagenUrl!.startsWith('products/')) {
      return const AssetImage('assets/images/placeholder.png');
    }

    if (widget.producto.imagenUrl!.startsWith('http')) {
      return NetworkImage(widget.producto.imagenUrl!);
    }

    return const AssetImage('assets/images/placeholder.png');
  }
}
