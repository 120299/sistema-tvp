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
  late TextEditingController _buscadorIngredientesController;
  late TextEditingController _buscadorExtrasController;
  final ValueNotifier<String> _busquedaIngredientes = ValueNotifier<String>('');
  final ValueNotifier<String> _busquedaExtras = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    _notasController = TextEditingController(text: widget.itemInicial?.notas);
    _buscadorIngredientesController = TextEditingController();
    _buscadorExtrasController = TextEditingController();

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
    _buscadorIngredientesController.dispose();
    _buscadorExtrasController.dispose();
    _busquedaIngredientes.dispose();
    _busquedaExtras.dispose();
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

    Navigator.pop(context, item);
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.itemInicial != null;

    return Dialog(
      backgroundColor: Colors.white,
      elevation: 8,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Material(
        color: Colors.white,
        child: Container(
          width: 500,
          constraints: const BoxConstraints(maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(isEditing: isEditing),
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
              _buildFooter(isEditing: isEditing),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({bool isEditing = false}) {
    String? nombreVariante = _varianteSeleccionada?.nombre;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: AppColors.primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.zero,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                child: const Icon(
                  Icons.fastfood,
                  color: Colors.white,
                  size: 32,
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
    final variantes = widget.producto.variantes!;

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
          LayoutBuilder(
            builder: (context, constraints) {
              final anchoPorItem = constraints.maxWidth / 2;

              return Wrap(
                spacing: 0,
                runSpacing: 0,
                children: variantes.map((variante) {
                  final isSelected = _varianteSeleccionada?.id == variante.id;

                  return SizedBox(
                    width: anchoPorItem,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _varianteSeleccionada = variante;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue.shade600
                              : Colors.white,
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.blue.shade300,
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              variante.nombre,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.blue.shade700,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${variante.precio.toStringAsFixed(2)}€',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
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
    final ingredientesTodos = widget.producto.ingredientes ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant_menu, color: Colors.black, size: 20),
              const SizedBox(width: 8),
              const Text(
                'INGREDIENTES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              Text(
                '(quitar)',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _buscadorIngredientesController,
            decoration: InputDecoration(
              hintText: 'Buscar ingrediente...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _buscadorIngredientesController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _buscadorIngredientesController.clear();
                        _busquedaIngredientes.value = '';
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            onChanged: (value) {
              _busquedaIngredientes.value = value.toLowerCase();
            },
          ),
          const SizedBox(height: 12),
          ListenableBuilder(
            listenable: _busquedaIngredientes,
            builder: (context, _) {
              final filtrados = _busquedaIngredientes.value.isEmpty
                  ? ingredientesTodos
                  : ingredientesTodos
                        .where(
                          (i) => i.nombre.toLowerCase().contains(
                            _busquedaIngredientes.value,
                          ),
                        )
                        .toList();

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: filtrados.map((ingrediente) {
                  final estaQuitado = _ingredientesQuitados.contains(
                    ingrediente.id,
                  );
                  return FilterChip(
                    label: Text(
                      ingrediente.nombre,
                      style: TextStyle(
                        color: Colors.black,
                        decoration: estaQuitado
                            ? TextDecoration.lineThrough
                            : null,
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
                    selectedColor: Colors.grey.shade300,
                    checkmarkColor: Colors.black,
                    backgroundColor: Colors.white,
                  );
                }).toList(),
              );
            },
          ),
          if (_ingredientesQuitados.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.remove_circle, color: Colors.red.shade700, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sin ${_getIngredientesQuitadosTexto()}',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExtrasSection() {
    final extrasTodos = widget.producto.extras ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.add_circle, color: Colors.black, size: 20),
              const SizedBox(width: 8),
              const Text(
                'EXTRAS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              Text(
                '(añadir)',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _buscadorExtrasController,
            decoration: InputDecoration(
              hintText: 'Buscar extra...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _buscadorExtrasController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _buscadorExtrasController.clear();
                        _busquedaExtras.value = '';
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            onChanged: (value) {
              _busquedaExtras.value = value.toLowerCase();
            },
          ),
          const SizedBox(height: 12),
          ListenableBuilder(
            listenable: _busquedaExtras,
            builder: (context, _) {
              final filtrados = _busquedaExtras.value.isEmpty
                  ? extrasTodos
                  : extrasTodos
                        .where(
                          (e) => e.nombre.toLowerCase().contains(
                            _busquedaExtras.value,
                          ),
                        )
                        .toList();

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: filtrados.map((extra) {
                  final seleccionado = _extrasSeleccionados.contains(extra.id);
                  return FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          extra.nombre,
                          style: TextStyle(
                            color: seleccionado ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+${extra.precio.toStringAsFixed(2)}€',
                          style: TextStyle(
                            fontSize: 10,
                            color: seleccionado
                                ? Colors.white70
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    selected: seleccionado,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _extrasSeleccionados.add(extra.id);
                        } else {
                          _extrasSeleccionados.remove(extra.id);
                        }
                      });
                    },
                    selectedColor: AppColors.primary,
                    checkmarkColor: Colors.white,
                    backgroundColor: Colors.white,
                  );
                }).toList(),
              );
            },
          ),
          if (_extrasSeleccionados.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Extras: ${_getExtrasSeleccionadosTexto()}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
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

  Widget _buildFooter({bool isEditing = false}) {
    final String buttonText = isEditing
        ? 'Actualizar ${_precioTotal.toStringAsFixed(2)}€'
        : 'Añadir ${_precioTotal.toStringAsFixed(2)}€';

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
                  icon: Icon(isEditing ? Icons.check : Icons.add_shopping_cart),
                  label: Text(buttonText),
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
}
