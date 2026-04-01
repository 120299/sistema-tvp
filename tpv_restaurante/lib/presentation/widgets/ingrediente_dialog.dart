import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/services/ingredientes_extras_service.dart';

class IngredienteDialog extends ConsumerStatefulWidget {
  final IngredienteProducto? ingrediente;

  const IngredienteDialog({super.key, this.ingrediente});

  @override
  ConsumerState<IngredienteDialog> createState() => _IngredienteDialogState();
}

class _IngredienteDialogState extends ConsumerState<IngredienteDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(
      text: widget.ingrediente?.nombre ?? '',
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.ingrediente != null;
    final ingredientesExistentes = ref.read(ingredientesGlobalesProvider);

    return AlertDialog(
      title: Text(esEdicion ? 'Editar Ingrediente' : 'Nuevo Ingrediente'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del ingrediente',
                hintText: 'Ej: Lechuga, Tomate, Cebolla',
                prefixIcon: Icon(Icons.restaurant),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es obligatorio';
                }
                final existe = ingredientesExistentes.any(
                  (i) =>
                      i.nombre.toLowerCase() == value.trim().toLowerCase() &&
                      (widget.ingrediente == null ||
                          i.id != widget.ingrediente!.id),
                );
                if (existe) {
                  return 'Ya existe un ingrediente con este nombre';
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
      final ingrediente = IngredienteProducto(
        id: widget.ingrediente?.id ?? const Uuid().v4(),
        nombre: _nombreController.text.trim(),
      );

      if (widget.ingrediente != null) {
        ref.read(ingredientesGlobalesProvider.notifier).actualizar(ingrediente);
      } else {
        ref.read(ingredientesGlobalesProvider.notifier).agregar(ingrediente);
      }

      Navigator.pop(context, ingrediente);
    }
  }
}
