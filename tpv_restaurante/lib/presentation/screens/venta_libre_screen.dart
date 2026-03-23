import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/services/image_storage_service.dart';
import '../providers/providers.dart';

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
    final productosFiltrados = ref.watch(productosFiltradosProvider);
    final categorias = ref.watch(categoriasProvider);
    final categoriaSeleccionada = ref.watch(categoriaSeleccionadaProvider);
    final todasMesas = ref.watch(mesasProvider);
    final todosProductos = ref.watch(productosProvider);

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
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _buildHeader(mesasDisponibles),
                _buildCategorias(categoriaSeleccionada, categorias),
                _buildBuscador(),
                Expanded(child: _buildGridProductos(productosAMostrar)),
              ],
            ),
          ),
          Container(width: 1, color: AppColors.lightDivider),
          SizedBox(width: 380, child: _buildPanelCarrito()),
        ],
      ),
    );
  }

  Widget _buildHeader(List<Mesa> mesasDisponibles) {
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
                ),
              ),
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
                      hint: const Text('Sin mesa'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Sin mesa'),
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
                                const SizedBox(width: 8),
                                Text('Mesa ${m.numero} (Libre)'),
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
                                const SizedBox(width: 8),
                                Text('Mesa ${m.numero} (Ocupada)'),
                              ],
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _mesaAsignada = value);
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
    return FilterChip(
      selected: selected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Text(icono),
            const SizedBox(width: 4),
          ] else ...[
            Icon(selected ? Icons.check : icon, size: 16),
            const SizedBox(width: 4),
          ],
          Text(label),
        ],
      ),
      onSelected: (_) {
        ref.read(categoriaSeleccionadaProvider.notifier).state = selected
            ? null
            : id;
      },
      selectedColor: (color ?? AppColors.primary).withValues(alpha: 0.2),
      checkmarkColor: color ?? AppColors.primary,
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

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: productos.length,
      itemBuilder: (context, index) {
        final producto = productos[index];
        return _buildProductCard(producto);
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
        child: Container(
          decoration: BoxDecoration(
            color: producto.disponible ? Colors.white : Colors.grey.shade100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildProductImage(producto, categoria),
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
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              ),
            ],
          ),
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

  Widget _buildPanelCarrito() {
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
              padding: const EdgeInsets.symmetric(vertical: 8),
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${total.toStringAsFixed(2)} €',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_mesaAsignada != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _guardarPedidoMesa,
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar para Mesa'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _enviarACocina,
                          icon: const Icon(Icons.send),
                          label: const Text('Cocina'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _cobrarPedido,
                          icon: const Icon(Icons.payment),
                          label: const Text('Cobrar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _enviarACocina,
                          icon: const Icon(Icons.send),
                          label: const Text('Cocina'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _cobrarPedido,
                          icon: const Icon(Icons.payment),
                          label: const Text('Cobrar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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
      child: ListTile(
        dense: true,
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              '${item.cantidad}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        title: Text(item.productoNombre, style: const TextStyle(fontSize: 13)),
        subtitle: Text(
          '${item.precioUnitario.toStringAsFixed(2)} €',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${item.subtotal.toStringAsFixed(2)} €',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
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
              child: const Icon(
                Icons.remove_circle_outline,
                size: 20,
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () {
                setState(() {
                  _carrito[index] = item.copyWith(cantidad: item.cantidad + 1);
                });
              },
              child: const Icon(
                Icons.add_circle_outline,
                size: 20,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _agregarProducto(Producto producto) {
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

  void _enviarACocina() async {
    if (_carrito.isEmpty) return;

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

    await ref.read(pedidosProvider.notifier).enviarACocina(pedidoId);

    setState(() => _carrito.clear());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enviado a cocina'),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CobroSheet(
        total: total,
        onCobrar: (metodoPago) async {
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

          await ref.read(pedidosProvider.notifier).cerrar(pedidoId, metodoPago);

          if (_mesaAsignada != null) {
            await ref.read(mesasProvider.notifier).liberar(_mesaAsignada!);
          }

          setState(() => _carrito.clear());
          _mesaAsignada = null;

          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Venta completada - $metodoPago'),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 1),
              ),
            );
          }
        },
      ),
    );
  }
}

class _CobroSheet extends StatefulWidget {
  final double total;
  final Function(String) onCobrar;

  const _CobroSheet({required this.total, required this.onCobrar});

  @override
  State<_CobroSheet> createState() => _CobroSheetState();
}

class _CobroSheetState extends State<_CobroSheet> {
  String _metodoPago = 'Efectivo';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Total a Cobrar',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.total.toStringAsFixed(2)} €',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildMetodoButton(
                  Icons.money,
                  'Efectivo',
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetodoButton(
                  Icons.credit_card,
                  'Tarjeta',
                  AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onCobrar(_metodoPago),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text('Cobrar $_metodoPago'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetodoButton(IconData icon, String texto, Color color) {
    final selected = _metodoPago == texto;
    return InkWell(
      onTap: () => setState(() => _metodoPago = texto),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: selected ? Colors.white : color),
            const SizedBox(height: 8),
            Text(
              texto,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
