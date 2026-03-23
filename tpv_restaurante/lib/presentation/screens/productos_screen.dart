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
    final categorias = ref.watch(categoriasProvider);
    final categoriaSeleccionada = ref.watch(categoriaSeleccionadaProvider);
    final busqueda = ref.watch(busquedaProductoProvider);

    final productosFiltrados = busqueda.isEmpty
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

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          _buildToolbar(busqueda, categoriaSeleccionada, categorias),
          _buildCategoriasToolbar(categoriaSeleccionada, categorias),
          Expanded(
            child: productosFiltrados.isEmpty
                ? _buildEmptyState()
                : _buildProductGrid(productosFiltrados, categorias),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _agregarProducto(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
    );
  }

  Widget _buildHeader() {
    final productos = ref.watch(productosProvider);
    final disponibles = productos.where((p) => p.disponible).length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.inventory_2,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gestión de Productos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Administra tu catálogo de productos',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildStatItem('${productos.length}', 'Total'),
                  const SizedBox(width: 16),
                  Container(width: 1, height: 30, color: Colors.white24),
                  const SizedBox(width: 16),
                  _buildStatItem('$disponibles', 'Activos'),
                ],
              ),
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: () => _gestionarCategorias(context),
              icon: const Icon(Icons.category, color: Colors.white),
              label: const Text(
                'Categorías',
                style: TextStyle(color: Colors.white),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildToolbar(
    String busqueda,
    String? categoriaSeleccionada,
    List<CategoriaProducto> categorias,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.lightDivider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _busquedaController,
              decoration: InputDecoration(
                hintText: 'Buscar...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: busqueda.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _busquedaController.clear();
                          ref.read(busquedaProductoProvider.notifier).state =
                              '';
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (value) =>
                  ref.read(busquedaProductoProvider.notifier).state = value,
            ),
          ),
        ],
      ),
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
                null,
                cat.icono,
                cat.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriaChip(
    String label,
    String? id,
    bool selected,
    IconData? icon, [
    String? icono,
    Color? color,
  ]) {
    return ActionChip(
      avatar: icono != null
          ? Text(icono, style: const TextStyle(fontSize: 14))
          : (icon != null
                ? Icon(
                    icon,
                    size: 16,
                    color: selected
                        ? (color ?? AppColors.primary)
                        : Colors.grey,
                  )
                : null),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: selected ? Colors.white : Colors.grey.shade700,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      backgroundColor: selected
          ? (color ?? AppColors.primary)
          : Colors.grey.shade200,
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
              shape: BoxShape.circle,
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
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.75,
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
      child: InkWell(
        onTap: () => _editarProducto(context, producto),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1,
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
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.warning_amber,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: producto.disponible ? null : Colors.grey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${producto.precio.toStringAsFixed(2)} €',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: producto.disponible
                                ? AppColors.secondary
                                : Colors.grey,
                          ),
                        ),
                        InkWell(
                          onTap: () => _toggleDisponibilidad(producto),
                          child: Icon(
                            producto.disponible
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 20,
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
        child: Text(categoria.icono, style: const TextStyle(fontSize: 40)),
      ),
    );
  }

  void _agregarProducto(BuildContext context) {
    showDialog(context: context, builder: (context) => const ProductoDialog());
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

  void _gestionarCategorias(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) =>
            _buildCategoriasSheet(scrollController),
      ),
    );
  }

  Widget _buildCategoriasSheet(ScrollController scrollController) {
    final categorias = ref.watch(categoriasProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.category, color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Gestionar Categorías',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => const CategoriaDialog(),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Nueva'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: categorias.isEmpty
                ? const Center(
                    child: Text(
                      'No hay categorías',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    itemCount: categorias.length,
                    itemBuilder: (context, index) {
                      final cat = categorias[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: cat.color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                cat.icono,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                          title: Text(
                            cat.nombre,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${ref.watch(productosProvider).where((p) => p.categoriaId == cat.id).length} productos',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: cat.color,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => showDialog(
                                  context: context,
                                  builder: (context) =>
                                      CategoriaDialog(categoria: cat),
                                ),
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
}
