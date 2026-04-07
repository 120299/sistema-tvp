import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../providers/providers.dart';

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
  String _busqueda = '';
  List<ExtraProducto> _extrasCache = [];

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.extra?.nombre ?? '');
    _precioController = TextEditingController(
      text: widget.extra?.precio.toStringAsFixed(2) ?? '',
    );
    _extrasCache = ref.read(extrasGlobalesProvider);
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
    _extrasCache = ref.watch(extrasGlobalesProvider);

    final filtered = _busqueda.isEmpty
        ? _extrasCache
        : _extrasCache
              .where(
                (e) => e.nombre.toLowerCase().contains(_busqueda.toLowerCase()),
              )
              .toList();

    return AlertDialog(
      title: Text(esEdicion ? 'Editar Extra' : 'Nuevo Extra'),
      content: SizedBox(
        width: 400,
        height: 450,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre del extra',
                  hintText: 'Ej: Queso extra, Bacon',
                  prefixIcon: const Icon(Icons.add_circle_outline),
                  suffixIcon: _nombreController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _nombreController.clear();
                            setState(() => _busqueda = '');
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
                                ? 'No hay extras'
                                : 'No se encontraron',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final extra = filtered[index];
                            return ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.add_circle_outline,
                                size: 20,
                              ),
                              title: Text(extra.nombre),
                              subtitle: Text(
                                '+${extra.precio.toStringAsFixed(2)}€',
                              ),
                              onTap: () => Navigator.pop(context, extra),
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
          child: Text(esEdicion ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }

  void _guardar() {
    if (_formKey.currentState?.validate() ?? false) {
      final nombreIngresado = _nombreController.text.trim().toLowerCase();
      final precio = double.parse(_precioController.text.replaceAll(',', '.'));

      final existe = _extrasCache.any(
        (e) => e.nombre.toLowerCase() == nombreIngresado,
      );

      ExtraProducto extra;

      if (existe) {
        extra = _extrasCache.firstWhere(
          (e) => e.nombre.toLowerCase() == nombreIngresado,
        );
      } else {
        extra = ExtraProducto(
          id: widget.extra?.id ?? const Uuid().v4(),
          nombre: _nombreController.text.trim(),
          precio: precio,
        );

        if (widget.extra != null) {
          ref.read(extrasGlobalesProvider.notifier).actualizar(extra);
        } else {
          ref.read(extrasGlobalesProvider.notifier).agregar(extra);
        }
      }

      Navigator.pop(context, extra);
    }
  }
}
