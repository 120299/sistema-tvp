import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/services/image_storage_service.dart';
import '../../data/services/ingredientes_extras_service.dart';
import '../providers/providers.dart';
import 'ingrediente_dialog.dart';
import 'extra_dialog.dart';

class ProductoDialog extends ConsumerStatefulWidget {
  final Producto? producto;

  const ProductoDialog({super.key, this.producto});

  @override
  ConsumerState<ProductoDialog> createState() => _ProductoDialogState();
}

class _VarianteDialog extends StatefulWidget {
  final VarianteProducto? variante;
  final ValueChanged<VarianteProducto> onGuardar;
  const _VarianteDialog({Key? key, this.variante, required this.onGuardar})
    : super(key: key);

  @override
  State<_VarianteDialog> createState() => _VarianteDialogState();
}

class _VarianteDialogState extends State<_VarianteDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _precioController;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(
      text: widget.variante?.nombre ?? '',
    );
    _precioController = TextEditingController(
      text: widget.variante?.precio.toString() ?? '0',
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.variante != null;
    return AlertDialog(
      title: Text(esEdicion ? 'Editar Variante' : 'Nueva Variante'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Nombre obligatorio' : null,
            ),
            TextFormField(
              controller: _precioController,
              decoration: const InputDecoration(labelText: 'Precio'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Precio obligatorio';
                if (double.tryParse(v) == null) return 'Precio inválido';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final v = VarianteProducto(
                id: widget.variante?.id ?? 'var_${const Uuid().v4()}',
                nombre: _nombreController.text.trim(),
                precio: double.parse(_precioController.text),
              );
              widget.onGuardar(v);
              Navigator.pop(context);
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class VarianteDialog extends StatefulWidget {
  final ValueChanged<VarianteProducto> onGuardar;
  const VarianteDialog({Key? key, required this.onGuardar}) : super(key: key);

  @override
  State<VarianteDialog> createState() => _VarianteDialogStatePublic();
}

class _VarianteDialogStatePublic extends State<VarianteDialog> {
  final _formKey = GlobalKey<FormState>();
  String _nombre = '';
  double _precio = 0.0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva Variante'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Nombre'),
              onChanged: (v) => _nombre = v,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Nombre obligatorio' : null,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Precio'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (v) => _precio = double.tryParse(v) ?? 0,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Precio obligatorio';
                if (double.tryParse(v) == null) return 'Precio inválido';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final v = VarianteProducto(
                id: 'var_${Uuid().v4()}',
                nombre: _nombre.trim(),
                precio: _precio,
              );
              widget.onGuardar(v);
              Navigator.pop(context);
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _ProductoDialogState extends ConsumerState<ProductoDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _precioController;
  late TextEditingController _precioCompraController;
  late TextEditingController _descripcionController;
  late TextEditingController _codigoBarrasController;
  late TextEditingController _stockController;
  late TextEditingController _stockMinimoController;
  late String _categoriaId;
  late bool _disponible;
  late bool _esAlergenico;
  late bool _esVariable;
  late bool _controlStock;
  List<VarianteProducto> _variantes = [];
  List<IngredienteProducto> _ingredientes = [];
  List<ExtraProducto> _extras = [];

  String? _localImageBase64;
  String? _currentImagePath;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(
      text: widget.producto?.nombre ?? '',
    );
    _precioController = TextEditingController(
      text: widget.producto?.precio.toStringAsFixed(2) ?? '',
    );
    _precioCompraController = TextEditingController(
      text: widget.producto?.precioCompra?.toStringAsFixed(2) ?? '',
    );
    _descripcionController = TextEditingController(
      text: widget.producto?.descripcion ?? '',
    );
    _codigoBarrasController = TextEditingController(
      text: widget.producto?.codigoBarras ?? '',
    );
    _stockController = TextEditingController(
      text: widget.producto?.stockActual?.toString() ?? '',
    );
    _stockMinimoController = TextEditingController(
      text: widget.producto?.stockMinimo?.toString() ?? '5',
    );
    _categoriaId = widget.producto?.categoriaId ?? 'cafes';
    _disponible = widget.producto?.disponible ?? true;
    _esAlergenico = widget.producto?.esAlergenico ?? false;
    _esVariable = widget.producto?.esVariable ?? false;
    _controlStock = widget.producto?.controlStock ?? false;
    _variantes = List.from(widget.producto?.variantes ?? []);
    _ingredientes = List.from(widget.producto?.ingredientes ?? []);
    _extras = List.from(widget.producto?.extras ?? []);

    if (widget.producto?.imagenUrl != null &&
        widget.producto!.imagenUrl!.startsWith('products/')) {
      _currentImagePath = widget.producto!.imagenUrl;
      _loadLocalImage(widget.producto!.imagenUrl!);
    }
  }

  void _loadLocalImage(String imagePath) {
    final base64 = imageStorageService.getBase64FromPath(imagePath);
    if (base64.isNotEmpty) {
      setState(() => _localImageBase64 = base64);
    }
  }

  void _agregarVariante() {
    showDialog(
      context: context,
      builder: (ctx) => _VarianteDialog(
        onGuardar: (variante) {
          setState(() => _variantes.add(variante));
        },
      ),
    );
  }

  void _eliminarVariante(int index) {
    setState(() => _variantes.removeAt(index));
  }

  void _editarVariante(int index) {
    final variante = _variantes[index];
    showDialog(
      context: context,
      builder: (ctx) => _VarianteDialog(
        variante: variante,
        onGuardar: (varianteEditada) {
          setState(() => _variantes[index] = varianteEditada);
        },
      ),
    );
  }

  void _agregarIngrediente() async {
    final resultado = await showDialog<IngredienteProducto>(
      context: context,
      builder: (ctx) => const IngredienteDialog(),
    );
    if (resultado != null) {
      setState(() => _ingredientes.add(resultado));
    }
  }

  void _eliminarIngrediente(int index) {
    setState(() => _ingredientes.removeAt(index));
  }

  void _agregarExtra() async {
    final resultado = await showDialog<ExtraProducto>(
      context: context,
      builder: (ctx) => const ExtraDialog(),
    );
    if (resultado != null) {
      setState(() => _extras.add(resultado));
    }
  }

  void _eliminarExtra(int index) {
    setState(() => _extras.removeAt(index));
  }

  void _editarExtra(int index) async {
    final extra = _extras[index];
    final resultado = await showDialog<ExtraProducto>(
      context: context,
      builder: (ctx) => ExtraDialog(extra: extra),
    );
    if (resultado != null) {
      setState(() => _extras[index] = resultado);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    _precioCompraController.dispose();
    _descripcionController.dispose();
    _codigoBarrasController.dispose();
    _stockController.dispose();
    _stockMinimoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.producto != null;
    final categorias = ref.watch(categoriasProvider);

    return Dialog(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Container(
          width: 700,
          constraints: const BoxConstraints(maxHeight: 800),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(esEdicion),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildImagePreview(),
                        const SizedBox(height: 20),
                        _buildBasicInfo(),
                        const SizedBox(height: 20),
                        _buildPricesRow(),
                        const SizedBox(height: 20),
                        _buildCategoryAndStock(categorias),
                        const SizedBox(height: 20),
                        _buildStockSection(),
                        const SizedBox(height: 20),
                        _buildOptionalFields(),
                        const SizedBox(height: 20),
                        _buildIngredientesSection(),
                        const SizedBox(height: 20),
                        _buildExtrasSection(),
                      ],
                    ),
                  ),
                ),
              ),
              _buildActions(esEdicion),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool esEdicion) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.zero,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.zero,
            ),
            child: Icon(
              esEdicion ? Icons.edit : Icons.add_circle,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  esEdicion ? 'Editar Producto' : 'Nuevo Producto',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  esEdicion
                      ? 'Actualiza los datos del producto'
                      : 'Completa los datos del nuevo producto',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
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
    );
  }

  Widget _buildImagePreview() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _seleccionarImagen,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.zero,
                border: Border.all(color: Colors.grey.shade200, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.zero,
                child: _localImageBase64 != null
                    ? Image.memory(
                        base64Decode(_localImageBase64!),
                        fit: BoxFit.cover,
                      )
                    : _buildImagePlaceholder(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _seleccionarImagen,
                icon: const Icon(Icons.photo_camera, size: 18),
                label: const Text('Seleccionar Imagen'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              if (_localImageBase64 != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _localImageBase64 = null;
                      _currentImagePath = null;
                    });
                  },
                  icon: const Icon(Icons.delete, color: AppColors.error),
                  tooltip: 'Eliminar imagen',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _seleccionarImagen() async {
    final XFile? imagen = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 80,
    );

    if (imagen != null) {
      final Uint8List bytes = await imagen.readAsBytes();
      setState(() => _localImageBase64 = base64Encode(bytes));
    }
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey.shade400),
        const SizedBox(height: 8),
        Text(
          'Toca para agregar',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información básica',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nombreController,
          decoration: const InputDecoration(
            labelText: 'Nombre del producto *',
            hintText: 'Ej: Hamburguesa Especial',
            prefixIcon: Icon(Icons.restaurant_menu),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'El nombre es obligatorio';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descripcionController,
          decoration: const InputDecoration(
            labelText: 'Descripción',
            hintText: 'Breve descripción del producto',
            prefixIcon: Icon(Icons.description),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildPricesRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Precios',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _precioController,
                decoration: const InputDecoration(
                  labelText: 'Precio venta *',
                  prefixIcon: Icon(Icons.sell),
                  suffixText: '€',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Obligatorio';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Inválido';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _precioCompraController,
                decoration: const InputDecoration(
                  labelText: 'Precio coste',
                  prefixIcon: Icon(Icons.shopping_cart),
                  suffixText: '€',
                  hintText: '0.00',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryAndStock(List<CategoriaProducto> categorias) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categoría y disponibilidad',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                value: _categoriaId,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  prefixIcon: Icon(Icons.category),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                ),
                items: categorias.map((cat) {
                  return DropdownMenuItem(
                    value: cat.id,
                    child: SizedBox(
                      width: 200,
                      child: Row(
                        children: [
                          Text(cat.icono, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              cat.nombre,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _categoriaId = value);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      _disponible ? Icons.check_circle : Icons.cancel,
                      color: _disponible ? AppColors.success : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Estado',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          Text(
                            _disponible ? 'Disponible' : 'Agotado',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _disponible
                                  ? AppColors.success
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _disponible,
                      onChanged: (value) => setState(() => _disponible = value),
                      activeColor: AppColors.success,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStockSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _controlStock
            ? Colors.orange.withOpacity(0.05)
            : Colors.grey.shade50,
        border: Border.all(
          color: _controlStock
              ? Colors.orange.withOpacity(0.3)
              : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.inventory,
                color: _controlStock ? Colors.orange : Colors.grey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Control de Stock',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Activar para gestionar el inventario',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _controlStock,
                onChanged: (value) => setState(() => _controlStock = value),
                activeThumbColor: Colors.orange,
              ),
            ],
          ),
          if (_controlStock) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _stockController,
                    decoration: const InputDecoration(
                      labelText: 'Stock actual',
                      prefixIcon: Icon(Icons.numbers),
                      hintText: 'Ej: 50',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (_controlStock && (value == null || value.isEmpty)) {
                        return 'Obligatorio si control stock activo';
                      }
                      if (value != null &&
                          value.isNotEmpty &&
                          int.tryParse(value) == null) {
                        return 'Debe ser un número';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _stockMinimoController,
                    decoration: const InputDecoration(
                      labelText: 'Stock mínimo (alerta)',
                      prefixIcon: Icon(Icons.warning_amber),
                      hintText: 'Ej: 5',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionalFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información adicional',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _codigoBarrasController,
                decoration: const InputDecoration(
                  labelText: 'Código de barras',
                  prefixIcon: Icon(Icons.qr_code),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.zero,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: _esAlergenico ? AppColors.warning : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Alérgenos',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            _esAlergenico ? 'Contiene' : 'Sin alérgenos',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _esAlergenico
                                  ? AppColors.warning
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _esAlergenico,
                      onChanged: (value) =>
                          setState(() => _esAlergenico = value),
                      activeThumbColor: AppColors.warning,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildVariableSection(),
      ],
    );
  }

  Widget _buildVariableSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _esVariable
            ? AppColors.primary.withOpacity(0.05)
            : Colors.grey.shade50,
        border: Border.all(
          color: _esVariable
              ? AppColors.primary.withOpacity(0.3)
              : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune,
                color: _esVariable ? AppColors.primary : Colors.grey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Producto Variable',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Permite crear variantes (ej: tamaños, sabores)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _esVariable,
                onChanged: (value) => setState(() {
                  _esVariable = value;
                  if (!value) {
                    _variantes.clear();
                  }
                }),
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),
          if (_esVariable) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Variantes',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _agregarVariante,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Añadir'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_variantes.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.zero,
                ),
                child: Center(
                  child: Text(
                    'No hay variantes. Añade al menos una.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 150),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _variantes.length,
                  itemBuilder: (context, index) {
                    final variante = _variantes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(variante.nombre),
                        subtitle: Text(
                          '${variante.precio.toStringAsFixed(2)} €',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: AppColors.primary,
                              ),
                              onPressed: () => _editarVariante(index),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppColors.error,
                              ),
                              onPressed: () => _eliminarVariante(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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
        color: Colors.green.withOpacity(0.05),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant_menu, color: Colors.green),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ingredientes',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Ingredientes incluidos (cliente puede quitarlos)',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _agregarIngrediente,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Añadir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_ingredientes.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.zero,
              ),
              child: Center(
                child: Text(
                  'Sin ingredientes. Añade los ingredientes que lleva el producto.',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _ingredientes.asMap().entries.map((entry) {
                final index = entry.key;
                final ingrediente = entry.value;
                return Chip(
                  label: Text(ingrediente.nombre),
                  backgroundColor: Colors.green.shade50,
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => _eliminarIngrediente(index),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildExtrasSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.05),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.add_circle, color: Colors.purple),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Extras',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Extras con precio adicional',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _agregarExtra,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Añadir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_extras.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.zero,
              ),
              child: Center(
                child: Text(
                  'Sin extras. Añade extras con precio adicional.',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ),
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _extras.length,
                itemBuilder: (context, index) {
                  final extra = _extras[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.zero,
                        ),
                        child: const Icon(
                          Icons.add_circle,
                          color: Colors.purple,
                          size: 20,
                        ),
                      ),
                      title: Text(extra.nombre),
                      subtitle: Text(
                        '+${extra.precio.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: AppColors.primary,
                            ),
                            onPressed: () => _editarExtra(index),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.error,
                            ),
                            onPressed: () => _eliminarExtra(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActions(bool esEdicion) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.zero,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (esEdicion)
            TextButton.icon(
              onPressed: _eliminar,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Eliminar'),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
            ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _guardar,
            icon: Icon(esEdicion ? Icons.save : Icons.add),
            label: Text(esEdicion ? 'Guardar Cambios' : 'Crear Producto'),
          ),
        ],
      ),
    );
  }

  Future<void> _guardar() async {
    if (_formKey.currentState!.validate()) {
      if (_esVariable && _variantes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Los productos variables deben tener al menos una variante',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final productoId = widget.producto?.id ?? 'prod_${const Uuid().v4()}';

      String? imagenPath;
      if (_localImageBase64 != null) {
        imagenPath = await imageStorageService.saveImageFromBase64(
          productoId,
          _localImageBase64!,
        );
      }

      int? stockActual;
      if (_controlStock && _stockController.text.isNotEmpty) {
        stockActual = int.tryParse(_stockController.text);
      }

      int? stockMinimo;
      if (_controlStock && _stockMinimoController.text.isNotEmpty) {
        stockMinimo = int.tryParse(_stockMinimoController.text);
      }

      final producto = Producto(
        id: productoId,
        nombre: _nombreController.text.trim(),
        precio: double.parse(_precioController.text),
        categoriaId: _categoriaId,
        imagenUrl: imagenPath ?? _currentImagePath,
        disponible: _disponible,
        descripcion: _descripcionController.text.isEmpty
            ? null
            : _descripcionController.text.trim(),
        precioCompra: _precioCompraController.text.isEmpty
            ? null
            : double.tryParse(_precioCompraController.text),
        esAlergenico: _esAlergenico,
        codigoBarras: _codigoBarrasController.text.isEmpty
            ? null
            : _codigoBarrasController.text.trim(),
        esVariable: _esVariable,
        variantes: _esVariable ? _variantes : null,
        ingredientes: _ingredientes.isNotEmpty ? _ingredientes : null,
        extras: _extras.isNotEmpty ? _extras : null,
        stockActual: stockActual,
        stockMinimo: stockMinimo,
        controlStock: _controlStock,
      );

      if (widget.producto != null) {
        await ref.read(productosProvider.notifier).actualizar(producto);
        final productos = ref.read(productosProvider);
        final actualizado = productos
            .where((p) => p.id == producto.id)
            .firstOrNull;

        if (actualizado == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error: No se pudo guardar el producto'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      } else {
        await ref.read(productosProvider.notifier).agregar(producto);
      }

      triggerImageRefresh(ref);

      await Future.delayed(const Duration(milliseconds: 100));

      if (mounted) {
        Navigator.pop(context, producto);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.producto != null
                  ? 'Producto actualizado'
                  : 'Producto creado',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _eliminar() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.error),
            SizedBox(width: 12),
            Text('Confirmar eliminación'),
          ],
        ),
        content: Text(
          '¿Eliminar "${widget.producto!.nombre}"?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(productosProvider.notifier)
                  .eliminar(widget.producto!.id);
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Producto eliminado'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
