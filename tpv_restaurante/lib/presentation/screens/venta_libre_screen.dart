import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/services/image_storage_service.dart';
import '../../data/services/print_service.dart';
import '../providers/providers.dart';
import 'caja_screen.dart';

class VentaLibreScreen extends ConsumerStatefulWidget {
  const VentaLibreScreen({super.key});

  @override
  ConsumerState<VentaLibreScreen> createState() => _VentaLibreScreenState();
}

class _VentaLibreScreenState extends ConsumerState<VentaLibreScreen> {
  final List<PedidoItem> _carrito = [];
  String? _mesaAsignada;
  final TextEditingController _buscadorController = TextEditingController();
  String _textoBusqueda = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mesaId = ref.read(mesaVentaSeleccionadaProvider);
      if (mesaId != null) {
        setState(() {
          _mesaAsignada = mesaId;
        });
        _cargarProductosMesa(mesaId);
        ref.read(mesaVentaSeleccionadaProvider.notifier).state = null;
      }
    });
  }

  @override
  void dispose() {
    _buscadorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(imageRefreshTriggerProvider);
    final caja = ref.watch(cajaProvider);
    final productosFiltrados = ref.watch(productosFiltradosProvider);
    final categorias = ref.watch(categoriasProvider);
    final categoriaSeleccionada = ref.watch(categoriaSeleccionadaProvider);
    final todasMesas = ref.watch(mesasProvider);
    final todosProductos = ref.watch(productosProvider);

    final cajaAbierta = caja != null && caja.estado == EstadoCaja.abierta;

    final mesasDisponibles = todasMesas
        .where((m) => m.estado == EstadoMesa.libre)
        .toList();

    final productosAMostrar = _textoBusqueda.isNotEmpty
        ? todosProductos
              .where(
                (p) => p.nombre.toLowerCase().contains(
                  _textoBusqueda.toLowerCase(),
                ),
              )
              .toList()
        : productosFiltrados;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;

          if (isWide) {
            return Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildHeader(mesasDisponibles, isWide: true),
                      _buildCategorias(categoriaSeleccionada, categorias),
                      _buildBuscador(),
                      Expanded(child: _buildGridProductos(productosAMostrar)),
                    ],
                  ),
                ),
                Container(width: 1, color: AppColors.lightDivider),
                SizedBox(width: 380, child: _buildPanelCarrito()),
              ],
            );
          } else {
            return Column(
              children: [
                _buildHeader(mesasDisponibles, isWide: false),
                _buildCategorias(categoriaSeleccionada, categorias),
                _buildBuscador(),
                Expanded(child: _buildGridProductos(productosAMostrar)),
                _buildCarritoBarra(),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildCarritoBarra() {
    if (_carrito.isEmpty) return const SizedBox.shrink();

    final total = _carrito.fold<double>(0, (sum, item) => sum + item.subtotal);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.shopping_cart,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_carrito.fold<int>(0, (sum, i) => sum + i.cantidad)} items',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${total.toStringAsFixed(2)} €',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _cobrarPedido,
              icon: const Icon(Icons.payment),
              label: const Text('Cobrar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _verCarritoCompleto,
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  void _verCarritoCompleto() {
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
            _buildPanelCarrito(scrollController: scrollController),
      ),
    );
  }

  Widget _buildHeader(List<Mesa> mesasDisponibles, {bool isWide = true}) {
    final total = _carrito.fold<double>(0, (sum, item) => sum + item.subtotal);
    final totalItems = _carrito.fold<int>(
      0,
      (sum, item) => sum + item.cantidad,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.point_of_sale,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Punto de Venta',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isWide) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.shopping_cart,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$totalItems items',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.lightDivider),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _mesaAsignada,
                        isExpanded: true,
                        hint: const Row(
                          children: [
                            Icon(
                              Icons.table_restaurant,
                              size: 18,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '/',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.table_restaurant,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '/ (Sin mesa)',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          ...mesasDisponibles.map(
                            (m) => DropdownMenuItem(
                              value: m.id,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.table_restaurant,
                                    size: 18,
                                    color: AppColors.success,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Mesa ${m.numero}'),
                                ],
                              ),
                            ),
                          ),
                          ..._getMesasOcupadas().map(
                            (m) => DropdownMenuItem(
                              value: m.id,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.table_restaurant,
                                    size: 18,
                                    color: AppColors.warning,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Mesa ${m.numero}'),
                                ],
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) async {
                          if (value == _mesaAsignada) return;

                          final mesaAnterior = _mesaAsignada;
                          final carritoAnterior = List<PedidoItem>.from(
                            _carrito,
                          );

                          setState(() {
                            _mesaAsignada = value;
                            _carrito.clear();
                          });

                          if (value != null) {
                            _cargarProductosMesa(value);
                          }

                          if (mesaAnterior != null &&
                              carritoAnterior.isNotEmpty) {
                            final mesa = ref
                                .read(mesasProvider)
                                .firstWhere((m) => m.id == mesaAnterior);
                            if (mesa.pedidoActualId != null) {
                              await ref
                                  .read(mesasProvider.notifier)
                                  .liberar(mesaAnterior);
                            }
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (_mesaAsignada != null && _carrito.isNotEmpty) ...[
                  _buildActionButton(
                    icon: Icons.delete_outline,
                    color: AppColors.error,
                    onPressed: () {
                      _mostrarDialogoLiberarMesa();
                    },
                    tooltip: 'Liberar mesa',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoLiberarMesa() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppColors.warning),
            SizedBox(width: 12),
            Text('Liberar Mesa'),
          ],
        ),
        content: const Text(
          '¿Deseas liberar esta mesa? Se eliminará el pedido actual.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_mesaAsignada != null) {
                await ref.read(mesasProvider.notifier).liberar(_mesaAsignada!);
                final mesa = ref
                    .read(mesasProvider)
                    .firstWhere((m) => m.id == _mesaAsignada);
                if (mesa.pedidoActualId != null) {
                  await ref
                      .read(pedidosProvider.notifier)
                      .cancelar(mesa.pedidoActualId!);
                }
              }
              setState(() {
                _mesaAsignada = null;
                _carrito.clear();
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Liberar'),
          ),
        ],
      ),
    );
  }

  List<Mesa> _getMesasOcupadas() {
    final todasMesas = ref.read(mesasProvider);
    return todasMesas.where((m) => m.estado == EstadoMesa.ocupada).toList();
  }

  Widget _buildCategorias(
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
                Icons.category,
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

  Widget _buildBuscador() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.lightDivider)),
      ),
      child: TextField(
        controller: _buscadorController,
        decoration: InputDecoration(
          hintText: 'Buscar producto...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _textoBusqueda.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _buscadorController.clear();
                    setState(() => _textoBusqueda = '');
                  },
                )
              : null,
        ),
        onChanged: (value) => setState(() => _textoBusqueda = value),
      ),
    );
  }

  Widget _buildGridProductos(List<Producto> productos) {
    if (productos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No hay productos',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

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
            return _buildProductCard(producto);
          },
        );
      },
    );
  }

  Widget _buildProductCard(Producto producto) {
    final itemEnCarrito = _carrito
        .where((i) => i.productoId == producto.id)
        .firstOrNull;
    final categorias = ref.read(categoriasProvider);
    final categoria = categorias
        .where((c) => c.id == producto.categoriaId)
        .firstOrNull;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      child: InkWell(
        onTap: producto.disponible ? () => _agregarProducto(producto) : null,
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
                  if (itemEnCarrito != null)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${itemEnCarrito.cantidad}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
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
                  const SizedBox(height: 4),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(Producto producto, CategoriaProducto? categoria) {
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

  Widget _buildPlaceholder(CategoriaProducto? categoria) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (categoria?.color ?? AppColors.primary).withValues(alpha: 0.2),
            (categoria?.color ?? AppColors.primary).withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Center(
        child: Text(
          categoria?.icono ?? '🍽️',
          style: const TextStyle(fontSize: 40),
        ),
      ),
    );
  }

  Widget _buildPanelCarrito({ScrollController? scrollController}) {
    if (_carrito.isEmpty) {
      return Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Carrito vacío',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 8),
              Text(
                'Toca productos para añadir',
                style: TextStyle(color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      );
    }

    final total = _carrito.fold<double>(0, (sum, item) => sum + item.subtotal);
    final mesaSeleccionada = _mesaAsignada != null
        ? ref
              .read(mesasProvider)
              .where((m) => m.id == _mesaAsignada)
              .firstOrNull
        : null;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primary),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Pedido (${_carrito.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (mesaSeleccionada != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.table_restaurant,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Mesa ${mesaSeleccionada.numero}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: _carrito.length,
              itemBuilder: (context, index) {
                final item = _carrito[index];
                return _buildCarritoItem(item, index);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              border: Border(top: BorderSide(color: AppColors.lightDivider)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${total.toStringAsFixed(2)} €',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _cobrarPedido,
                    icon: const Icon(Icons.payment, size: 24),
                    label: const Text(
                      'COBRAR',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarritoItem(PedidoItem item, int index) {
    return Dismissible(
      key: ValueKey('carrito_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Eliminar producto'),
                content: Text(
                  '¿Eliminar "${item.productoNombre}" del carrito?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Eliminar'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => _eliminarProducto(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '${item.cantidad}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productoNombre,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${item.precioUnitario.toStringAsFixed(2)} € x ${item.cantidad}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Text(
              '${item.subtotal.toStringAsFixed(2)} €',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    if (item.cantidad > 1) {
                      setState(() {
                        _carrito[index] = item.copyWith(
                          cantidad: item.cantidad - 1,
                        );
                      });
                    } else {
                      _eliminarProducto(index);
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.remove,
                      color: AppColors.error,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    setState(() {
                      _carrito[index] = item.copyWith(
                        cantidad: item.cantidad + 1,
                      );
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: AppColors.success,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _agregarProducto(Producto producto) async {
    final caja = ref.read(cajaProvider);
    if (caja == null || caja.estado != EstadoCaja.abierta) {
      _mostrarAlertaCajaCerrada();
      return;
    }

    final itemExistente = _carrito
        .where((i) => i.productoId == producto.id)
        .firstOrNull;

    if (itemExistente != null) {
      final index = _carrito.indexOf(itemExistente);
      setState(() {
        _carrito[index] = itemExistente.copyWith(
          cantidad: itemExistente.cantidad + 1,
        );
      });
      if (_mesaAsignada != null) {
        await _actualizarItemBD(itemExistente, itemExistente.cantidad + 1);
      }
    } else {
      final nuevoItem = PedidoItem(
        id: 'item_${DateTime.now().millisecondsSinceEpoch}',
        productoId: producto.id,
        productoNombre: producto.nombre,
        cantidad: 1,
        precioUnitario: producto.precio,
      );
      setState(() {
        _carrito.add(nuevoItem);
      });
      if (_mesaAsignada != null) {
        await _agregarItemBD(nuevoItem);
      }
    }
  }

  Future<void> _agregarItemBD(PedidoItem item) async {
    if (_mesaAsignada == null) return;

    final mesaActual = ref
        .read(mesasProvider)
        .firstWhere((m) => m.id == _mesaAsignada);
    String pedidoId = mesaActual.pedidoActualId ?? '';

    if (pedidoId.isEmpty) {
      pedidoId = await ref.read(pedidosProvider.notifier).crear(_mesaAsignada!);
      await ref.read(mesasProvider.notifier).ocupar(_mesaAsignada!, pedidoId);
    }

    await ref
        .read(pedidosProvider.notifier)
        .agregarItem(
          pedidoId,
          Producto(
            id: item.productoId,
            nombre: item.productoNombre,
            precio: item.precioUnitario,
            categoriaId: '',
          ),
          cantidad: item.cantidad,
        );
  }

  Future<void> _actualizarItemBD(PedidoItem item, int nuevaCantidad) async {
    if (_mesaAsignada == null) return;

    final mesaActual = ref
        .read(mesasProvider)
        .firstWhere((m) => m.id == _mesaAsignada);
    if (mesaActual.pedidoActualId == null) return;

    final pedido = ref
        .read(pedidosProvider)
        .where((p) => p.id == mesaActual.pedidoActualId)
        .firstOrNull;
    if (pedido == null) return;

    final itemEnPedido = pedido.items
        .where((i) => i.productoId == item.productoId)
        .firstOrNull;
    if (itemEnPedido != null) {
      await ref
          .read(pedidosProvider.notifier)
          .actualizarCantidad(
            mesaActual.pedidoActualId!,
            itemEnPedido.id,
            nuevaCantidad,
          );
    }
  }

  void _eliminarProducto(int index) async {
    if (index < 0 || index >= _carrito.length) return;

    final item = _carrito[index];
    setState(() => _carrito.removeAt(index));

    if (_mesaAsignada != null) {
      final mesaActual = ref
          .read(mesasProvider)
          .firstWhere(
            (m) => m.id == _mesaAsignada,
            orElse: () => Mesa(id: '', numero: 0, capacidad: 4),
          );
      if (mesaActual.pedidoActualId != null) {
        await ref
            .read(pedidosProvider.notifier)
            .eliminarItem(mesaActual.pedidoActualId!, item.id);
      }
    }
  }

  void _mostrarAlertaCajaCerrada() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_amber, color: AppColors.warning),
            ),
            const SizedBox(width: 12),
            const Text('Caja Cerrada'),
          ],
        ),
        content: const Text(
          'La caja está cerrada. Abre la caja para poder realizar ventas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(indiceNavegacionProvider.notifier).state = 3;
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Ir a Caja'),
          ),
        ],
      ),
    );
  }

  void _cargarProductosMesa(String mesaId) async {
    final mesa = ref.read(mesasProvider).firstWhere((m) => m.id == mesaId);

    if (mesa.pedidoActualId == null) {
      setState(() {
        _carrito.clear();
      });
      return;
    }

    final pedido = ref
        .read(pedidosProvider)
        .where((p) => p.id == mesa.pedidoActualId)
        .firstOrNull;

    if (pedido != null && pedido.estado != EstadoPedido.cerrado) {
      setState(() {
        _carrito.clear();
        _carrito.addAll(pedido.items);
      });
    } else {
      await ref.read(mesasProvider.notifier).liberar(mesaId);
      setState(() {
        _carrito.clear();
      });
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }

  void _cobrarPedido() async {
    if (_carrito.isEmpty) return;

    final negocio = ref.read(negocioProvider);
    final subtotal = _carrito.fold<double>(
      0,
      (sum, item) => sum + item.subtotal,
    );
    final total = subtotal;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _CobroSheet(
        total: total,
        onCobrar: (metodosPago, {Cliente? cliente}) async {
          Navigator.pop(context);

          final caja = ref.read(cajaProvider);
          final pedidoId = await ref
              .read(pedidosProvider.notifier)
              .crear(
                _mesaAsignada ?? '',
                clienteId: cliente?.id,
                clienteNombre: cliente?.nombre,
                cajeroId: caja?.cajeroId,
                cajeroNombre: caja?.cajeroNombre,
              );

          for (final item in _carrito) {
            await ref
                .read(pedidosProvider.notifier)
                .agregarItem(
                  pedidoId,
                  Producto(
                    id: item.productoId,
                    nombre: item.productoNombre,
                    precio: item.precioUnitario,
                    categoriaId: '',
                  ),
                  cantidad: item.cantidad,
                );
          }

          final metodoPrincipal = metodosPago.keys.first;
          final totalPrincipal = metodosPago.values.first;

          await ref
              .read(pedidosProvider.notifier)
              .cerrar(pedidoId, metodoPrincipal);

          await ref
              .read(cajaProvider.notifier)
              .registrarVenta(total, metodoPrincipal, pedidoId: pedidoId);

          if (cliente != null) {
            await ref
                .read(clientesProvider.notifier)
                .registrarVenta(cliente.id, total);
          }

          if (_mesaAsignada != null) {
            await ref.read(mesasProvider.notifier).liberar(_mesaAsignada!);
          }

          final mesaNumero = _mesaAsignada != null
              ? ref
                    .read(mesasProvider)
                    .firstWhere((m) => m.id == _mesaAsignada)
                    .numero
                    .toString()
              : null;

          final metodoTexto = metodosPago.entries
              .map((e) => '${e.key}: ${e.value.toStringAsFixed(2)}€')
              .join(' + ');

          await PrintService.printTicket(
            items: List.from(_carrito),
            subtotal: subtotal,
            ivaPorcentaje: negocio.ivaPorcentaje,
            metodoPago: metodoTexto,
            negocio: negocio,
            mesaNumero: mesaNumero,
            cajeroNombre: caja?.cajeroNombre,
            clienteNombre: cliente?.nombre,
            clienteNif: cliente?.nif,
          );

          setState(() => _carrito.clear());
          _mesaAsignada = null;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Venta completada'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }
}

class _CobroSheet extends StatefulWidget {
  final double total;
  final Function(Map<String, double>, {Cliente? cliente}) onCobrar;

  const _CobroSheet({required this.total, required this.onCobrar});

  @override
  State<_CobroSheet> createState() => _CobroSheetState();
}

class _CobroSheetState extends State<_CobroSheet> {
  String _importe = '';
  String _metodoSeleccionado = 'Efectivo';
  Cliente? _clienteSeleccionado;

  @override
  void initState() {
    super.initState();
    _importe = widget.total.toStringAsFixed(2);
  }

  double get _importeNumerico => _metodoSeleccionado == 'Tarjeta'
      ? widget.total
      : (double.tryParse(_importe) ?? 0);
  double get _cambio => _importeNumerico - widget.total;
  bool get _pagoCompleto => _importeNumerico >= widget.total;

  void _setImporte(double amount) {
    setState(() {
      _importe = amount.toStringAsFixed(2);
    });
  }

  void _mostrarSelectorCliente() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SelectorClienteSheet(
        onClienteSelected: (cliente) {
          setState(() => _clienteSeleccionado = cliente);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _cobrar() {
    if (!_pagoCompleto) return;

    final metodos = <String, double>{};
    metodos[_metodoSeleccionado] = _importeNumerico;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: 12),
            Text('Confirmar Cobro'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total: ${widget.total.toStringAsFixed(2)} €'),
            Text('Pagado: ${_importeNumerico.toStringAsFixed(2)} €'),
            if (_cambio > 0)
              Text(
                'Cambio: ${_cambio.toStringAsFixed(2)} €',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                  fontSize: 18,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              '¿Confirmar el cobro?',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onCobrar(metodos, cliente: _clienteSeleccionado);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL A PAGAR',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${widget.total.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _mostrarSelectorCliente,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _clienteSeleccionado != null
                            ? AppColors.primary
                            : Colors.grey.shade600,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _clienteSeleccionado != null
                              ? Icons.person
                              : Icons.person_add,
                          color: _clienteSeleccionado != null
                              ? AppColors.primary
                              : Colors.white54,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _clienteSeleccionado != null
                                ? _clienteSeleccionado!.nombre
                                : 'Sin cliente (venta rápida)',
                            style: TextStyle(
                              color: _clienteSeleccionado != null
                                  ? Colors.white
                                  : Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (_clienteSeleccionado != null)
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white54,
                              size: 18,
                            ),
                            onPressed: () {
                              setState(() => _clienteSeleccionado = null);
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          )
                        else
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.white54,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildMetodoButton(
                      'Efectivo',
                      Icons.money,
                      AppColors.success,
                    ),
                    const SizedBox(width: 12),
                    _buildMetodoButton(
                      'Tarjeta',
                      Icons.credit_card,
                      Colors.blue,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_metodoSeleccionado == 'Tarjeta')
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.credit_card,
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${widget.total.toStringAsFixed(2)} €',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'PAGO EXACTO - SIN CAMBIO',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white30, width: 1),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'IMPORTE ENTREGADO',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              'Toca los botones para cambiar',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _importe.isEmpty || _importe == '0'
                              ? '0.00 €'
                              : '${double.tryParse(_importe)?.toStringAsFixed(2) ?? _importe} €',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_pagoCompleto && _cambio > 0) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade700,
                            Colors.green.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'PAGO COMPLETADO',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'PAGADO',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.white70,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_importeNumerico.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const Text(
                                        'EUR',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.arrow_forward,
                                color: Colors.white.withValues(alpha: 0.7),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'CAMBIO',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.green.shade700,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_cambio.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                      Text(
                                        'EUR',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else if (_pagoCompleto && _cambio == 0) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PAGO EXACTO',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Sin cambio - ${_importeNumerico.toStringAsFixed(2)} €',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade800,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.warning,
                            color: Colors.white70,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'FALTA POR PAGAR',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '${(widget.total - _importeNumerico).toStringAsFixed(2)} €',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _buildKeypadNumerico(),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'CANCELAR',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _pagoCompleto ? _cobrar : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _pagoCompleto
                                ? AppColors.success
                                : Colors.grey.shade600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _pagoCompleto
                                ? 'COBRAR ${widget.total.toStringAsFixed(2)} €'
                                : 'FALTAN ${(widget.total - _importeNumerico).toStringAsFixed(2)} €',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarEditorImporte() {
    final controller = TextEditingController(
      text: _importe == '0' ? '' : _importe,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Introducir importe',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    prefixText: '€ ',
                    prefixStyle: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildNumericPadSimple(controller),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      final value = double.tryParse(controller.text);
                      if (value != null && value > 0) {
                        _setImporte(value);
                        Navigator.pop(ctx);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'CONFIRMAR',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumericPadSimple(TextEditingController controller) {
    return Column(
      children: [
        Row(
          children: [
            _buildNumButton('1', controller),
            _buildNumButton('2', controller),
            _buildNumButton('3', controller),
          ],
        ),
        Row(
          children: [
            _buildNumButton('4', controller),
            _buildNumButton('5', controller),
            _buildNumButton('6', controller),
          ],
        ),
        Row(
          children: [
            _buildNumButton('7', controller),
            _buildNumButton('8', controller),
            _buildNumButton('9', controller),
          ],
        ),
        Row(
          children: [
            _buildNumButton('.', controller),
            _buildNumButton('0', controller),
            _buildBackspaceButton(controller),
          ],
        ),
      ],
    );
  }

  Widget _buildNumButton(String num, TextEditingController controller) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () {
              final text = controller.text;
              if (num == '.' && text.contains('.')) return;
              if (text.contains('.') && text.split('.').last.length >= 2)
                return;
              controller.text = text + num;
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 60,
              alignment: Alignment.center,
              child: Text(
                num,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton(TextEditingController controller) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () {
              if (controller.text.isNotEmpty) {
                controller.text = controller.text.substring(
                  0,
                  controller.text.length - 1,
                );
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 60,
              alignment: Alignment.center,
              child: const Icon(Icons.backspace_outlined, size: 24),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetodoButton(String metodo, IconData icon, Color color) {
    final isSelected = _metodoSeleccionado == metodo;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _metodoSeleccionado = metodo),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.grey.shade800,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                metodo,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadNumerico() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [_buildTecla('1'), _buildTecla('2'), _buildTecla('3')],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [_buildTecla('4'), _buildTecla('5'), _buildTecla('6')],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [_buildTecla('7'), _buildTecla('8'), _buildTecla('9')],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTecla('.', esDecimal: true),
            _buildTecla('0'),
            _buildTeclaBorrar(),
          ],
        ),
      ],
    );
  }

  Widget _buildTecla(String digito, {bool esDecimal = false}) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            if (esDecimal) {
              if (!_importe.contains('.')) {
                setState(() {
                  _importe = _importe.isEmpty ? '0.' : '$_importe.';
                });
              }
            } else {
              setState(() {
                if (_importe == '0') {
                  _importe = digito;
                } else {
                  final partes = _importe.split('.');
                  if (partes.length == 2 && partes[1].length >= 2) {
                    return;
                  }
                  _importe = '$_importe$digito';
                }
              });
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 80,
            height: 56,
            alignment: Alignment.center,
            child: Text(
              esDecimal ? ',' : digito,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeclaBorrar() {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: Colors.grey.shade700,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            setState(() {
              if (_importe.isNotEmpty) {
                _importe = _importe.substring(0, _importe.length - 1);
              }
            });
          },
          onLongPress: () {
            setState(() {
              _importe = '';
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 80,
            height: 56,
            alignment: Alignment.center,
            child: const Icon(
              Icons.backspace_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickButton(double amount) {
    return GestureDetector(
      onTap: () => _setImporte(amount),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade700),
        ),
        child: Text(
          '${amount.toInt()}€',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}

class _CalculadoraSheet extends StatefulWidget {
  const _CalculadoraSheet();

  @override
  State<_CalculadoraSheet> createState() => _CalculadoraSheetState();
}

class _CalculadoraSheetState extends State<_CalculadoraSheet> {
  String _display = '0';
  double _result = 0;
  String _operator = '';
  bool _shouldResetDisplay = false;

  void _onDigit(String digit) {
    setState(() {
      if (_shouldResetDisplay) {
        _display = digit;
        _shouldResetDisplay = false;
      } else {
        _display = _display == '0' ? digit : _display + digit;
      }
    });
  }

  void _onOperator(String op) {
    setState(() {
      _result = double.tryParse(_display) ?? 0;
      _operator = op;
      _shouldResetDisplay = true;
    });
  }

  void _onEquals() {
    setState(() {
      final current = double.tryParse(_display) ?? 0;
      switch (_operator) {
        case '+':
          _result += current;
          break;
        case '-':
          _result -= current;
          break;
        case 'x':
          _result *= current;
          break;
        case '/':
          if (current != 0) _result /= current;
          break;
      }
      _display = _result.toStringAsFixed(2);
      _operator = '';
      _shouldResetDisplay = true;
    });
  }

  void _onClear() {
    setState(() {
      _display = '0';
      _result = 0;
      _operator = '';
      _shouldResetDisplay = false;
    });
  }

  void _onPercent() {
    setState(() {
      final value = (double.tryParse(_display) ?? 0) / 100;
      _display = value.toStringAsFixed(2);
    });
  }

  void _onBackspace() {
    setState(() {
      if (_display.length > 1) {
        _display = _display.substring(0, _display.length - 1);
      } else {
        _display = '0';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _display,
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (_operator.isNotEmpty)
                    Text(
                      '${_result.toStringAsFixed(2)} $_operator',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildCalcButton('C', AppColors.error, null, () => _onClear()),
                _buildCalcButton('%', Colors.orange, null, () => _onPercent()),
                _buildCalcButton(
                  '',
                  Colors.grey.shade600,
                  Icons.backspace_outlined,
                  () => _onBackspace(),
                ),
                _buildCalcButton(
                  '÷',
                  Colors.orange,
                  null,
                  () => _onOperator('/'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildCalcButton('7', Colors.white, null, () => _onDigit('7')),
                _buildCalcButton('8', Colors.white, null, () => _onDigit('8')),
                _buildCalcButton('9', Colors.white, null, () => _onDigit('9')),
                _buildCalcButton(
                  '×',
                  Colors.orange,
                  null,
                  () => _onOperator('x'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildCalcButton('4', Colors.white, null, () => _onDigit('4')),
                _buildCalcButton('5', Colors.white, null, () => _onDigit('5')),
                _buildCalcButton('6', Colors.white, null, () => _onDigit('6')),
                _buildCalcButton(
                  '-',
                  Colors.orange,
                  null,
                  () => _onOperator('-'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildCalcButton('1', Colors.white, null, () => _onDigit('1')),
                _buildCalcButton('2', Colors.white, null, () => _onDigit('2')),
                _buildCalcButton('3', Colors.white, null, () => _onDigit('3')),
                _buildCalcButton(
                  '+',
                  Colors.orange,
                  null,
                  () => _onOperator('+'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildCalcButton(
                  '0',
                  Colors.white,
                  null,
                  () => _onDigit('0'),
                  flex: 2,
                ),
                _buildCalcButton('.', Colors.white, null, () {
                  if (!_display.contains('.')) _onDigit('.');
                }),
                _buildCalcButton(
                  '=',
                  AppColors.success,
                  null,
                  () => _onEquals(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalcButton(
    String text,
    Color textColor,
    IconData? icon,
    VoidCallback onTap, {
    int flex = 1,
  }) {
    final isOperator = ['+', '-', '×', '÷', '='].contains(text);
    final isAction = text == 'C' || text == '%';

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: isOperator
                ? Colors.orange
                : (isAction ? Colors.grey.shade700 : Colors.grey.shade800),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: icon != null
                    ? Icon(icon, color: textColor, size: 24)
                    : Text(
                        text,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectorClienteSheet extends ConsumerStatefulWidget {
  final Function(Cliente?) onClienteSelected;

  const _SelectorClienteSheet({required this.onClienteSelected});

  @override
  ConsumerState<_SelectorClienteSheet> createState() =>
      _SelectorClienteSheetState();
}

class _SelectorClienteSheetState extends ConsumerState<_SelectorClienteSheet> {
  final _buscadorController = TextEditingController();
  String _textoBusqueda = '';

  @override
  void dispose() {
    _buscadorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientes = ref.watch(clientesProvider);
    final clientesFiltrados = _textoBusqueda.isEmpty
        ? clientes
        : clientes
              .where(
                (c) =>
                    c.nombre.toLowerCase().contains(
                      _textoBusqueda.toLowerCase(),
                    ) ||
                    (c.telefono?.contains(_textoBusqueda) ?? false),
              )
              .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Seleccionar Cliente',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _buscadorController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o teléfono...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) => setState(() => _textoBusqueda = value),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => widget.onClienteSelected(null),
                icon: const Icon(Icons.person_add),
                label: const Text('Venta sin cliente'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: clientesFiltrados.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _textoBusqueda.isEmpty
                              ? 'No hay clientes registrados'
                              : 'No se encontraron clientes',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: clientesFiltrados.length,
                    itemBuilder: (context, index) {
                      final cliente = clientesFiltrados[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.1,
                            ),
                            child: const Icon(
                              Icons.person,
                              color: AppColors.primary,
                            ),
                          ),
                          title: Text(
                            cliente.nombre,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: cliente.telefono != null
                              ? Text(cliente.telefono!)
                              : null,
                          trailing: cliente.totalPedidos > 0
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${cliente.totalPedidos} pedidos',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                )
                              : null,
                          onTap: () => widget.onClienteSelected(cliente),
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
