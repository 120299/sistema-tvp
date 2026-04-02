import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../providers/providers.dart';

class CategoriaDialog extends ConsumerStatefulWidget {
  final CategoriaProducto? categoria;

  const CategoriaDialog({super.key, this.categoria});

  @override
  ConsumerState<CategoriaDialog> createState() => _CategoriaDialogState();
}

class _CategoriaDialogState extends ConsumerState<CategoriaDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late Color _color;
  String? _imagenBase64;
  String? _imagenUrlActual;
  final ImagePicker _imagePicker = ImagePicker();

  static const List<Color> _coloresDisponibles = [
    Color(0xFF8B4513),
    Color(0xFF2196F3),
    Color(0xFFFF5722),
    Color(0xFFE91E63),
    Color(0xFF7B1FA2),
    Color(0xFFFFC107),
    Color(0xFF00BCD4),
    Color(0xFF795548),
    Color(0xFF4CAF50),
    Color(0xFF607D8B),
    Color(0xFFE53935),
    Color(0xFF1E88E5),
  ];

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(
      text: widget.categoria?.nombre ?? '',
    );
    _color = widget.categoria?.color ?? _coloresDisponibles.first;
    _imagenUrlActual = widget.categoria?.imagenUrl;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagen() async {
    final XFile? imagen = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (imagen != null) {
      final Uint8List bytes = await imagen.readAsBytes();
      setState(() => _imagenBase64 = base64Encode(bytes));
    }
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.categoria != null;

    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(esEdicion),
              const SizedBox(height: 24),
              _buildImageSection(),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la categoría',
                  prefixIcon: Icon(Icons.label),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty == true ? 'Obligatorio' : null,
              ),
              const SizedBox(height: 20),
              _buildColorSelector(),
              const SizedBox(height: 24),
              _buildActions(esEdicion),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool esEdicion) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.zero,
          ),
          child: _imagenBase64 != null
              ? ClipRRect(
                  borderRadius: BorderRadius.zero,
                  child: Image.memory(
                    base64Decode(_imagenBase64!),
                    width: 24,
                    height: 24,
                    fit: BoxFit.cover,
                  ),
                )
              : _imagenUrlActual != null
              ? Image.network(
                  _imagenUrlActual!,
                  width: 24,
                  height: 24,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.category, size: 24, color: _color),
                )
              : Icon(Icons.category, size: 24, color: _color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                esEdicion ? 'Editar Categoría' : 'Nueva Categoría',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                esEdicion ? 'Actualiza los datos' : 'Crea una nueva categoría',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Imagen de la categoría',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _seleccionarImagen,
            child: Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.zero,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _imagenBase64 != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.zero,
                          child: Image.memory(
                            base64Decode(_imagenBase64!),
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            onPressed: () {
                              setState(() => _imagenBase64 = null);
                            },
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    )
                  : _imagenUrlActual != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          _imagenUrlActual!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                size: 40,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Imagen no disponible',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            onPressed: () {
                              setState(() => _imagenUrlActual = null);
                            },
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 40,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Toca para seleccionar imagen',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Color:', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _coloresDisponibles.map((color) {
            return GestureDetector(
              onTap: () => setState(() => _color = color),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.zero,
                  border: _color == color
                      ? Border.all(color: Colors.black, width: 3)
                      : null,
                ),
                child: _color == color
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActions(bool esEdicion) {
    return Row(
      children: [
        if (esEdicion)
          TextButton.icon(
            onPressed: _eliminar,
            icon: const Icon(Icons.delete),
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
          label: Text(esEdicion ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }

  void _guardar() async {
    if (_formKey.currentState!.validate()) {
      String? imagenUrl;

      if (_imagenBase64 != null) {
        imagenUrl = 'data:image/png;base64,$_imagenBase64';
      } else if (_imagenUrlActual != null) {
        imagenUrl = _imagenUrlActual;
      }

      final categoria = CategoriaProducto(
        id: widget.categoria?.id ?? 'cat_${const Uuid().v4()}',
        nombre: _nombreController.text.trim(),
        icono: '',
        color: _color,
        imagenUrl: imagenUrl,
        orden: widget.categoria?.orden ?? 0,
      );

      if (widget.categoria != null) {
        await ref.read(categoriasProvider.notifier).actualizar(categoria);
      } else {
        await ref.read(categoriasProvider.notifier).agregar(categoria);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.categoria != null
                  ? 'Categoría actualizada'
                  : 'Categoría creada',
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
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppColors.error),
            SizedBox(width: 12),
            Text('Eliminar Categoría'),
          ],
        ),
        content: Text(
          '¿Eliminar "${widget.categoria!.nombre}"?\n\nLos productos de esta categoría quedarán sin categoría.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref
                  .read(categoriasProvider.notifier)
                  .eliminar(widget.categoria!.id);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Categoría eliminada'),
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
