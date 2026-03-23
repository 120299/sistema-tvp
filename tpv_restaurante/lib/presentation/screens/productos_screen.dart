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
          Expanded(
            child: productosFiltrados.isEmpty
                ? _buildEmptyState()
                : _buildProductList(productosFiltrados, categorias),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _agregarProducto(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Producto'),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _busquedaController,
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: busqueda.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _busquedaController.clear();
                          ref.read(busquedaProductoProvider.notifier).state =
                              '';
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) =>
                  ref.read(busquedaProductoProvider.notifier).state = value,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
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
                        cat.icono,
                        cat.color,
                      ),
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

  Widget _buildFilterChip(
    String label,
    String? value,
    bool selected,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: () =>
          ref.read(categoriaSeleccionadaProvider.notifier).state = value,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: selected ? Colors.white : Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriaChip(
    String label,
    String value,
    bool selected,
    String icono,
    Color color,
  ) {
    return GestureDetector(
      onTap: () => ref.read(categoriaSeleccionadaProvider.notifier).state =
          selected ? null : value,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: selected ? color : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icono, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildProductList(
    List<Producto> productos,
    List<CategoriaProducto> categorias,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
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
  }

  Widget _buildProductCard(Producto producto, CategoriaProducto categoria) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: producto.disponible
            ? null
            : Border.all(color: Colors.grey.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _editarProducto(context, producto),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildProductImage(producto, categoria),
                const SizedBox(width: 16),
                Expanded(child: _buildProductInfo(producto, categoria)),
                _buildProductPrice(producto),
                const SizedBox(width: 16),
                _buildProductActions(producto),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(Producto producto, CategoriaProducto categoria) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: categoria.color.withValues(alpha: 0.1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildProductImageContent(producto, categoria),
      ),
    );
  }

  Widget _buildProductImageContent(
    Producto producto,
    CategoriaProducto categoria,
  ) {
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
      color: categoria.color.withValues(alpha: 0.1),
      child: Center(
        child: Text(categoria.icono, style: const TextStyle(fontSize: 32)),
      ),
    );
  }

  Widget _buildProductInfo(Producto producto, CategoriaProducto categoria) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                producto.nombre,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!producto.disponible)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'AGOTADO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            if (producto.esAlergenico)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_amber,
                  size: 16,
                  color: AppColors.warning,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: categoria.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(categoria.icono, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text(
                categoria.nombre,
                style: TextStyle(
                  fontSize: 12,
                  color: categoria.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (producto.descripcion != null) ...[
          const SizedBox(height: 4),
          Text(
            producto.descripcion!,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildProductPrice(Producto producto) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${producto.precio.toStringAsFixed(2)} €',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        if (producto.precioCompra != null)
          Text(
            'Coste: ${producto.precioCompra!.toStringAsFixed(2)} €',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
      ],
    );
  }

  Widget _buildProductActions(Producto producto) {
    return Column(
      children: [
        IconButton(
          onPressed: () => _editarProducto(context, producto),
          icon: const Icon(Icons.edit_outlined),
          color: AppColors.primary,
          tooltip: 'Editar',
        ),
        IconButton(
          onPressed: () => _toggleDisponibilidad(producto),
          icon: Icon(
            producto.disponible ? Icons.visibility_off : Icons.visibility,
          ),
          color: producto.disponible ? AppColors.success : Colors.grey,
          tooltip: producto.disponible ? 'Deshabilitar' : 'Habilitar',
        ),
      ],
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
