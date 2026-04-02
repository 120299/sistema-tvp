import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/services/ingredientes_extras_service.dart';
import '../providers/providers.dart';

class IngredientesExtrasScreen extends ConsumerStatefulWidget {
  const IngredientesExtrasScreen({super.key});

  @override
  ConsumerState<IngredientesExtrasScreen> createState() =>
      _IngredientesExtrasScreenState();
}

class _IngredientesExtrasScreenState
    extends ConsumerState<IngredientesExtrasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _busquedaController = TextEditingController();
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _busquedaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingredientes y Extras'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Ingredientes', icon: Icon(Icons.restaurant)),
            Tab(text: 'Extras', icon: Icon(Icons.add_circle)),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: TextField(
              controller: _busquedaController,
              decoration: InputDecoration(
                hintText: 'Buscar...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _busqueda.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _busquedaController.clear();
                          setState(() => _busqueda = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) =>
                  setState(() => _busqueda = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildIngredientesList(), _buildExtrasList()],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoAgregar(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildIngredientesList() {
    final ingredientes = ref.watch(ingredientesGlobalesProvider);
    final filtered = _busqueda.isEmpty
        ? ingredientes
        : ingredientes
              .where((i) => i.nombre.toLowerCase().contains(_busqueda))
              .toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _busqueda.isEmpty
                  ? 'No hay ingredientes'
                  : 'No se encontraron ingredientes',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final ingrediente = filtered[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.restaurant, color: AppColors.primary),
            ),
            title: Text(
              ingrediente.nombre,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () =>
                      _mostrarDialogoEditar(ingrediente: ingrediente),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    size: 20,
                    color: Colors.red.shade700,
                  ),
                  onPressed: () => _confirmarEliminar(ingrediente),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExtrasList() {
    final extras = ref.watch(extrasGlobalesProvider);
    final filtered = _busqueda.isEmpty
        ? extras
        : extras
              .where((e) => e.nombre.toLowerCase().contains(_busqueda))
              .toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _busqueda.isEmpty ? 'No hay extras' : 'No se encontraron extras',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final extra = filtered[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add_circle, color: Colors.purple),
            ),
            title: Text(
              extra.nombre,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${extra.precio.toStringAsFixed(2)} EUR'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _mostrarDialogoEditar(extra: extra),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    size: 20,
                    color: Colors.red.shade700,
                  ),
                  onPressed: () => _confirmarEliminarExtra(extra),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _mostrarDialogoAgregar() {
    if (_tabController.index == 0) {
      _mostrarDialogoIngrediente();
    } else {
      _mostrarDialogoExtra();
    }
  }

  void _mostrarDialogoIngrediente({IngredienteProducto? ingrediente}) async {
    final nombreController = TextEditingController(
      text: ingrediente?.nombre ?? '',
    );
    final esEdicion = ingrediente != null;

    final resultado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(esEdicion ? 'Editar Ingrediente' : 'Nuevo Ingrediente'),
        content: TextField(
          controller: nombreController,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            hintText: 'Ej: Lechuga, Tomate',
            prefixIcon: Icon(Icons.restaurant),
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(esEdicion ? 'Guardar' : 'Crear'),
          ),
        ],
      ),
    );

    if (resultado == true && nombreController.text.trim().isNotEmpty) {
      final nuevoIngrediente = IngredienteProducto(
        id: ingrediente?.id ?? const Uuid().v4(),
        nombre: nombreController.text.trim(),
      );

      if (esEdicion) {
        ref
            .read(ingredientesGlobalesProvider.notifier)
            .actualizar(nuevoIngrediente);
      } else {
        ref
            .read(ingredientesGlobalesProvider.notifier)
            .agregar(nuevoIngrediente);
      }
    }
  }

  void _mostrarDialogoExtra({ExtraProducto? extra}) async {
    final nombreController = TextEditingController(text: extra?.nombre ?? '');
    final precioController = TextEditingController(
      text: extra?.precio.toString() ?? '',
    );
    final esEdicion = extra != null;

    final resultado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(esEdicion ? 'Editar Extra' : 'Nuevo Extra'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Ej: Queso extra, Bacon',
                prefixIcon: Icon(Icons.add_circle),
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: precioController,
              decoration: const InputDecoration(
                labelText: 'Precio (EUR)',
                hintText: '1.50',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(esEdicion ? 'Guardar' : 'Crear'),
          ),
        ],
      ),
    );

    if (resultado == true && nombreController.text.trim().isNotEmpty) {
      final precio =
          double.tryParse(precioController.text.replaceAll(',', '.')) ?? 0.0;
      final nuevoExtra = ExtraProducto(
        id: extra?.id ?? const Uuid().v4(),
        nombre: nombreController.text.trim(),
        precio: precio,
      );

      if (esEdicion) {
        ref.read(extrasGlobalesProvider.notifier).actualizar(nuevoExtra);
      } else {
        ref.read(extrasGlobalesProvider.notifier).agregar(nuevoExtra);
      }
    }
  }

  void _mostrarDialogoEditar({
    IngredienteProducto? ingrediente,
    ExtraProducto? extra,
  }) {
    if (ingrediente != null) {
      _mostrarDialogoIngrediente(ingrediente: ingrediente);
    } else if (extra != null) {
      _mostrarDialogoExtra(extra: extra);
    }
  }

  void _confirmarEliminar(IngredienteProducto ingrediente) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Ingrediente'),
        content: Text('¿Estás seguro de eliminar "${ingrediente.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      ref.read(ingredientesGlobalesProvider.notifier).eliminar(ingrediente.id);
    }
  }

  void _confirmarEliminarExtra(ExtraProducto extra) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Extra'),
        content: Text('¿Estás seguro de eliminar "${extra.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      ref.read(extrasGlobalesProvider.notifier).eliminar(extra.id);
    }
  }
}
