import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../providers/providers.dart';

class MesaDialog extends ConsumerStatefulWidget {
  final Mesa? mesa;

  const MesaDialog({super.key, this.mesa});

  @override
  ConsumerState<MesaDialog> createState() => _MesaDialogState();
}

class _MesaDialogState extends ConsumerState<MesaDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _numeroController;
  late TextEditingController _capacidadController;

  @override
  void initState() {
    super.initState();
    _numeroController = TextEditingController(
      text: widget.mesa?.numero.toString() ?? '',
    );
    _capacidadController = TextEditingController(
      text: widget.mesa?.capacidad.toString() ?? '4',
    );
  }

  @override
  void dispose() {
    _numeroController.dispose();
    _capacidadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.mesa != null;

    return AlertDialog(
      title: Text(esEdicion ? 'Editar Mesa' : 'Nueva Mesa'),
      content: SizedBox(
        width: 350,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _numeroController,
                decoration: const InputDecoration(
                  labelText: 'Número de Mesa',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El número es obligatorio';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Número inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _capacidadController,
                decoration: const InputDecoration(
                  labelText: 'Capacidad (personas)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La capacidad es obligatoria';
                  }
                  final num = int.tryParse(value);
                  if (num == null || num < 1) {
                    return 'Capacidad inválida';
                  }
                  return null;
                },
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
        if (esEdicion)
          TextButton(
            onPressed: _eliminar,
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ElevatedButton(
          onPressed: _guardar,
          child: Text(esEdicion ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      final numero = int.parse(_numeroController.text);
      final capacidad = int.parse(_capacidadController.text);

      if (widget.mesa != null) {
        final mesaActualizada = widget.mesa!.copyWith(
          numero: numero,
          capacidad: capacidad,
        );
        ref.read(mesasProvider.notifier).actualizar(mesaActualizada);
        Navigator.pop(context, mesaActualizada);
      } else {
        final nuevaMesa = Mesa(
          id: 'mesa_${const Uuid().v4()}',
          numero: numero,
          capacidad: capacidad,
        );
        ref.read(mesasProvider.notifier).agregar(nuevaMesa);
        Navigator.pop(context, nuevaMesa);
      }
    }
  }

  void _eliminar() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Eliminar Mesa ${widget.mesa!.numero}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(mesasProvider.notifier).eliminar(widget.mesa!.id);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
