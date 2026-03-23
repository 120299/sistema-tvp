import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/services/print_service.dart';
import '../providers/providers.dart';

class MesasScreen extends ConsumerStatefulWidget {
  const MesasScreen({super.key});

  @override
  ConsumerState<MesasScreen> createState() => _MesasScreenState();
}

class _MesasScreenState extends ConsumerState<MesasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Todas', 'Libres', 'Ocupadas', 'Reservas'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Mesa> _getMesasFiltradas(List<Mesa> todasMesas) {
    switch (_tabController.index) {
      case 1:
        return todasMesas.where((m) => m.estado == EstadoMesa.libre).toList();
      case 2:
        return todasMesas.where((m) => m.estado == EstadoMesa.ocupada).toList();
      case 3:
        return todasMesas
            .where((m) => m.estado == EstadoMesa.reservada)
            .toList();
      default:
        return todasMesas;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mesas = ref.watch(mesasProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Column(
        children: [
          _buildHeader(mesas),
          _buildTabBar(),
          Expanded(child: _buildMesasGrid(_getMesasFiltradas(mesas))),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        onTap: (_) => setState(() {}),
        labelColor: AppColors.primary,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: [
          Tab(text: 'Todas (${ref.watch(mesasProvider).length})'),
          Tab(
            text:
                'Libres (${ref.watch(mesasProvider).where((m) => m.estado == EstadoMesa.libre).length})',
          ),
          Tab(
            text:
                'Ocupadas (${ref.watch(mesasProvider).where((m) => m.estado == EstadoMesa.ocupada).length})',
          ),
          Tab(
            text:
                'Reservas (${ref.watch(mesasProvider).where((m) => m.estado == EstadoMesa.reservada).length})',
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(List<Mesa> mesas) {
    final libres = mesas.where((m) => m.estado == EstadoMesa.libre).length;
    final ocupadas = mesas.where((m) => m.estado == EstadoMesa.ocupada).length;
    final reservadas = mesas
        .where((m) => m.estado == EstadoMesa.reservada)
        .length;

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
                  Icons.table_restaurant,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Mesas',
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
                child: Text(
                  '${mesas.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatBadge(libres, 'Libres', AppColors.success),
              const SizedBox(width: 8),
              _buildStatBadge(ocupadas, 'Ocupadas', AppColors.warning),
              const SizedBox(width: 8),
              _buildStatBadge(reservadas, 'Reservas', AppColors.mesaReservada),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(int count, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMesasGrid(List<Mesa> mesas) {
    if (mesas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_restaurant, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No hay mesas',
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
        childAspectRatio: 1.1,
      ),
      itemCount: mesas.length,
      itemBuilder: (context, index) => _buildMesaCard(mesas[index]),
    );
  }

  Widget _buildMesaCard(Mesa mesa) {
    final estadoData = _getEstadoData(mesa.estado);
    final pedidoActual = mesa.pedidoActualId != null
        ? ref
              .read(pedidosProvider)
              .where((p) => p.id == mesa.pedidoActualId)
              .firstOrNull
        : null;
    final totalPedido =
        pedidoActual?.items.fold<double>(
          0,
          (sum, item) => sum + item.subtotal,
        ) ??
        0;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: () => _mostrarOpcionesMesa(context, mesa),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [estadoData.color.withValues(alpha: 0.1), Colors.white],
            ),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: estadoData.color.withValues(alpha: 0.2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          estadoData.icono,
                          size: 14,
                          color: estadoData.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          estadoData.texto,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: estadoData.color,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.people,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${mesa.capacidad}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.table_restaurant,
                        size: 40,
                        color: estadoData.color,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Mesa ${mesa.numero}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (mesa.estado == EstadoMesa.ocupada &&
                          totalPedido > 0) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${totalPedido.toStringAsFixed(2)} €',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
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

  _EstadoData _getEstadoData(EstadoMesa estado) {
    switch (estado) {
      case EstadoMesa.libre:
        return _EstadoData(AppColors.success, 'Libre', Icons.check_circle);
      case EstadoMesa.ocupada:
        return _EstadoData(AppColors.warning, 'Ocupada', Icons.restaurant);
      case EstadoMesa.reservada:
        return _EstadoData(AppColors.mesaReservada, 'Reservada', Icons.event);
      case EstadoMesa.necesitaAtencion:
        return _EstadoData(
          AppColors.error,
          'Atención',
          Icons.notification_important,
        );
    }
  }

  void _mostrarOpcionesMesa(BuildContext context, Mesa mesa) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getEstadoData(
                        mesa.estado,
                      ).color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.table_restaurant,
                      color: _getEstadoData(mesa.estado).color,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mesa ${mesa.numero}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${mesa.capacidad} personas',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (mesa.estado == EstadoMesa.libre) ...[
              _buildOpcion(
                Icons.add_circle,
                'Abrir Mesa',
                AppColors.success,
                () {
                  Navigator.pop(context);
                  _abrirMesa(mesa);
                },
              ),
              _buildOpcion(
                Icons.event_available,
                'Reservar',
                AppColors.mesaReservada,
                () {
                  Navigator.pop(context);
                  ref.read(mesasProvider.notifier).marcarReservada(mesa.id);
                },
              ),
            ],
            if (mesa.estado == EstadoMesa.ocupada) ...[
              _buildOpcion(
                Icons.visibility,
                'Ver Pedido',
                AppColors.primary,
                () {
                  Navigator.pop(context);
                  _verPedidoMesa(mesa);
                },
              ),
              _buildOpcion(Icons.payment, 'Cobrar', AppColors.success, () {
                Navigator.pop(context);
                _cobrarMesa(mesa);
              }),
              _buildOpcion(Icons.cancel, 'Cancelar', AppColors.error, () {
                Navigator.pop(context);
                _cancelarMesa(mesa);
              }),
            ],
            if (mesa.estado == EstadoMesa.reservada) ...[
              _buildOpcion(
                Icons.check_circle,
                'Activar Reserva',
                AppColors.success,
                () {
                  Navigator.pop(context);
                  _abrirMesa(mesa);
                },
              ),
            ],
            if (mesa.estado == EstadoMesa.necesitaAtencion) ...[
              _buildOpcion(Icons.check, 'Atender', AppColors.primary, () {
                Navigator.pop(context);
                ref.read(mesasProvider.notifier).liberar(mesa.id);
              }),
            ],
            _buildOpcion(Icons.delete, 'Eliminar Mesa', AppColors.error, () {
              Navigator.pop(context);
              _eliminarMesa(mesa);
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOpcion(
    IconData icono,
    String texto,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icono, color: color, size: 20),
      ),
      title: Text(
        texto,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      onTap: onTap,
    );
  }

  void _abrirMesa(Mesa mesa) async {
    final pedidoId = await ref.read(pedidosProvider.notifier).crear(mesa.id);
    await ref.read(mesasProvider.notifier).ocupar(mesa.id, pedidoId);
  }

  void _verPedidoMesa(Mesa mesa) {
    final pedido = mesa.pedidoActualId != null
        ? ref
              .read(pedidosProvider)
              .where((p) => p.id == mesa.pedidoActualId)
              .firstOrNull
        : null;

    if (pedido == null) return;

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
        builder: (context, scrollController) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Pedido - Mesa ${mesa.numero}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Total: ${pedido.total.toStringAsFixed(2)} €',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: pedido.items.length,
                itemBuilder: (context, index) {
                  final item = pedido.items[index];
                  return ListTile(
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
                    title: Text(item.productoNombre),
                    trailing: Text(
                      '${item.subtotal.toStringAsFixed(2)} €',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _cobrarMesa(Mesa mesa) async {
    final pedido = mesa.pedidoActualId != null
        ? ref
              .read(pedidosProvider)
              .where((p) => p.id == mesa.pedidoActualId)
              .firstOrNull
        : null;

    if (pedido == null) return;

    final negocio = ref.read(negocioProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
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
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
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
                    '${pedido.total.toStringAsFixed(2)} €',
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Mesa ${mesa.numero}',
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Selecciona método de pago',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetodoButtonMesa(
                    Icons.money,
                    'Efectivo',
                    AppColors.success,
                    () async {
                      await _procesarCobro(mesa, pedido, 'Efectivo', negocio);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetodoButtonMesa(
                    Icons.credit_card,
                    'Tarjeta',
                    AppColors.primary,
                    () async {
                      await _procesarCobro(mesa, pedido, 'Tarjeta', negocio);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMetodoButtonMesa(
    IconData icon,
    String texto,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              texto,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _procesarCobro(
    Mesa mesa,
    Pedido pedido,
    String metodoPago,
    DatosNegocio negocio,
  ) async {
    Navigator.pop(context);

    await ref.read(pedidosProvider.notifier).cerrar(pedido.id, metodoPago);
    await ref.read(mesasProvider.notifier).liberar(mesa.id);
    await ref
        .read(cajaProvider.notifier)
        .registrarVenta(pedido.total, metodoPago, pedidoId: pedido.id);

    await PrintService.printTicket(
      items: pedido.items,
      total: pedido.total,
      ivaPorcentaje: negocio.ivaPorcentaje,
      metodoPago: metodoPago,
      negocio: negocio,
      mesaNumero: mesa.numero.toString(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Venta completada - $metodoPago'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _cancelarMesa(Mesa mesa) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar Pedido'),
        content: const Text('¿Cancelar el pedido y liberar la mesa?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (mesa.pedidoActualId != null) {
                final pedido = ref
                    .read(pedidosProvider)
                    .where((p) => p.id == mesa.pedidoActualId)
                    .firstOrNull;
                if (pedido != null) {
                  await ref
                      .read(pedidosProvider.notifier)
                      .cerrar(pedido.id, 'Cancelado');
                }
              }
              await ref.read(mesasProvider.notifier).liberar(mesa.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
  }

  void _eliminarMesa(Mesa mesa) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Mesa'),
        content: Text('¿Eliminar Mesa ${mesa.numero}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(mesasProvider.notifier).eliminar(mesa.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _EstadoData {
  final Color color;
  final String texto;
  final IconData icono;

  _EstadoData(this.color, this.texto, this.icono);
}
