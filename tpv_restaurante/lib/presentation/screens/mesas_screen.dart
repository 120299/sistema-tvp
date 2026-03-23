import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../providers/providers.dart';

class MesasScreen extends ConsumerStatefulWidget {
  const MesasScreen({super.key});

  @override
  ConsumerState<MesasScreen> createState() => _MesasScreenState();
}

class _MesasScreenState extends ConsumerState<MesasScreen> {
  String _filtroEstado = 'todas';

  @override
  Widget build(BuildContext context) {
    final mesas = ref.watch(mesasProvider);
    final mesasFiltradas = _filtrarMesas(mesas);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Column(
        children: [
          _buildHeader(mesas),
          _buildFiltros(),
          Expanded(child: _buildMesasGrid(mesasFiltradas)),
        ],
      ),
    );
  }

  List<Mesa> _filtrarMesas(List<Mesa> mesas) {
    switch (_filtroEstado) {
      case 'libres':
        return mesas.where((m) => m.estado == EstadoMesa.libre).toList();
      case 'ocupadas':
        return mesas.where((m) => m.estado == EstadoMesa.ocupada).toList();
      case 'reservadas':
        return mesas.where((m) => m.estado == EstadoMesa.reservada).toList();
      default:
        return mesas;
    }
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

  Widget _buildFiltros() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          _buildFiltroChip('todas', 'Todas'),
          const SizedBox(width: 8),
          _buildFiltroChip('libres', 'Libres', AppColors.success),
          const SizedBox(width: 8),
          _buildFiltroChip('ocupadas', 'Ocupadas', AppColors.warning),
          const SizedBox(width: 8),
          _buildFiltroChip('reservadas', 'Reservas', AppColors.mesaReservada),
        ],
      ),
    );
  }

  Widget _buildFiltroChip(String valor, String label, [Color? color]) {
    final selected = _filtroEstado == valor;
    return FilterChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) => setState(() => _filtroEstado = valor),
      selectedColor: (color ?? AppColors.primary).withValues(alpha: 0.2),
      checkmarkColor: color ?? AppColors.primary,
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

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CobroSheet(
        total: pedido.total,
        onCobrar: (metodoPago) async {
          await ref
              .read(pedidosProvider.notifier)
              .cerrar(pedido.id, metodoPago);
          await ref.read(mesasProvider.notifier).liberar(mesa.id);
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
