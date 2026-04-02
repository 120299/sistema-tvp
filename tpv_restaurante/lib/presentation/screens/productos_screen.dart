import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/services/image_storage_service.dart';
import '../providers/providers.dart';
import '../widgets/producto_dialog.dart';
import '../widgets/categoria_dialog.dart';

final busquedaProductoProvider = StateProvider<String>((ref) => '');

class ProductosScreen extends ConsumerStatefulWidget {
  const ProductosScreen({super.key});

  @override
  ConsumerState<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends ConsumerState<ProductosScreen> {
  final _busquedaController = TextEditingController();

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(imageRefreshTriggerProvider);
    final productos = ref.watch(productosFiltradosProvider);
    final categoriasRaw = ref.watch(categoriasProvider);
    final categorias = List<CategoriaProducto>.from(categoriasRaw)
      ..sort((a, b) => a.orden.compareTo(b.orden));
    final categoriaSeleccionada = ref.watch(categoriaSeleccionadaProvider);
    final busqueda = ref.watch(busquedaProductoProvider);
    final ordenProducto = ref.watch(ordenProductoProvider);

    // Apply search filter
    var productosFiltrados = busqueda.isEmpty
        ? productos
        : productos
              .where(
                (p) =>
                    p.nombre.toLowerCase().contains(busqueda.toLowerCase()) ||
                    (p.descripcion?.toLowerCase().contains(
                          busqueda.toLowerCase(),
                        ) ??
                        false),
              )
              .toList();

    // Apply sorting
    productosFiltrados = _ordenarProductos(productosFiltrados, ordenProducto);

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          _buildCategoriasToolbar(categoriaSeleccionada, categorias),
          _buildToolbar(busqueda, categoriaSeleccionada, categorias),
          Expanded(
            child: productosFiltrados.isEmpty
                ? _buildEmptyState()
                : _buildProductGrid(productosFiltrados, categorias),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'nuevo',
            onPressed: () => _agregarProducto(context),
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Nuevo producto',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final productos = ref.watch(productosProvider);
    final disponibles = productos.where((p) => p.disponible).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: const Icon(
                    Icons.inventory_2,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Productos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${productos.length} total • $disponibles activos',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(
    String busqueda,
    String? categoriaSeleccionada,
    List<CategoriaProducto> categorias,
  ) {
    final filtroDisp = ref.watch(filtroDisponibilidadProvider);
    final filtroTipo = ref.watch(filtroTipoProvider);
    final ordenProducto = ref.watch(ordenProductoProvider);

    final hayFiltrosActivos =
        filtroDisp != FiltroDisponibilidad.todos ||
        filtroTipo != FiltroTipo.todos ||
        busqueda.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          // Filtros en fila - Los 3 filtros solicitados
          Row(
            children: [
              // Filtro 1: Disponibilidad
              Expanded(
                child: _buildFiltroBoton(
                  icon: Icons.inventory_2,
                  titulo: 'Disponibilidad',
                  valor: _getDisponibilidadLabel(filtroDisp),
                  isActive: filtroDisp != FiltroDisponibilidad.todos,
                  onTap: () => _mostrarFiltroDisponibilidad(),
                ),
              ),
              const SizedBox(width: 8),
              // Filtro 2: Tipo
              Expanded(
                child: _buildFiltroBoton(
                  icon: Icons.tune,
                  titulo: 'Tipo',
                  valor: _getTipoLabel(filtroTipo),
                  isActive: filtroTipo != FiltroTipo.todos,
                  onTap: () => _mostrarFiltroTipo(),
                ),
              ),
              const SizedBox(width: 8),
              // Filtro 3: Orden (Nombre/Precio + Asc/Desc)
              Expanded(
                child: _buildFiltroBoton(
                  icon: Icons.sort,
                  titulo: 'Ordenar',
                  valor: _getOrdenLabel(ordenProducto),
                  isActive:
                      ordenProducto.campo != TipoOrdenProducto.nombre ||
                      ordenProducto.direccion != DireccionOrden.ascendente,
                  onTap: () => _mostrarFiltroOrden(),
                ),
              ),
            ],
          ),
          // Fila inferior con búsqueda y limpiar
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _busquedaController,
                  autofocus: false,
                  decoration: InputDecoration(
                    hintText: 'Buscar producto...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: busqueda.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _busquedaController.clear();
                              ref
                                      .read(busquedaCompartidaProvider.notifier)
                                      .state =
                                  '';
                              ref
                                      .read(busquedaProductoProvider.notifier)
                                      .state =
                                  '';
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  onChanged: (value) {
                    ref.read(busquedaCompartidaProvider.notifier).state = value;
                    ref.read(busquedaProductoProvider.notifier).state = value;
                  },
                ),
              ),
              if (hayFiltrosActivos) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    ref.read(filtroDisponibilidadProvider.notifier).state =
                        FiltroDisponibilidad.todos;
                    ref.read(filtroTipoProvider.notifier).state =
                        FiltroTipo.todos;
                    ref
                        .read(ordenProductoProvider.notifier)
                        .actualizarOrden(const OrdenProducto());
                    ref.read(busquedaCompartidaProvider.notifier).state = '';
                    ref.read(busquedaProductoProvider.notifier).state = '';
                    _busquedaController.clear();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.clear_all,
                          size: 16,
                          color: Colors.red.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Limpiar',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroBoton({
    required IconData icon,
    required String titulo,
    required String valor,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppColors.primary : Colors.grey.shade300,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? AppColors.primary : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                  Text(
                    valor,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isActive
                          ? AppColors.primary
                          : Colors.grey.shade800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: isActive ? AppColors.primary : Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }

  String _getDisponibilidadLabel(FiltroDisponibilidad filtro) {
    switch (filtro) {
      case FiltroDisponibilidad.todos:
        return 'Todos';
      case FiltroDisponibilidad.disponibles:
        return 'Disponibles';
      case FiltroDisponibilidad.noDisponibles:
        return 'Agotados';
    }
  }

  String _getTipoLabel(FiltroTipo filtro) {
    switch (filtro) {
      case FiltroTipo.todos:
        return 'Todos';
      case FiltroTipo.normales:
        return 'Normales';
      case FiltroTipo.variables:
        return 'Variables';
    }
  }

  String _getOrdenLabel(OrdenProducto orden) {
    final campo = orden.campo == TipoOrdenProducto.nombre ? 'Nombre' : 'Precio';
    final dir = orden.direccion == DireccionOrden.ascendente ? 'A-Z' : 'Z-A';
    return '$campo $dir';
  }

  void _mostrarFiltroDisponibilidad() {
    final actual = ref.read(filtroDisponibilidadProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filtrar por disponibilidad'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioOption<FiltroDisponibilidad>(
              title: 'Todos los productos',
              subtitle: 'Sin filtro',
              value: FiltroDisponibilidad.todos,
              groupValue: actual,
              onChanged: (value) {
                ref.read(filtroDisponibilidadProvider.notifier).state = value!;
                Navigator.pop(ctx);
              },
            ),
            _buildRadioOption<FiltroDisponibilidad>(
              title: 'Solo disponibles',
              subtitle: 'Productos en stock',
              value: FiltroDisponibilidad.disponibles,
              groupValue: actual,
              onChanged: (value) {
                ref.read(filtroDisponibilidadProvider.notifier).state = value!;
                Navigator.pop(ctx);
              },
            ),
            _buildRadioOption<FiltroDisponibilidad>(
              title: 'Solo agotados',
              subtitle: 'Productos sin stock',
              value: FiltroDisponibilidad.noDisponibles,
              groupValue: actual,
              onChanged: (value) {
                ref.read(filtroDisponibilidadProvider.notifier).state = value!;
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarFiltroTipo() {
    final actual = ref.read(filtroTipoProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filtrar por tipo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRadioOption<FiltroTipo>(
              title: 'Todos los tipos',
              subtitle: 'Normales y variables',
              value: FiltroTipo.todos,
              groupValue: actual,
              onChanged: (value) {
                ref.read(filtroTipoProvider.notifier).state = value!;
                Navigator.pop(ctx);
              },
            ),
            _buildRadioOption<FiltroTipo>(
              title: 'Productos normales',
              subtitle: 'Sin variantes',
              value: FiltroTipo.normales,
              groupValue: actual,
              onChanged: (value) {
                ref.read(filtroTipoProvider.notifier).state = value!;
                Navigator.pop(ctx);
              },
            ),
            _buildRadioOption<FiltroTipo>(
              title: 'Productos variables',
              subtitle: 'Con variantes',
              value: FiltroTipo.variables,
              groupValue: actual,
              onChanged: (value) {
                ref.read(filtroTipoProvider.notifier).state = value!;
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarFiltroOrden() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final actual = ref.read(ordenProductoProvider);

          void actualizarOrden(OrdenProducto nuevo) {
            ref.read(ordenProductoProvider.notifier).actualizarOrden(nuevo);
            setDialogState(() {});
          }

          return AlertDialog(
            title: const Text('Ordenar por'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Campo:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildOrdenCampoBoton(
                        label: 'Nombre',
                        icon: Icons.sort_by_alpha,
                        isSelected: actual.campo == TipoOrdenProducto.nombre,
                        onTap: () {
                          actualizarOrden(
                            OrdenProducto(
                              campo: TipoOrdenProducto.nombre,
                              direccion: actual.direccion,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildOrdenCampoBoton(
                        label: 'Precio',
                        icon: Icons.euro,
                        isSelected: actual.campo == TipoOrdenProducto.precio,
                        onTap: () {
                          actualizarOrden(
                            OrdenProducto(
                              campo: TipoOrdenProducto.precio,
                              direccion: actual.direccion,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Dirección:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildOrdenDireccionBoton(
                        label: 'Ascendente',
                        sublabel: actual.campo == TipoOrdenProducto.nombre
                            ? 'A → Z'
                            : 'Menor → Mayor',
                        icon: Icons.arrow_upward,
                        isSelected:
                            actual.direccion == DireccionOrden.ascendente,
                        onTap: () {
                          actualizarOrden(
                            actual.copyWith(
                              direccion: DireccionOrden.ascendente,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildOrdenDireccionBoton(
                        label: 'Descendente',
                        sublabel: actual.campo == TipoOrdenProducto.nombre
                            ? 'Z → A'
                            : 'Mayor → Menor',
                        icon: Icons.arrow_downward,
                        isSelected:
                            actual.direccion == DireccionOrden.descendente,
                        onTap: () {
                          actualizarOrden(
                            actual.copyWith(
                              direccion: DireccionOrden.descendente,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cerrar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrdenCampoBoton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdenDireccionBoton({
    required String label,
    required String sublabel,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondary.withValues(alpha: 0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.secondary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.secondary : Colors.grey,
              size: 18,
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? AppColors.secondary
                        : Colors.grey.shade700,
                  ),
                ),
                Text(
                  sublabel,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption<T>({
    required String title,
    required String subtitle,
    required T value,
    required T groupValue,
    required ValueChanged<T?> onChanged,
  }) {
    return RadioListTile<T>(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
    );
  }

  Widget _buildCategoriasToolbar(
    String? categoriaSeleccionada,
    List<CategoriaProducto> categorias,
  ) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.lightDivider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoriaChip(
                  'Todos',
                  null,
                  categoriaSeleccionada == null,
                  Icons.apps,
                ),
                const SizedBox(width: 8),
                ...categorias.map(
                  (cat) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildCategoriaChip(
                      cat.nombre,
                      cat.id,
                      categoriaSeleccionada == cat.id,
                      Icons.category,
                      cat.icono,
                      cat.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _mostrarModalCategorias(
              context,
              categoriaSeleccionada,
              categorias,
            ),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.grid_view,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarModalCategorias(
    BuildContext context,
    String? categoriaSeleccionada,
    List<CategoriaProducto> categorias,
  ) {
    bool modoGestion = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final cats = ref.watch(categoriasProvider);
            final sorted = List<CategoriaProducto>.from(cats)
              ..sort((a, b) => a.orden.compareTo(b.orden));
            final productos = ref.watch(productosProvider);

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.category, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          modoGestion ? 'Gestionar Categorías' : 'Categorías',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (!modoGestion)
                          TextButton.icon(
                            onPressed: () =>
                                setModalState(() => modoGestion = true),
                            icon: const Icon(Icons.settings, size: 18),
                            label: const Text('Gestionar'),
                          )
                        else
                          TextButton.icon(
                            onPressed: () =>
                                setModalState(() => modoGestion = false),
                            icon: const Icon(Icons.grid_view, size: 18),
                            label: const Text('Seleccionar'),
                          ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: modoGestion
                          ? _buildGestionCategorias(
                              ctx,
                              sorted,
                              productos,
                              setModalState,
                            )
                          : _buildGridCategorias(
                              ctx,
                              categoriaSeleccionada,
                              sorted,
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGridCategorias(
    BuildContext ctx,
    String? categoriaSeleccionada,
    List<CategoriaProducto> categorias,
  ) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: categorias.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          final isSelected = categoriaSeleccionada == null;
          return GestureDetector(
            onTap: () {
              ref.read(categoriaSeleccionadaProvider.notifier).state = null;
              Navigator.pop(ctx);
            },
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : Colors.grey.shade50,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.apps,
                    size: 40,
                    color: isSelected ? AppColors.primary : Colors.black,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Todos',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? AppColors.primary : Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        final cat = categorias[index - 1];
        final isSelected = categoriaSeleccionada == cat.id;
        return GestureDetector(
          onTap: () {
            ref.read(categoriaSeleccionadaProvider.notifier).state = cat.id;
            Navigator.pop(ctx);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? cat.color.withValues(alpha: 0.15)
                  : Colors.grey.shade50,
              border: Border.all(
                color: isSelected ? cat.color : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCategoryImage(cat, 90, 60),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    cat.nombre,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? cat.color : Colors.black,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGestionCategorias(
    BuildContext ctx,
    List<CategoriaProducto> categorias,
    List<Producto> productos,
    StateSetter setModalState,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Arrastra para reordenar',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await showDialog(
                  context: ctx,
                  builder: (context) => const CategoriaDialog(),
                );
                setModalState(() {});
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nueva'),
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
        Expanded(
          child: categorias.isEmpty
              ? const Center(
                  child: Text(
                    'No hay categorías',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  onReorder: (oldIndex, newIndex) async {
                    await ref
                        .read(categoriasProvider.notifier)
                        .reorderFromList(categorias, oldIndex, newIndex);
                    setModalState(() {});
                  },
                  itemCount: categorias.length,
                  itemBuilder: (context, index) {
                    final cat = categorias[index];
                    final count = productos
                        .where((p) => p.categoriaId == cat.id)
                        .length;
                    return Card(
                      key: ValueKey(cat.id),
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ReorderableDragStartListener(
                              index: index,
                              child: Icon(
                                Icons.drag_handle,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: cat.color.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child:
                                    cat.imagenUrl != null &&
                                        cat.imagenUrl!.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: _buildCategoryImage(cat, 36, 36),
                                      )
                                    : Text(
                                        cat.icono,
                                        style: const TextStyle(fontSize: 20),
                                      ),
                              ),
                            ),
                          ],
                        ),
                        title: Text(
                          cat.nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          '$count productos',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: cat.color,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              onPressed: () async {
                                await showDialog(
                                  context: ctx,
                                  builder: (context) =>
                                      CategoriaDialog(categoria: cat),
                                );
                                setModalState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoriaChip(
    String label,
    String? id,
    bool selected,
    IconData icon, [
    String? icono,
    Color? color,
  ]) {
    return ActionChip(
      avatar: icono != null
          ? Text(icono, style: const TextStyle(fontSize: 14))
          : Icon(
              selected ? Icons.check : icon,
              size: 16,
              color: selected ? (color ?? AppColors.primary) : Colors.grey,
            ),
      label: Text(
        label,
        style: TextStyle(
          color: selected ? (color ?? AppColors.primary) : Colors.grey.shade700,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      backgroundColor: selected
          ? (color ?? AppColors.primary).withValues(alpha: 0.15)
          : Colors.grey.shade100,
      side: BorderSide(
        color: selected ? (color ?? AppColors.primary) : Colors.grey.shade300,
      ),
      onPressed: () {
        ref.read(categoriaSeleccionadaProvider.notifier).state = selected
            ? null
            : id;
      },
    );
  }

  Widget _buildEmptyState() {
    final busqueda = ref.watch(busquedaProductoProvider);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.rectangle,
            ),
            child: Icon(
              busqueda.isNotEmpty
                  ? Icons.search_off
                  : Icons.inventory_2_outlined,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            busqueda.isNotEmpty
                ? 'No se encontraron productos'
                : 'No hay productos registrados',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            busqueda.isNotEmpty
                ? 'Intenta con otro término de búsqueda'
                : 'Agrega tu primer producto para comenzar',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          if (busqueda.isEmpty)
            ElevatedButton.icon(
              onPressed: () => _agregarProducto(context),
              icon: const Icon(Icons.add),
              label: const Text('Agregar Producto'),
            ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(
    List<Producto> productos,
    List<CategoriaProducto> categorias,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount;
        if (width > 1200) {
          crossAxisCount = 6;
        } else if (width > 900) {
          crossAxisCount = 5;
        } else if (width > 600) {
          crossAxisCount = 4;
        } else if (width > 400) {
          crossAxisCount = 3;
        } else {
          crossAxisCount = 2;
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 5 / 4,
          ),
          itemCount: productos.length,
          itemBuilder: (context, index) {
            final producto = productos[index];
            final categoria = categorias.firstWhere(
              (c) => c.id == producto.categoriaId,
              orElse: () => CategoriaProducto.defaultCategories.first,
            );
            return _buildProductCard(producto, categoria);
          },
        );
      },
    );
  }

  Widget _buildProductCard(Producto producto, CategoriaProducto categoria) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: InkWell(
        onTap: () => _editarProducto(context, producto),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildProductImage(producto, categoria),
                  if (!producto.disponible)
                    Container(
                      color: Colors.black45,
                      child: const Center(
                        child: Text(
                          'AGOTADO',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (producto.esAlergenico)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          borderRadius: BorderRadius.zero,
                        ),
                        child: const Icon(
                          Icons.warning_amber,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  if (producto.esVariable)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.zero,
                        ),
                        child: const Icon(
                          Icons.tune,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    producto.nombre,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: producto.disponible ? null : Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPrecioProducto(producto),
                      InkWell(
                        onTap: () => _toggleDisponibilidad(producto),
                        child: Icon(
                          producto.disponible
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 16,
                          color: producto.disponible
                              ? Colors.grey
                              : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(Producto producto, CategoriaProducto categoria) {
    if (producto.imagenUrl != null && producto.imagenUrl!.isNotEmpty) {
      if (producto.imagenUrl!.startsWith('products/')) {
        final base64 = imageStorageService.getBase64FromPath(
          producto.imagenUrl!,
        );
        if (base64.isNotEmpty) {
          return Image.memory(
            base64Decode(base64),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildPlaceholder(categoria),
          );
        }
      } else if (producto.imagenUrl!.startsWith('http')) {
        return Image.network(
          producto.imagenUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(categoria),
        );
      }
    }
    return _buildPlaceholder(categoria);
  }

  Widget _buildPlaceholder(CategoriaProducto categoria) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            categoria.color.withValues(alpha: 0.2),
            categoria.color.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Center(
        child: Text(categoria.icono, style: const TextStyle(fontSize: 36)),
      ),
    );
  }

  void _agregarProducto(BuildContext context) {
    showDialog(context: context, builder: (context) => const ProductoDialog());
  }

  Widget _buildCategoryImage(
    CategoriaProducto cat, [
    double width = 50,
    double height = 50,
  ]) {
    final imagenUrl = cat.imagenUrl;
    if (imagenUrl != null && imagenUrl.isNotEmpty) {
      if (imagenUrl.startsWith('data:')) {
        final base64Match = RegExp(r'base64,(.+)').firstMatch(imagenUrl);
        if (base64Match != null) {
          try {
            final base64Data = base64Match.group(1)!;
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                base64Decode(base64Data),
                width: width,
                height: height,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildCategoryIcon(cat, width),
              ),
            );
          } catch (_) {
            return _buildCategoryIcon(cat, width);
          }
        }
      }
      if (imagenUrl.startsWith('http')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imagenUrl,
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildCategoryIcon(cat, width),
          ),
        );
      }
      if (imagenUrl.startsWith('categories/')) {
        final base64 = imageStorageService.getBase64FromPath(imagenUrl);
        if (base64.isNotEmpty) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              base64Decode(base64),
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildCategoryIcon(cat, width),
            ),
          );
        }
      }
    }
    return _buildCategoryIcon(cat, width);
  }

  Widget _buildCategoryIcon(CategoriaProducto cat, [double size = 28]) {
    if (cat.icono.isNotEmpty) {
      return Text(cat.icono, style: TextStyle(fontSize: size));
    }
    return Icon(Icons.category, size: size, color: cat.color);
  }

  void _editarProducto(BuildContext context, Producto producto) {
    showDialog(
      context: context,
      builder: (context) => ProductoDialog(producto: producto),
    );
  }

  void _toggleDisponibilidad(Producto producto) {
    ref.read(productosProvider.notifier).toggleDisponibilidad(producto.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          producto.disponible
              ? '${producto.nombre} deshabilitado'
              : '${producto.nombre} habilitado',
        ),
        backgroundColor: producto.disponible
            ? Colors.orange
            : AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  List<Producto> _ordenarProductos(
    List<Producto> productos,
    OrdenProducto orden,
  ) {
    final productosOrdenados = List<Producto>.from(productos);

    switch (orden.campo) {
      case TipoOrdenProducto.nombre:
        productosOrdenados.sort((a, b) {
          final comparacion = a.nombre.toLowerCase().compareTo(
            b.nombre.toLowerCase(),
          );
          return orden.direccion == DireccionOrden.ascendente
              ? comparacion
              : -comparacion;
        });
        break;
      case TipoOrdenProducto.precio:
        productosOrdenados.sort((a, b) {
          final comparacion = a.precio.compareTo(b.precio);
          return orden.direccion == DireccionOrden.ascendente
              ? comparacion
              : -comparacion;
        });
        break;
      case TipoOrdenProducto.disponible:
        productosOrdenados.sort((a, b) {
          final comparacion = a.disponible == b.disponible
              ? 0
              : (a.disponible ? -1 : 1);
          return orden.direccion == DireccionOrden.ascendente
              ? comparacion
              : -comparacion;
        });
        break;
    }

    return productosOrdenados;
  }

  Widget _buildPrecioProducto(Producto producto, {bool compact = false}) {
    final color = producto.disponible ? AppColors.secondary : Colors.grey;

    if (producto.esVariable &&
        producto.precio == 0 &&
        (producto.variantes?.isNotEmpty ?? false)) {
      final precios = producto.variantes!.map((v) => v.precio).toList();
      final precioMin = precios.reduce((a, b) => a < b ? a : b);
      final precioMax = precios.reduce((a, b) => a > b ? a : b);

      if (compact) {
        return Text(
          precioMin == precioMax
              ? '${precioMin.toStringAsFixed(2)} EUR'
              : 'Desde ${precioMin.toStringAsFixed(2)} EUR',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (precioMin == precioMax)
            Text(
              '${precioMin.toStringAsFixed(2)} EUR',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            )
          else
            Text(
              '${precioMin.toStringAsFixed(2)} - ${precioMax.toStringAsFixed(2)} EUR',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
        ],
      );
    }

    return Text(
      '${producto.precio.toStringAsFixed(2)} EUR',
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
    );
  }
}
