import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/services/ingredientes_extras_service.dart';

class ExtraDialog extends ConsumerStatefulWidget {
  final ExtraProducto? extra;

  const ExtraDialog({super.key, this.extra});

  @override
  ConsumerState<ExtraDialog> createState() => _ExtraDialogState();
}

class _ExtraDialogState extends ConsumerState<ExtraDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _precioController;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.extra?.nombre ?? '');
    _precioController = TextEditingController(
      text: widget.extra?.precio.toStringAsFixed(2) ?? '',
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
    final esEdicion = widget.extra != null;
    final extrasExistentes = ref.read(extrasGlobalesProvider);

    return AlertDialog(
      title: Text(esEdicion ? 'Editar Extra' : 'Nuevo Extra'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del extra',
                hintText: 'Ej: Queso extra, Bacon',
                prefixIcon: Icon(Icons.add_circle_outline),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es obligatorio';
                }
                final existe = extrasExistentes.any(
                  (e) =>
                      e.nombre.toLowerCase() == value.trim().toLowerCase() &&
                      (widget.extra == null || e.id != widget.extra!.id),
                );
                if (existe) {
                  return 'Ya existe un extra con este nombre';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _precioController,
              decoration: const InputDecoration(
                labelText: 'Precio extra (€)',
                hintText: '1.50',
                prefixIcon: Icon(Icons.euro),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El precio es obligatorio';
                }
                final precio = double.tryParse(value.replaceAll(',', '.'));
                if (precio == null || precio < 0) {
                  return 'Precio no válido';
                }
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
          onPressed: _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: Text(esEdicion ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      final precio = double.parse(_precioController.text.replaceAll(',', '.'));

      final extra = ExtraProducto(
        id: widget.extra?.id ?? const Uuid().v4(),
        nombre: _nombreController.text.trim(),
        precio: precio,
      );

      if (widget.extra != null) {
        ref.read(extrasGlobalesProvider.notifier).actualizar(extra);
      } else {
        ref.read(extrasGlobalesProvider.notifier).agregar(extra);
      }

      Navigator.pop(context, extra);
    }
  }
}
