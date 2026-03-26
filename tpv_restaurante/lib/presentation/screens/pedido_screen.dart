import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../providers/providers.dart';
import '../widgets/product_card.dart';
import '../widgets/category_chip.dart';
import '../widgets/ticket_widget.dart';

class PedidoScreen extends ConsumerStatefulWidget {
  final Mesa mesa;

  const PedidoScreen({super.key, required this.mesa});

  @override
  ConsumerState<PedidoScreen> createState() => _PedidoScreenState();
}

class _PedidoScreenState extends ConsumerState<PedidoScreen> {
  late String _pedidoId;
  bool _pedidoCreado = false;

  @override
  void initState() {
    super.initState();
    if (widget.mesa.pedidoActualId != null) {
      _pedidoId = widget.mesa.pedidoActualId!;
      _pedidoCreado = true;
    }
  }

  void _crearPedido() {
    final cajeroActual = ref.read(cajeroActualProvider);
    ref
        .read(pedidosProvider.notifier)
        .crear(
          widget.mesa.id,
          cajeroId: cajeroActual?.id,
          cajeroNombre: cajeroActual?.nombre,
        )
        .then((id) {
          setState(() => _pedidoId = id);
        });
    ref.read(mesasProvider.notifier).ocupar(widget.mesa.id, _pedidoId);
    setState(() => _pedidoCreado = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_pedidoCreado && widget.mesa.estado != EstadoMesa.ocupada) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _crearPedido());
    }

    final productos = ref.watch(productosFiltradosProvider);
    final categoriaSeleccionada = ref.watch(categoriaSeleccionadaProvider);
    final categorias = ref.watch(categoriasProvider);
    final pedido = ref.watch(pedidosProvider.notifier).getPorId(_pedidoId);

    return Scaffold(
      appBar: AppBar(
        title: Text('Mesa ${widget.mesa.numero}'),
        actions: [
          if (pedido != null && pedido.items.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.send),
              tooltip: 'Enviar a cocina',
              onPressed: () => _enviarACocina(pedido),
            ),
            IconButton(
              icon: const Icon(Icons.receipt_long),
              tooltip: 'Ver ticket',
              onPressed: () => _mostrarTicket(context, pedido),
            ),
            IconButton(
              icon: const Icon(Icons.payment),
              tooltip: 'Cobrar',
              onPressed: () => _mostrarCobro(context, pedido),
            ),
          ],
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _buildCategorias(categoriaSeleccionada, categorias),
                Expanded(child: _buildGridProductos(productos)),
              ],
            ),
          ),
          Container(width: 1, color: Colors.grey[300]),
          Expanded(flex: 2, child: _buildPanelPedido(pedido)),
        ],
      ),
    );
  }

  Widget _buildCategorias(
    String? categoriaSeleccionada,
    List<CategoriaProducto> categorias,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                ref.read(categoriaSeleccionadaProvider.notifier).state = null;
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: categoriaSeleccionada == null
                      ? AppColors.secondary
                      : AppColors.surface,
                  borderRadius: BorderRadius.zero,
                  border: Border.all(
                    color: categoriaSeleccionada == null
                        ? AppColors.secondary
                        : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  'Todos',
                  style: TextStyle(
                    color: categoriaSeleccionada == null
                        ? Colors.white
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ...categorias.map((categoria) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CategoryChip(
                  categoria: categoria,
                  isSelected: categoriaSeleccionada == categoria.id,
                  onTap: () {
                    ref.read(categoriaSeleccionadaProvider.notifier).state =
                        categoria.id;
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildGridProductos(List<Producto> productos) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 4;
        if (constraints.maxWidth < 900) crossAxisCount = 3;
        if (constraints.maxWidth < 600) crossAxisCount = 2;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 5 / 4,
          ),
          itemCount: productos.length,
          itemBuilder: (context, index) {
            final producto = productos[index];
            return ProductCard(
              producto: producto,
              showEditIcon: false,
              onTap: () => _agregarProducto(producto),
            );
          },
        );
      },
    );
  }

  Widget _buildPanelPedido(Pedido? pedido) {
    if (pedido == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pedido Actual',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${pedido.items.length} items',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Expanded(
            child: pedido.items.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Sin productos',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Toca los productos para añadirlos',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: pedido.items.length,
                    itemBuilder: (context, index) {
                      return _buildItemPedido(pedido.items[index]);
                    },
                  ),
          ),
          _buildResumenPedido(pedido),
        ],
      ),
    );
  }

  Widget _buildItemPedido(PedidoItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.zero,
              ),
              child: Center(
                child: Text(
                  '${item.cantidad}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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
                  ),
                  Text(
                    '${item.precioUnitario.toStringAsFixed(2)} €',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  color: AppColors.error,
                  iconSize: 20,
                  onPressed: () => _actualizarCantidad(item, -1),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppColors.success,
                  iconSize: 20,
                  onPressed: () => _actualizarCantidad(item, 1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenPedido(Pedido pedido) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal:', style: TextStyle(color: Colors.grey)),
              Text('${pedido.subtotal.toStringAsFixed(2)} €'),
            ],
          ),
          if (pedido.montoPropina > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Propina (${pedido.porcentajePropina.toStringAsFixed(0)}%):',
                  style: const TextStyle(color: Colors.grey),
                ),
                Text('+${pedido.montoPropina.toStringAsFixed(2)} €'),
              ],
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('IVA (10%):', style: TextStyle(color: Colors.grey)),
              Text('${pedido.impuesto.toStringAsFixed(2)} €'),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '${pedido.total.toStringAsFixed(2)} €',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _agregarProducto(Producto producto) {
    if (!_pedidoCreado) _crearPedido();
    ref.read(pedidosProvider.notifier).agregarItem(_pedidoId, producto);
  }

  void _actualizarCantidad(PedidoItem item, int delta) {
    ref
        .read(pedidosProvider.notifier)
        .actualizarCantidad(_pedidoId, item.id, item.cantidad + delta);
  }

  void _enviarACocina(Pedido pedido) {
    ref.read(pedidosProvider.notifier).enviarACocina(_pedidoId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pedido enviado a cocina'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _mostrarTicket(BuildContext context, Pedido pedido) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) =>
            _buildTicketContent(pedido, scrollController),
      ),
    );
  }

  Widget _buildTicketContent(Pedido pedido, ScrollController controller) {
    final negocio = ref.watch(negocioProvider);
    return Container(
      padding: const EdgeInsets.all(24),
      child: ListView(
        controller: controller,
        children: [
          Center(
            child: Text(
              negocio.nombre,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          if (negocio.slogan != null)
            Center(
              child: Text(
                negocio.slogan!,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              negocio.direccion,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Center(
            child: Text(negocio.ciudad, style: const TextStyle(fontSize: 12)),
          ),
          Center(
            child: Text(
              'CIF: ${negocio.cifNif ?? "N/A"}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mesa ${widget.mesa.numero}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${pedido.horaApertura.day}/${pedido.horaApertura.month}/${pedido.horaApertura.year} ${pedido.horaApertura.hour}:${pedido.horaApertura.minute.toString().padLeft(2, '0')}',
              ),
            ],
          ),
          Text(
            'Camarero: ${pedido.mesero ?? "N/A"}',
            style: const TextStyle(color: Colors.grey),
          ),
          const Divider(height: 32),
          ...pedido.items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(width: 30, child: Text('${item.cantidad}x')),
                  Expanded(child: Text(item.productoNombre)),
                  Text('${item.subtotal.toStringAsFixed(2)} €'),
                ],
              ),
            ),
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal'),
              Text('${pedido.subtotal.toStringAsFixed(2)} €'),
            ],
          ),
          if (pedido.montoPropina > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Propina (${pedido.porcentajePropina.toStringAsFixed(0)}%)',
                ),
                Text('+${pedido.montoPropina.toStringAsFixed(2)} €'),
              ],
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('IVA (10%)'),
              Text('${pedido.impuesto.toStringAsFixed(2)} €'),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                '${pedido.total.toStringAsFixed(2)} €',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Center(
            child: Text(
              '¡Gracias por su visita!',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarCobro(BuildContext context, Pedido pedido) {
    double porcentajePropina = 0;
    int numeroPersonas = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Opciones de Pago',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              const Text(
                'Dividir cuenta entre:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: numeroPersonas > 1
                        ? () => setState(() => numeroPersonas--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    '$numeroPersonas persona${numeroPersonas > 1 ? 's' : ''} - ${(pedido.total / numeroPersonas).toStringAsFixed(2)} €/persona',
                    style: const TextStyle(fontSize: 16),
                  ),
                  IconButton(
                    onPressed: () => setState(() => numeroPersonas++),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Propina:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Row(
                children: [
                  for (final pct in [0, 5, 10, 15])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('$pct%'),
                        selected: porcentajePropina == pct,
                        onSelected: (selected) => setState(
                          () =>
                              porcentajePropina = selected ? pct.toDouble() : 0,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.zero,
                ),
                child: Column(
                  children: [
                    Text(
                      'Total a Cobrar',
                      style: TextStyle(color: AppColors.primary),
                    ),
                    Text(
                      '${(pedido.total * (1 + porcentajePropina / 100)).toStringAsFixed(2)} €',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Método de pago:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildBotonPago(
                      Icons.money,
                      'Efectivo',
                      () => _procesarCobro('Efectivo', porcentajePropina),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBotonPago(
                      Icons.credit_card,
                      'Tarjeta',
                      () => _procesarCobro('Tarjeta', porcentajePropina),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBotonPago(
                      Icons.call_split,
                      'Mixto',
                      () => _procesarCobro('Mixto', porcentajePropina),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBotonPago(IconData icono, String texto, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.zero,
          border: Border.all(color: AppColors.primary),
        ),
        child: Column(
          children: [
            Icon(icono, size: 28, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(
              texto,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _procesarCobro(String metodoPago, double porcentajePropina) {
    final notifier = ref.read(pedidosProvider.notifier);
    final negocio = ref.read(negocioProvider);
    final pedido = notifier.getPorId(_pedidoId);

    if (pedido != null) {
      final itemsParaTicket = List<PedidoItem>.from(pedido.items);

      notifier.cerrar(_pedidoId, metodoPago);
      ref.read(mesasProvider.notifier).liberar(widget.mesa.id);

      Navigator.pop(context);
      Navigator.pop(context);

      TicketPrintHelper.showPrintDialog(
        context,
        items: itemsParaTicket,
        subtotal: pedido.subtotal,
        porcentajePropina: porcentajePropina,
        ivaPorcentaje: negocio.ivaPorcentaje,
        metodoPago: metodoPago,
        negocio: negocio,
        mesaNumero: widget.mesa.numero.toString(),
        onImprimir: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Abriendo diálogo de impresión...'),
              backgroundColor: AppColors.primary,
            ),
          );
        },
        onCerrar: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pedido cobrado con $metodoPago'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );
        },
      );
    } else {
      ref.read(mesasProvider.notifier).liberar(widget.mesa.id);
      Navigator.pop(context);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pedido cobrado con $metodoPago'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
