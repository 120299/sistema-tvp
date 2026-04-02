import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/services/print_service.dart';
import '../providers/providers.dart';
import '../widgets/producto_personalizacion_dialog.dart';
import '../widgets/product_image_widget.dart';
import '../widgets/category_avatar.dart';

class MesaProductosScreen extends ConsumerStatefulWidget {
  final Mesa mesa;

  const MesaProductosScreen({super.key, required this.mesa});

  @override
  ConsumerState<MesaProductosScreen> createState() =>
      _MesaProductosScreenState();
}

class _MesaProductosScreenState extends ConsumerState<MesaProductosScreen> {
  final TextEditingController _buscadorController = TextEditingController();
  String _textoBusqueda = '';

  @override
  void dispose() {
    _buscadorController.dispose();
    super.dispose();
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        width: 300,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(imageRefreshTriggerProvider);
    ref.watch(mesasProvider);
    ref.watch(pedidosProvider);
    final categoriasRaw = ref.watch(categoriasProvider);
    final categoriasOrdenadas = List<CategoriaProducto>.from(categoriasRaw)
      ..sort((a, b) => a.orden.compareTo(b.orden));
    final productos = ref.watch(productosProvider);
    final categoriaSeleccionada = ref.watch(categoriaSeleccionadaProvider);

    final productosFiltrados = categoriaSeleccionada == null
        ? productos
        : productos
              .where((p) => p.categoriaId == categoriaSeleccionada)
              .toList();

    final productosAMostrar = _textoBusqueda.isNotEmpty
        ? productos
              .where(
                (p) => p.nombre.toLowerCase().contains(
                  _textoBusqueda.toLowerCase(),
                ),
              )
              .toList()
        : productosFiltrados;

    return Container(
      color: AppColors.lightBackground,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _buildHeader(),
                _buildCategorias(categoriaSeleccionada, categoriasOrdenadas),
                _buildBuscador(),
                Expanded(
                  child: _buildGridProductos(
                    productosAMostrar,
                    categoriasOrdenadas,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, color: AppColors.lightDivider),
          SizedBox(width: 380, child: _buildPanelPedido()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final pedidoActual = _getPedidoActual();
    final total = pedidoActual.fold<double>(
      0,
      (sum, item) => sum + item.subtotal,
    );
    final totalItems = pedidoActual.fold<int>(
      0,
      (sum, item) => sum + item.cantidad,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary,
            AppColors.secondary.withValues(alpha: 0.8),
          ],
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
                borderRadius: BorderRadius.zero,
              ),
              child: const Icon(
                Icons.table_restaurant,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mesa ${widget.mesa.numero}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$totalItems productos',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.zero,
              ),
              child: Row(
                children: [
                  const Icon(Icons.euro, color: AppColors.secondary, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    total.toStringAsFixed(2),
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
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

  Widget _buildCategorias(
    String? categoriaSeleccionada,
    List<CategoriaProducto> categorias,
  ) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.lightDivider)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categorias.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = categoriaSeleccionada == null;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: const Text('Todos'),
                avatar: isSelected ? null : const Icon(Icons.apps, size: 18),
                onSelected: (_) {
                  ref.read(categoriaSeleccionadaProvider.notifier).state = null;
                },
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                checkmarkColor: AppColors.primary,
              ),
            );
          }

          final categoria = categorias[index - 1];
          final isSelected = categoriaSeleccionada == categoria.id;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              avatar: CategoryAvatar(categoria: categoria, size: 20),
              label: Text(categoria.nombre),
              onSelected: (_) {
                ref.read(categoriaSeleccionadaProvider.notifier).state =
                    isSelected ? null : categoria.id;
              },
              selectedColor: categoria.color.withValues(alpha: 0.2),
              checkmarkColor: categoria.color,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBuscador() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.lightDivider)),
      ),
      child: TextField(
        controller: _buscadorController,
        decoration: InputDecoration(
          hintText: 'Buscar...',
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

  Widget _buildGridProductos(
    List<Producto> productos,
    List<CategoriaProducto> categorias,
  ) {
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
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 5 / 4,
      ),
      itemCount: productos.length,
      itemBuilder: (context, index) {
        final producto = productos[index];
        final categoria = categorias
            .where((c) => c.id == producto.categoriaId)
            .firstOrNull;
        return _buildProductCard(producto, categoria);
      },
    );
  }

  Widget _buildProductCard(Producto producto, CategoriaProducto? categoria) {
    final pedidoActual = _getPedidoActual();
    final itemEnPedido = pedidoActual
        .where((i) => i.productoId == producto.id)
        .firstOrNull;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
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
                    if (itemEnPedido != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.zero,
                          ),
                          child: Text(
                            '${itemEnPedido.cantidad}',
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
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          producto.nombre,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: producto.disponible ? null : Colors.grey,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${producto.precio.toStringAsFixed(2)} €',
                        style: TextStyle(
                          fontSize: 15,
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
    return ProductImageWidget(producto: producto, categoria: categoria);
  }

  List<PedidoItem> _getPedidoActual() {
    final mesas = ref.read(mesasProvider);
    final mesaActual = mesas.firstWhere(
      (m) => m.id == widget.mesa.id,
      orElse: () => widget.mesa,
    );
    if (mesaActual.pedidoActualId == null) return [];
    final pedidos = ref.read(pedidosProvider);
    final pedido = pedidos
        .where((p) => p.id == mesaActual.pedidoActualId)
        .firstOrNull;
    return pedido?.items ?? [];
  }

  Pedido? _getPedidoCompleto() {
    final mesas = ref.read(mesasProvider);
    final mesaActual = mesas.firstWhere(
      (m) => m.id == widget.mesa.id,
      orElse: () => widget.mesa,
    );
    if (mesaActual.pedidoActualId == null) return null;
    final pedidos = ref.read(pedidosProvider);
    return pedidos.where((p) => p.id == mesaActual.pedidoActualId).firstOrNull;
  }

  Widget _buildPanelPedido() {
    final pedidoActual = _getPedidoActual();

    if (pedidoActual.isEmpty) {
      return Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.rectangle,
                ),
                child: const Icon(
                  Icons.receipt_long,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Sin pedido',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Toca un producto para empezar',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    final total = pedidoActual.fold<double>(
      0,
      (sum, item) => sum + item.subtotal,
    );

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Text(
                  'Pedido',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Text(
                    '${pedidoActual.length} items',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: pedidoActual.length,
              itemBuilder: (context, index) {
                final item = pedidoActual[index];
                return _buildPedidoItemCard(item, index);
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
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _cobrarPedido(total),
                    icon: const Icon(Icons.payment),
                    label: const Text('Cobrar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPedidoItemCard(PedidoItem item, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      child: InkWell(
        onTap: () => _editarItem(item),
        borderRadius: BorderRadius.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.zero,
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
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${item.precioUnitario.toStringAsFixed(2)} € c/u',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.edit, size: 12, color: Colors.grey.shade400),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '${item.subtotal.toStringAsFixed(2)} €',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMiniButton(
                    Icons.remove,
                    () => _actualizarCantidad(index, item.cantidad - 1),
                    AppColors.error,
                  ),
                  const SizedBox(width: 4),
                  _buildMiniButton(
                    Icons.add,
                    () => _actualizarCantidad(index, item.cantidad + 1),
                    AppColors.success,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniButton(IconData icon, VoidCallback onTap, Color color) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.zero,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.zero,
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  void _agregarProducto(Producto producto) async {
    try {
      final mesaActual = ref
          .read(mesasProvider)
          .firstWhere((m) => m.id == widget.mesa.id);
      String pedidoId = mesaActual.pedidoActualId ?? '';

      if (pedidoId.isEmpty) {
        final cajeroActual = ref.read(cajeroActualProvider);
        final cajaActual = ref.read(cajaProvider);
        pedidoId = await ref
            .read(pedidosProvider.notifier)
            .crear(
              widget.mesa.id,
              cajeroId: cajeroActual?.id,
              cajeroNombre: cajeroActual?.nombre,
              cajaId: cajaActual?.id,
            );
        await ref.read(mesasProvider.notifier).ocupar(widget.mesa.id, pedidoId);
      }

      final esConfigurable =
          producto.esVariable ||
          (producto.ingredientes?.isNotEmpty ?? false) ||
          (producto.extras?.isNotEmpty ?? false);

      if (esConfigurable) {
        final resultado = await showDialog<PedidoItem>(
          context: context,
          builder: (ctx) => ProductoPersonalizacionDialog(
            producto: producto,
            onConfirm: (item) => Navigator.pop(ctx, item),
          ),
        );

        if (resultado != null && mounted) {
          VarianteProducto? variante;
          if (resultado.varianteId != null && producto.variantes != null) {
            variante = producto.variantes!
                .where((v) => v.id == resultado.varianteId)
                .firstOrNull;
          }

          final success = await ref
              .read(pedidosProvider.notifier)
              .agregarItem(
                pedidoId,
                producto,
                cantidad: resultado.cantidad,
                variante: variante,
                notas: resultado.notas,
                ingredientesQuitados: resultado.ingredientesQuitados,
                extrasSeleccionados: resultado.extrasSeleccionados,
              );

          if (success && mounted) {
            _mostrarMensaje('${producto.nombre} añadido');
            setState(() {});
          } else if (mounted) {
            _mostrarMensaje('Error al añadir ${producto.nombre}');
          }
        }
        return;
      }

      final success = await ref
          .read(pedidosProvider.notifier)
          .agregarItem(pedidoId, producto, cantidad: 1);

      if (success && mounted) {
        _mostrarMensaje('${producto.nombre} añadido');
        setState(() {});
      } else if (mounted) {
        _mostrarMensaje('Error al añadir ${producto.nombre}');
      }
    } catch (e) {
      if (mounted) {
        _mostrarMensaje('Error al añadir producto: $e');
      }
    }
  }

  void _actualizarCantidad(int index, int cantidad) async {
    try {
      final pedidoActual = _getPedidoActual();
      if (index >= pedidoActual.length) return;

      final item = pedidoActual[index];
      final mesaActual = ref
          .read(mesasProvider)
          .firstWhere((m) => m.id == widget.mesa.id);
      if (mesaActual.pedidoActualId == null) return;

      final pedidoId = mesaActual.pedidoActualId!;
      final success = await ref
          .read(pedidosProvider.notifier)
          .actualizarCantidad(pedidoId, item.id, cantidad);

      if (!success) {
        if (mounted) _mostrarMensaje('Error al actualizar cantidad');
        return;
      }

      final nuevoPedido = ref
          .read(pedidosProvider)
          .where((p) => p.id == pedidoId)
          .firstOrNull;

      if (nuevoPedido == null) return;

      if (nuevoPedido.items.isEmpty) {
        await ref.read(pedidosProvider.notifier).eliminar(pedidoId);
        await ref.read(mesasProvider.notifier).liberar(widget.mesa.id);
      }

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) _mostrarMensaje('Error al actualizar cantidad: $e');
    }
  }

  void _editarItem(PedidoItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (ctx) => _EditarItemSheet(
        item: item,
        onGuardar: (cantidad, precio, notas) async {
          try {
            final mesaActual = ref
                .read(mesasProvider)
                .firstWhere((m) => m.id == widget.mesa.id);
            if (mesaActual.pedidoActualId == null) return;

            final pedidoId = mesaActual.pedidoActualId!;

            if (cantidad <= 0) {
              final success = await ref
                  .read(pedidosProvider.notifier)
                  .actualizarCantidad(pedidoId, item.id, 0);
              if (!success) {
                if (mounted) _mostrarMensaje('Error al actualizar');
                return;
              }
              final pedidoActual = _getPedidoActual();
              if (pedidoActual.isEmpty) {
                await ref.read(pedidosProvider.notifier).eliminar(pedidoId);
                await ref.read(mesasProvider.notifier).liberar(widget.mesa.id);
              }
            } else {
              final pedido = ref
                  .read(pedidosProvider)
                  .where((p) => p.id == pedidoId)
                  .firstOrNull;
              if (pedido != null) {
                final itemsActualizados = pedido.items.map((i) {
                  if (i.id == item.id) {
                    return PedidoItem(
                      id: item.id,
                      productoId: item.productoId,
                      varianteId: item.varianteId,
                      productoNombre: item.productoNombre,
                      cantidad: cantidad,
                      precioUnitario: precio,
                      notas: notas,
                      ingredientesQuitados: item.ingredientesQuitados,
                      extrasSeleccionados: item.extrasSeleccionados,
                    );
                  }
                  return i;
                }).toList();
                final success = await ref
                    .read(pedidosProvider.notifier)
                    .actualizar(pedido.copyWith(items: itemsActualizados));
                if (!success && mounted) {
                  _mostrarMensaje('Error al guardar cambios');
                  return;
                }
              }
            }

            if (mounted) {
              Navigator.pop(ctx);
              setState(() {});
            }
          } catch (e) {
            if (mounted) _mostrarMensaje('Error al editar: $e');
          }
        },
        onEliminar: () async {
          try {
            final mesaActual = ref
                .read(mesasProvider)
                .firstWhere((m) => m.id == widget.mesa.id);
            if (mesaActual.pedidoActualId == null) return;
            final pedidoId = mesaActual.pedidoActualId!;
            final success = await ref
                .read(pedidosProvider.notifier)
                .actualizarCantidad(pedidoId, item.id, 0);

            if (!success) {
              if (mounted) _mostrarMensaje('Error al eliminar');
              return;
            }

            final pedidoActual = _getPedidoActual();
            if (pedidoActual.isEmpty) {
              await ref.read(pedidosProvider.notifier).eliminar(pedidoId);
              await ref.read(mesasProvider.notifier).liberar(widget.mesa.id);
            }

            if (mounted) {
              Navigator.pop(ctx);
              setState(() {});
            }
          } catch (e) {
            if (mounted) _mostrarMensaje('Error al eliminar: $e');
          }
        },
      ),
    );
  }

  void _cobrarPedido(double total) async {
    final mesaActual = ref
        .read(mesasProvider)
        .firstWhere((m) => m.id == widget.mesa.id);
    if (mesaActual.pedidoActualId == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) => _CobroSheet(
        total: total,
        onCobrar: (metodoPago) async {
          try {
            final negocio = ref.read(negocioProvider);
            final pedidoActual = _getPedidoActual();
            final pedidoId = mesaActual.pedidoActualId!;
            final cajaActual = ref.read(cajaProvider);

            final numeroTicket = await ref
                .read(negocioProvider.notifier)
                .obtenerSiguienteNumeroTicket();

            final cerrarSuccess = await ref
                .read(pedidosProvider.notifier)
                .cerrar(
                  pedidoId,
                  metodoPago,
                  numeroTicket: numeroTicket,
                  cajaId: cajaActual?.id,
                );

            if (!cerrarSuccess) {
              if (mounted) {
                _mostrarMensaje('Error al cerrar el pedido');
              }
              return;
            }

            for (final item in pedidoActual) {
              try {
                await ref
                    .read(productosProvider.notifier)
                    .decrementarStock(item.productoId, item.cantidad);
              } catch (e) {
                debugPrint('Error decrementando stock: $e');
              }
            }

            if (cajaActual != null) {
              await ref
                  .read(cajaProvider.notifier)
                  .registrarVenta(total, metodoPago, pedidoId: pedidoId);
            }

            final pedidoCompleto = _getPedidoCompleto();
            await ref.read(mesasProvider.notifier).liberar(widget.mesa.id);

            try {
              await PrintService.mostrarTicketPreview(
                context: context,
                items: pedidoActual,
                subtotal: pedidoActual.fold<double>(
                  0,
                  (sum, item) => sum + item.subtotal,
                ),
                ivaPorcentaje: negocio.ivaPorcentaje,
                metodoPago: metodoPago,
                negocio: negocio,
                mesaNumero: widget.mesa.numero.toString(),
                numeroTicket: numeroTicket,
                fechaVenta: pedidoCompleto?.horaApertura,
              );
            } catch (e) {
              debugPrint('Error imprimiendo ticket: $e');
            }

            if (mounted) {
              Navigator.pop(context);
              Navigator.pop(context);
              _mostrarMensaje('Venta completada');
            }
          } catch (e) {
            if (mounted) {
              _mostrarMensaje('Error al cobrar: $e');
            }
          }
        },
      ),
    );
  }
}

class _EditarItemSheet extends StatefulWidget {
  final PedidoItem item;
  final Function(int, double, String?) onGuardar;
  final VoidCallback onEliminar;

  const _EditarItemSheet({
    required this.item,
    required this.onGuardar,
    required this.onEliminar,
  });

  @override
  State<_EditarItemSheet> createState() => _EditarItemSheetState();
}

class _EditarItemSheetState extends State<_EditarItemSheet> {
  late int _cantidad;
  late double _precioUnitario;
  late TextEditingController _precioController;
  late TextEditingController _notasController;

  @override
  void initState() {
    super.initState();
    _cantidad = widget.item.cantidad;
    _precioUnitario = widget.item.precioUnitario;
    _precioController = TextEditingController(
      text: _precioUnitario.toStringAsFixed(2),
    );
    _notasController = TextEditingController(text: widget.item.notas ?? '');
  }

  @override
  void dispose() {
    _precioController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.zero,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.item.productoNombre,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text('Cantidad:'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: _cantidad > 1
                    ? () => setState(() => _cantidad--)
                    : null,
                color: AppColors.error,
              ),
              Container(
                width: 48,
                alignment: Alignment.center,
                child: Text(
                  '$_cantidad',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => setState(() => _cantidad++),
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Precio:'),
              const Spacer(),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _precioController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(prefixText: '€ '),
                  onChanged: (v) =>
                      setState(() => _precioUnitario = double.tryParse(v) ?? 0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notasController,
            decoration: const InputDecoration(
              labelText: 'Notas',
              hintText: 'Ej: Sin cebolla',
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.zero,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subtotal:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${(_cantidad * _precioUnitario).toStringAsFixed(2)} €',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
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
                  onPressed: () {
                    Navigator.pop(context);
                    _confirmarEliminar();
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('Eliminar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => widget.onGuardar(
                    _cantidad,
                    _precioUnitario,
                    _notasController.text.isEmpty
                        ? null
                        : _notasController.text,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                  child: const Text('Guardar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmarEliminar() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar'),
        content: Text('¿Eliminar "${widget.item.productoNombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onEliminar();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
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
                borderRadius: BorderRadius.zero,
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
          const Text('Método de pago:'),
          const SizedBox(height: 12),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.zero,
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
