import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';

class ProductoPersonalizacionDialog extends StatefulWidget {
  final Producto producto;
  final Function(PedidoItem) onConfirm;
  final PedidoItem? itemInicial;

  const ProductoPersonalizacionDialog({
    super.key,
    required this.producto,
    required this.onConfirm,
    this.itemInicial,
  });

  @override
  State<ProductoPersonalizacionDialog> createState() =>
      _ProductoPersonalizacionDialogState();
}

class _ProductoPersonalizacionDialogState
    extends State<ProductoPersonalizacionDialog> {
  VarianteProducto? _varianteSeleccionada;
  final Set<String> _ingredientesQuitados = {};
  final Set<String> _extrasSeleccionados = {};
  late TextEditingController _notasController;

  @override
  void initState() {
    super.initState();
    _notasController = TextEditingController(text: widget.itemInicial?.notas);

    if (widget.itemInicial != null) {
      final item = widget.itemInicial!;
      if (item.varianteId != null && widget.producto.variantes != null) {
        _varianteSeleccionada = widget.producto.variantes!
            .where((v) => v.id == item.varianteId)
            .firstOrNull;
      }
      if (item.ingredientesQuitados != null) {
        for (final nombre in item.ingredientesQuitados!) {
          final ingrediente = widget.producto.ingredientes
              ?.where((i) => i.nombre == nombre)
              .firstOrNull;
          if (ingrediente != null) {
            _ingredientesQuitados.add(ingrediente.id);
          }
        }
      }
      if (item.extrasSeleccionados != null) {
        for (final extra in item.extrasSeleccionados!) {
          _extrasSeleccionados.add(extra.id);
        }
      }
    }
  }

  @override
  void dispose() {
    _notasController.dispose();
    super.dispose();
  }

  bool get _esVariable => widget.producto.esVariable;
  bool get _tieneVariantes =>
      widget.producto.variantes != null &&
      widget.producto.variantes!.isNotEmpty;
  bool get _tieneIngredientes =>
      widget.producto.ingredientes != null &&
      widget.producto.ingredientes!.isNotEmpty;
  bool get _tieneExtras =>
      widget.producto.extras != null && widget.producto.extras!.isNotEmpty;

  bool get _puedeConfirmar {
    if (_esVariable && _tieneVariantes && _varianteSeleccionada == null) {
      return false;
    }
    return true;
  }

  String? get _mensajeError {
    if (_esVariable && _tieneVariantes && _varianteSeleccionada == null) {
      return 'Por favor, selecciona una opción';
    }
    return null;
  }

  double get _precioBase {
    if (_varianteSeleccionada != null) {
      return _varianteSeleccionada!.precio;
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

  String _getNombreCompleto() {
    String nombre = widget.producto.nombre;
    if (_varianteSeleccionada != null) {
      nombre += ' - ${_varianteSeleccionada!.nombre}';
    }
    return nombre;
  }

  void _confirmar() {
    if (!_puedeConfirmar) return;

    List<ExtraProducto> extrasLista = [];
    if (_extrasSeleccionados.isNotEmpty && widget.producto.extras != null) {
      extrasLista = widget.producto.extras!
          .where((e) => _extrasSeleccionados.contains(e.id))
          .toList();
    }

    List<String> ingredientesQuitadosLista = [];
    if (_ingredientesQuitados.isNotEmpty &&
        widget.producto.ingredientes != null) {
      ingredientesQuitadosLista = widget.producto.ingredientes!
          .where((i) => _ingredientesQuitados.contains(i.id))
          .map((i) => i.nombre)
          .toList();
    }

    final item = PedidoItem(
      id: widget.itemInicial?.id ?? 'item_${const Uuid().v4()}',
      productoId: widget.producto.id,
      varianteId: _varianteSeleccionada?.id,
      productoNombre: _getNombreCompleto(),
      cantidad: widget.itemInicial?.cantidad ?? 1,
      precioUnitario: _precioBase,
      notas: _notasController.text.isNotEmpty ? _notasController.text : null,
      ingredientesQuitados: ingredientesQuitadosLista.isNotEmpty
          ? ingredientesQuitadosLista
          : null,
      extrasSeleccionados: extrasLista.isNotEmpty ? extrasLista : null,
    );

    widget.onConfirm(item);
    Navigator.pop(context, item);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 700),
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
                    if (_esVariable && _tieneVariantes)
                      _buildVariantesSection(),
                    if ((_esVariable && _tieneVariantes) &&
                        (_tieneIngredientes || _tieneExtras))
                      const SizedBox(height: 16),
                    if (_tieneIngredientes) _buildIngredientesSection(),
                    if (_tieneIngredientes && _tieneExtras)
                      const SizedBox(height: 16),
                    if (_tieneExtras) _buildExtrasSection(),
                    const SizedBox(height: 16),
                    _buildNotasSection(),
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

  Widget _buildHeader() {
    String? nombreVariante = _varianteSeleccionada?.nombre;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: AppColors.primary),
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

  Widget _buildVariantesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.straighten, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'TAMAÑO / PRESENTACIÓN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
              const Text(' *', style: TextStyle(color: Colors.red)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.producto.variantes!.map((variante) {
              final isSelected = _varianteSeleccionada?.id == variante.id;
              return InkWell(
                onTap: () {
                  setState(() {
                    _varianteSeleccionada = variante;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.shade100 : Colors.white,
                    borderRadius: BorderRadius.zero,
                    border: Border.all(
                      color: isSelected
                          ? Colors.blue.shade600
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        variante.nombre,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${variante.precio.toStringAsFixed(2)}€',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (_mensajeError != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.zero,
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red.shade700, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    _mensajeError!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
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
            children: (widget.producto.ingredientes ?? []).map((ingrediente) {
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
          ...(widget.producto.extras ?? []).map((extra) {
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

  Widget _buildNotasSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note, color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'NOTAS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notasController,
            decoration: InputDecoration(
              hintText: 'Ej: Sin hielo, extra sal, etc.',
              border: OutlineInputBorder(borderRadius: BorderRadius.zero),
              contentPadding: const EdgeInsets.all(12),
            ),
            maxLines: 2,
          ),
        ],
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
              color: AppColors.primary.withValues(alpha: 0.1),
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
                  onPressed: _puedeConfirmar ? _confirmar : null,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: Text('Añadir ${_precioTotal.toStringAsFixed(2)}€'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getIngredientesQuitadosTexto() {
    if (widget.producto.ingredientes == null) return '';
    return widget.producto.ingredientes!
        .where((i) => _ingredientesQuitados.contains(i.id))
        .map((i) => i.nombre)
        .join(', ');
  }

  String _getExtrasSeleccionadosTexto() {
    if (widget.producto.extras == null) return '';
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
