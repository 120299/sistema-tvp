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
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _mesaAsignada,
                      isExpanded: true,
                      isDense: true,
                      hint: const Text('Sin mesa'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'Sin mesa',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ...mesasDisponibles.map(
                          (m) => DropdownMenuItem(
                            value: m.id,
                            child: Text(
                              'Mesa ${m.numero}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        ..._getMesasOcupadas().map(
                          (m) => DropdownMenuItem(
                            value: m.id,
                            child: Text(
                              'Mesa ${m.numero} (Ocupada)',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _mesaAsignada = value;
                          if (value != null) {
                            _cargarProductosMesa(value);
                          } else {
                            _carrito.clear();
                          }
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${total.toStringAsFixed(2)} €',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
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
                IconButton(
                  icon: const Icon(Icons.calculate, color: Colors.white),
                  onPressed: _mostrarCalculadora,
                  tooltip: 'Calculadora',
                ),
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
                if (_mesaAsignada != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _guardarPedidoMesa,
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar Mesa'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
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
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => setState(() => _carrito.clear()),
                    child: const Text('Limpiar pedido'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarritoItem(PedidoItem item, int index) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => setState(() => _carrito.removeAt(index)),
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
                      setState(() => _carrito.removeAt(index));
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

  void _mostrarCalculadora() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _CalculadoraSheet(),
    );
  }

  void _agregarProducto(Producto producto) {
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
    } else {
      setState(() {
        _carrito.add(
          PedidoItem(
            id: 'item_${DateTime.now().millisecondsSinceEpoch}',
            productoId: producto.id,
            productoNombre: producto.nombre,
            cantidad: 1,
            precioUnitario: producto.precio,
          ),
        );
      });
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CajaScreen()),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Ir a Caja'),
          ),
        ],
      ),
    );
  }

  void _cargarProductosMesa(String mesaId) {
    final mesa = ref.read(mesasProvider).firstWhere((m) => m.id == mesaId);

    if (mesa.pedidoActualId == null) {
      _carrito.clear();
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
      _carrito.clear();
    }
  }

  void _guardarPedidoMesa() async {
    if (_mesaAsignada == null || _carrito.isEmpty) return;

    final mesaActual = ref
        .read(mesasProvider)
        .firstWhere((m) => m.id == _mesaAsignada);
    String pedidoId = mesaActual.pedidoActualId ?? '';

    if (pedidoId.isEmpty) {
      pedidoId = await ref.read(pedidosProvider.notifier).crear(_mesaAsignada!);
      await ref.read(mesasProvider.notifier).ocupar(_mesaAsignada!, pedidoId);
    }

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

    setState(() => _carrito.clear());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pedido guardado para la mesa'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _cobrarPedido() async {
    if (_carrito.isEmpty) return;

    final negocio = ref.read(negocioProvider);
    final total = _carrito.fold<double>(0, (sum, item) => sum + item.subtotal);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _CobroSheet(
        total: total,
        onCobrar: (metodosPago) async {
          Navigator.pop(context);

          final pedidoId = await ref
              .read(pedidosProvider.notifier)
              .crear(_mesaAsignada ?? '');

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
            total: total,
            ivaPorcentaje: negocio.ivaPorcentaje,
            metodoPago: metodoTexto,
            negocio: negocio,
            mesaNumero: mesaNumero,
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
  final Function(Map<String, double>) onCobrar;

  const _CobroSheet({required this.total, required this.onCobrar});

  @override
  State<_CobroSheet> createState() => _CobroSheetState();
}

class _CobroSheetState extends State<_CobroSheet> {
  final _efectivoController = TextEditingController();
  final _tarjetaController = TextEditingController();
  bool _dividirPago = false;

  @override
  void initState() {
    super.initState();
    _efectivoController.text = widget.total.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _efectivoController.dispose();
    _tarjetaController.dispose();
    super.dispose();
  }

  double get _efectivo => double.tryParse(_efectivoController.text) ?? 0;
  double get _tarjeta => double.tryParse(_tarjetaController.text) ?? 0;
  double get _totalPagado => _efectivo + _tarjeta;
  double get _cambio => _totalPagado - widget.total;
  double get _faltaPagar => widget.total - _totalPagado;
  bool get _pagoCompleto => _totalPagado >= widget.total;

  void _cobrar() {
    if (!_pagoCompleto) return;

    final metodos = <String, double>{};
    if (_efectivo > 0) metodos['Efectivo'] = _efectivo;
    if (_tarjeta > 0) metodos['Tarjeta'] = _tarjeta;

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
            Text('Pagado: ${_totalPagado.toStringAsFixed(2)} €'),
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
              widget.onCobrar(metodos);
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.success,
                    AppColors.success.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    'TOTAL A COBRAR',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.total.toStringAsFixed(2)} €',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() {
                      _dividirPago = false;
                      _efectivoController.text = widget.total.toStringAsFixed(
                        2,
                      );
                      _tarjetaController.clear();
                    }),
                    icon: Icon(
                      _dividirPago
                          ? Icons.radio_button_unchecked
                          : Icons.check_circle,
                      size: 20,
                    ),
                    label: const Text('Pago Completo'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: !_dividirPago
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() {
                      _dividirPago = true;
                      _efectivoController.text = '';
                      _tarjetaController.text = '';
                    }),
                    icon: Icon(
                      _dividirPago
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 20,
                    ),
                    label: const Text('Dividir'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: _dividirPago
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (!_dividirPago) ...[
              _buildImporteField(
                controller: _efectivoController,
                label: 'Importe recibido (Efectivo)',
                color: AppColors.success,
              ),
            ] else ...[
              _buildImporteField(
                controller: _efectivoController,
                label: 'Efectivo',
                color: AppColors.success,
              ),
              const SizedBox(height: 12),
              _buildImporteField(
                controller: _tarjetaController,
                label: 'Tarjeta',
                color: AppColors.primary,
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    'Total:',
                    '${widget.total.toStringAsFixed(2)} €',
                  ),
                  if (_dividirPago || _efectivo > 0)
                    _buildInfoRow(
                      'Efectivo:',
                      '${_efectivo.toStringAsFixed(2)} €',
                    ),
                  if (_tarjeta > 0)
                    _buildInfoRow(
                      'Tarjeta:',
                      '${_tarjeta.toStringAsFixed(2)} €',
                    ),
                  const Divider(),
                  _buildInfoRow(
                    'Pagado:',
                    '${_totalPagado.toStringAsFixed(2)} €',
                    bold: true,
                  ),
                  if (_faltaPagar > 0)
                    _buildInfoRow(
                      'Falta:',
                      '${_faltaPagar.toStringAsFixed(2)} €',
                      color: AppColors.error,
                    )
                  else
                    _buildInfoRow(
                      'Cambio:',
                      '${_cambio.toStringAsFixed(2)} €',
                      color: AppColors.success,
                      bold: true,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _pagoCompleto ? _cobrar : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      _pagoCompleto
                          ? 'COBRAR'
                          : 'FALTAN ${_faltaPagar.toStringAsFixed(2)} €',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildImporteField({
    required TextEditingController controller,
    required String label,
    required Color color,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        prefixText: '€ ',
        prefixStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: color,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: 2),
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? color,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color,
              fontSize: bold ? 18 : 14,
            ),
          ),
        ],
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _display,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_operator.isNotEmpty)
                    Text(
                      '${_result.toStringAsFixed(2)} $_operator',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildCalcButton('C', AppColors.error, () => _onClear()),
                _buildCalcButton('%', Colors.grey, () => _onPercent()),
                _buildCalcButton('⌫', Colors.grey, () => _onBackspace()),
                _buildCalcButton(
                  '/',
                  AppColors.primary,
                  () => _onOperator('/'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildCalcButton('7', Colors.black, () => _onDigit('7')),
                _buildCalcButton('8', Colors.black, () => _onDigit('8')),
                _buildCalcButton('9', Colors.black, () => _onDigit('9')),
                _buildCalcButton(
                  'x',
                  AppColors.primary,
                  () => _onOperator('x'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildCalcButton('4', Colors.black, () => _onDigit('4')),
                _buildCalcButton('5', Colors.black, () => _onDigit('5')),
                _buildCalcButton('6', Colors.black, () => _onDigit('6')),
                _buildCalcButton(
                  '-',
                  AppColors.primary,
                  () => _onOperator('-'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildCalcButton('1', Colors.black, () => _onDigit('1')),
                _buildCalcButton('2', Colors.black, () => _onDigit('2')),
                _buildCalcButton('3', Colors.black, () => _onDigit('3')),
                _buildCalcButton(
                  '+',
                  AppColors.primary,
                  () => _onOperator('+'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildCalcButton(
                  '0',
                  Colors.black,
                  () => _onDigit('0'),
                  flex: 2,
                ),
                _buildCalcButton('.', Colors.black, () {
                  if (!_display.contains('.')) _onDigit('.');
                }),
                _buildCalcButton('=', AppColors.success, () => _onEquals()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalcButton(
    String text,
    Color color,
    VoidCallback onTap, {
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: color.withValues(
            alpha:
                text == '=' ||
                    text == '+' ||
                    text == '-' ||
                    text == 'x' ||
                    text == '/'
                ? 1
                : 0.15,
          ),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 60,
              alignment: Alignment.center,
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
