import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  late TextEditingController _iconoController;
  late Color _color;

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
    _iconoController = TextEditingController(
      text: widget.categoria?.icono ?? '📦',
    );
    _color = widget.categoria?.color ?? _coloresDisponibles.first;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _iconoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.categoria != null;

    return Dialog(
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _iconoController.text,
                      style: const TextStyle(fontSize: 24),
                    ),
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
                          esEdicion
                              ? 'Actualiza los datos'
                              : 'Crea una nueva categoría',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la categoría',
                  prefixIcon: Icon(Icons.label),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty == true ? 'Obligatorio' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _iconoController,
                decoration: const InputDecoration(
                  labelText: 'Icono (emoji)',
                  prefixIcon: Icon(Icons.emoji_emotions),
                  border: OutlineInputBorder(),
                  hintText: 'Ej: ☕, 🍕, 🍷',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              const Text(
                'Color:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
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
                        borderRadius: BorderRadius.circular(8),
                        border: _color == color
                            ? Border.all(color: Colors.black, width: 3)
                            : null,
                      ),
                      child: _color == color
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (esEdicion)
                    TextButton.icon(
                      onPressed: _eliminar,
                      icon: const Icon(Icons.delete),
                      label: const Text('Eliminar'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _guardar() async {
    if (_formKey.currentState!.validate()) {
      final categoria = CategoriaProducto(
        id: widget.categoria?.id ?? 'cat_${const Uuid().v4()}',
        nombre: _nombreController.text.trim(),
        icono: _iconoController.text,
        color: _color,
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
