import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../providers/providers.dart';

class IngredienteDialog extends ConsumerStatefulWidget {
  final IngredienteProducto? ingrediente;

  const IngredienteDialog({super.key, this.ingrediente});

  @override
  ConsumerState<IngredienteDialog> createState() => _IngredienteDialogState();
}

class _IngredienteDialogState extends ConsumerState<IngredienteDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  String _busqueda = '';

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
    final ingredientesExistentes = ref.watch(ingredientesGlobalesProvider);

    final filtered = _busqueda.isEmpty
        ? ingredientesExistentes
        : ingredientesExistentes
              .where(
                (i) => i.nombre.toLowerCase().contains(_busqueda.toLowerCase()),
              )
              .toList();

    return AlertDialog(
      title: Text(esEdicion ? 'Editar Ingrediente' : 'Nuevo Ingrediente'),
      content: SizedBox(
        width: 400,
        height: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre del ingrediente',
                  hintText: 'Ej: Lechuga, Tomate, Cebolla',
                  prefixIcon: const Icon(Icons.restaurant),
                  suffixIcon: _nombreController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _nombreController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
                textCapitalization: TextCapitalization.words,
                onChanged: (value) => setState(() => _busqueda = value),
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
              const SizedBox(height: 16),
              const Text(
                'O selecciona uno existente:',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            _busqueda.isEmpty
                                ? 'No hay ingredientes'
                                : 'No se encontraron',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final ing = filtered[index];
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.restaurant, size: 20),
                              title: Text(ing.nombre),
                              onTap: () {
                                _nombreController.text = ing.nombre;
                                setState(() => _busqueda = '');
                              },
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
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
          child: Text(esEdicion ? 'Guardar' : 'Añadir'),
        ),
      ],
    );
  }

  void _guardar() {
    if (_formKey.currentState?.validate() ?? false) {
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
