import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../providers/providers.dart';
import 'mesa_productos_screen.dart';

class MesaDetalleScreen extends ConsumerStatefulWidget {
  final Mesa mesa;

  const MesaDetalleScreen({super.key, required this.mesa});

  @override
  ConsumerState<MesaDetalleScreen> createState() => _MesaDetalleScreenState();
}

class _MesaDetalleScreenState extends ConsumerState<MesaDetalleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filtroMetodo = 'Todos';
  DateTime? _fechaFiltro;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mesaActual = ref
        .watch(mesasProvider)
        .firstWhere((m) => m.id == widget.mesa.id, orElse: () => widget.mesa);
    final estadoData = _getEstadoData(mesaActual.estado);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text('Mesa ${widget.mesa.numero}'),
        backgroundColor: estadoData.color,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Información', icon: Icon(Icons.info_outline)),
            Tab(text: 'Historial', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildEstadoHeader(mesaActual, estadoData),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(mesaActual),
                _buildHistorialTab(mesaActual),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(mesaActual),
    );
  }

  Widget _buildEstadoHeader(Mesa mesa, _EstadoData estadoData) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: estadoData.color,
        boxShadow: [
          BoxShadow(
            color: estadoData.color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.zero,
              ),
              child: Icon(estadoData.icono, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    estadoData.texto,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (mesa.horaApertura != null)
                    Text(
                      'Desde ${DateFormat('HH:mm').format(mesa.horaApertura!)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.zero,
              ),
              child: Column(
                children: [
                  Text(
                    '${mesa.capacidad}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: estadoData.color,
                    ),
                  ),
                  Text(
                    'pers.',
                    style: TextStyle(fontSize: 10, color: estadoData.color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTab(Mesa mesa) {
    final negocio = ref.read(negocioProvider);
    final pedidoActual = _getPedidoActual(mesa);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pedidoActual != null) ...[
            _buildPedidoCard(mesa, pedidoActual, negocio),
            const SizedBox(height: 14),
          ],
          _buildAccionesCard(mesa),
          const SizedBox(height: 14),
          if (mesa.estado == EstadoMesa.ocupada) ...[
            _buildTiempoCard(mesa),
            const SizedBox(height: 14),
          ],
          _buildInfoCard(mesa),
        ],
      ),
    );
  }

  Widget _buildPedidoCard(Mesa mesa, Pedido pedido, DatosNegocio negocio) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.15),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: const Icon(
                    Icons.receipt,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pedido Activo',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'En curso',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.15),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Text(
                    '${pedido.items.length} items',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            ...pedido.items
                .take(3)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.zero,
                          ),
                          child: Center(
                            child: Text(
                              '${item.cantidad}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.productoNombre,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Text(
                          '${item.subtotal.toStringAsFixed(2)} €',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            if (pedido.items.length > 3) ...[
              const SizedBox(height: 6),
              Text(
                '+${pedido.items.length - 3} más...',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${pedido.total.toStringAsFixed(2)} €',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccionesCard(Mesa mesa) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Acciones Rápidas',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (mesa.estado == EstadoMesa.libre) ...[
                  _buildAccionBoton(
                    Icons.add_circle,
                    'Abrir Mesa',
                    () => _nuevoPedido(mesa),
                    AppColors.secondary,
                  ),
                  _buildAccionBoton(
                    Icons.event_available,
                    'Reservar',
                    () => _reservarMesa(mesa),
                    AppColors.mesaReservada,
                  ),
                ],
                if (mesa.estado == EstadoMesa.ocupada) ...[
                  _buildAccionBoton(Icons.restaurant_menu, 'Añadir', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MesaProductosScreen(mesa: mesa),
                      ),
                    );
                  }, AppColors.primary),
                  _buildAccionBoton(
                    Icons.payment,
                    'Cobrar',
                    () => _cobrarYLiberar(mesa),
                    AppColors.success,
                  ),
                  _buildAccionBoton(
                    Icons.cancel,
                    'Cancelar',
                    () => _cancelarPedido(mesa),
                    AppColors.error,
                  ),
                ],
                if (mesa.estado == EstadoMesa.reservada)
                  _buildAccionBoton(
                    Icons.check_circle,
                    'Activar',
                    () => _nuevoPedido(mesa),
                    AppColors.success,
                  ),
                if (mesa.estado == EstadoMesa.necesitaAtencion)
                  _buildAccionBoton(
                    Icons.check,
                    'Atender',
                    () => _liberarMesa(mesa),
                    AppColors.primary,
                  ),
                _buildAccionBoton(
                  Icons.edit,
                  'Editar',
                  () => showDialog(
                    context: context,
                    builder: (context) => _EditMesaDialog(mesa: mesa),
                  ),
                  AppColors.warning,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccionBoton(
    IconData icon,
    String texto,
    VoidCallback onTap,
    Color color,
  ) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.zero,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                texto,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTiempoCard(Mesa mesa) {
    if (mesa.tiempoTranscurrido == null) return const SizedBox();

    final tiempo = mesa.tiempoTranscurrido!;
    final color = _getTiempoColor(tiempo);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.zero,
              ),
              child: Icon(Icons.timer, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tiempo en mesa',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    _formatearTiempo(tiempo),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.zero,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time, size: 12, color: color),
                  const SizedBox(width: 4),
                  Text(
                    _getTiempoLabel(tiempo),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
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

  Widget _buildInfoCard(Mesa mesa) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.tag, 'Número', 'Mesa ${mesa.numero}'),
            const SizedBox(height: 10),
            _buildInfoRow(
              Icons.people,
              'Capacidad',
              '${mesa.capacidad} personas',
            ),
            const SizedBox(height: 10),
            _buildInfoRow(
              Icons.access_time,
              'Última apertura',
              mesa.horaApertura != null
                  ? DateFormat('dd/MM/yyyy HH:mm').format(mesa.horaApertura!)
                  : 'Nunca',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String valor) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const Spacer(),
        Text(
          valor,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildHistorialTab(Mesa mesa) {
    final historialPedidos = ref
        .watch(pedidosProvider.notifier)
        .getPorMesa(mesa.id)
        .where((p) => p.estado == EstadoPedido.cerrado)
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'Todos', label: Text('Todos')),
                    ButtonSegment(value: 'Efectivo', label: Text('Efectivo')),
                    ButtonSegment(value: 'Tarjeta', label: Text('Tarjeta')),
                  ],
                  selected: {_filtroMetodo},
                  onSelectionChanged: (value) {
                    setState(() => _filtroMetodo = value.first);
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                icon: Icon(
                  _fechaFiltro != null
                      ? Icons.filter_alt
                      : Icons.filter_alt_outlined,
                ),
                onPressed: _seleccionarFecha,
              ),
            ],
          ),
        ),
        Expanded(
          child: historialPedidos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Sin pedidos en el historial',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: historialPedidos.length,
                  itemBuilder: (context, index) {
                    return _buildHistorialCard(historialPedidos[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHistorialCard(Pedido pedido) {
    final negocio = ref.read(negocioProvider);
    final esEfectivo = pedido.metodoPago == 'Efectivo';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _verDetalleTicket(pedido, negocio),
        borderRadius: BorderRadius.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (esEfectivo ? AppColors.success : AppColors.primary)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.zero,
                ),
                child: Icon(
                  esEfectivo ? Icons.money : Icons.credit_card,
                  color: esEfectivo ? AppColors.success : AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat(
                        'dd/MM/yyyy HH:mm',
                      ).format(pedido.horaApertura),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${pedido.items.length} productos - ${pedido.metodoPago ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${pedido.total.toStringAsFixed(2)} €',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(Mesa mesa) {
    if (mesa.estado == EstadoMesa.libre) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _nuevoPedido(mesa),
            icon: const Icon(Icons.add),
            label: const Text('Abrir Mesa'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              minimumSize: const Size(double.infinity, 56),
            ),
          ),
        ),
      );
    } else if (mesa.estado == EstadoMesa.ocupada) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _cobrarYLiberar(mesa),
            icon: const Icon(Icons.payment),
            label: const Text('Cobrar y Liberar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              minimumSize: const Size(double.infinity, 56),
            ),
          ),
        ),
      );
    }
    return const SizedBox();
  }

  Pedido? _getPedidoActual(Mesa mesa) {
    if (mesa.pedidoActualId == null) return null;
    final pedidos = ref.watch(pedidosProvider);
    return pedidos.where((p) => p.id == mesa.pedidoActualId).firstOrNull;
  }

  _EstadoData _getEstadoData(EstadoMesa estado) {
    switch (estado) {
      case EstadoMesa.libre:
        return _EstadoData(AppColors.mesaLibre, 'Libre', Icons.check_circle);
      case EstadoMesa.ocupada:
        return _EstadoData(AppColors.mesaOcupada, 'Ocupada', Icons.restaurant);
      case EstadoMesa.reservada:
        return _EstadoData(AppColors.mesaReservada, 'Reservada', Icons.event);
      case EstadoMesa.necesitaAtencion:
        return _EstadoData(
          AppColors.mesaAtencion,
          'Necesita Atención',
          Icons.notification_important,
        );
    }
  }

  Color _getTiempoColor(Duration duracion) {
    if (duracion.inMinutes < 30) return AppColors.success;
    if (duracion.inMinutes < 60) return AppColors.warning;
    return AppColors.error;
  }

  String _formatearTiempo(Duration duracion) {
    if (duracion.inMinutes < 60) return '${duracion.inMinutes} min';
    return '${duracion.inHours}h ${duracion.inMinutes % 60}m';
  }

  String _getTiempoLabel(Duration duracion) {
    if (duracion.inMinutes < 30) return 'Normal';
    if (duracion.inMinutes < 60) return 'Tardando';
    return 'Urgente';
  }

  void _nuevoPedido(Mesa mesa) async {
    final cajeroActual = ref.read(cajeroActualProvider);
    final pedidoId = await ref
        .read(pedidosProvider.notifier)
        .crear(
          mesa.id,
          cajeroId: cajeroActual?.id,
          cajeroNombre: cajeroActual?.nombre,
        );
    await ref.read(mesasProvider.notifier).ocupar(mesa.id, pedidoId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mesa abierta correctamente'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _reservarMesa(Mesa mesa) {
    ref.read(mesasProvider.notifier).marcarReservada(mesa.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mesa reservada'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _liberarMesa(Mesa mesa) {
    ref.read(mesasProvider.notifier).liberar(mesa.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mesa liberada'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _cancelarPedido(Mesa mesa) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar Pedido'),
        content: const Text('¿Cancelar el pedido actual y liberar la mesa?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (mesa.pedidoActualId != null) {
                final pedidos = ref.read(pedidosProvider);
                final pedido = pedidos
                    .where((p) => p.id == mesa.pedidoActualId)
                    .firstOrNull;
                if (pedido != null) {
                  await ref
                      .read(pedidosProvider.notifier)
                      .cerrar(pedido.id, 'Cancelado');
                }
              }
              await ref.read(mesasProvider.notifier).liberar(mesa.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Cancelar Pedido'),
          ),
        ],
      ),
    );
  }

  void _cobrarYLiberar(Mesa mesa) async {
    final pedidos = ref.read(pedidosProvider);
    final pedidoActual = mesa.pedidoActualId != null
        ? pedidos.where((p) => p.id == mesa.pedidoActualId).firstOrNull
        : null;

    if (pedidoActual != null) {
      _mostrarDialogoCobro(mesa, pedidoActual);
    } else {
      await ref.read(mesasProvider.notifier).liberar(mesa.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mesa liberada'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _mostrarDialogoCobro(Mesa mesa, Pedido pedido) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) => _CobroDialog(
        total: pedido.total,
        onPago: (metodoPago) => _procesarPago(mesa, pedido, metodoPago),
      ),
    );
  }

  void _procesarPago(Mesa mesa, Pedido pedido, String metodoPago) async {
    await ref.read(pedidosProvider.notifier).cerrar(pedido.id, metodoPago);
    await ref.read(mesasProvider.notifier).liberar(mesa.id);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Venta completada con $metodoPago'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaFiltro ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (fecha != null) {
      setState(() => _fechaFiltro = fecha);
    }
  }

  void _verDetalleTicket(Pedido pedido, DatosNegocio negocio) {
    final baseImponible = pedido.total / (1 + negocio.ivaPorcentaje / 100);
    final importeIva = pedido.total - baseImponible;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: const Icon(Icons.receipt, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ticket',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat(
                          'dd/MM/yyyy HH:mm',
                        ).format(pedido.horaApertura),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              ...pedido.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.zero,
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
                      const SizedBox(width: 12),
                      Expanded(child: Text(item.productoNombre)),
                      Text(
                        '${item.subtotal.toStringAsFixed(2)} €',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Base imponible:'),
                  Text('${baseImponible.toStringAsFixed(2)} €'),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('IVA (${negocio.ivaPorcentaje.toStringAsFixed(0)}%):'),
                  Text('${importeIva.toStringAsFixed(2)} €'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL:',
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
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      (pedido.metodoPago == 'Efectivo'
                              ? AppColors.success
                              : AppColors.primary)
                          .withOpacity(0.1),
                  borderRadius: BorderRadius.zero,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      pedido.metodoPago == 'Efectivo'
                          ? Icons.money
                          : Icons.credit_card,
                      size: 16,
                      color: pedido.metodoPago == 'Efectivo'
                          ? AppColors.success
                          : AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      pedido.metodoPago ?? 'N/A',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: pedido.metodoPago == 'Efectivo'
                            ? AppColors.success
                            : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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

class _CobroDialog extends StatefulWidget {
  final double total;
  final Function(String metodoPago) onPago;

  const _CobroDialog({required this.total, required this.onPago});

  @override
  State<_CobroDialog> createState() => _CobroDialogState();
}

class _CobroDialogState extends State<_CobroDialog> {
  String _metodoPago = 'Efectivo';

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
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.zero,
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
          const SizedBox(height: 32),
          const Text(
            'Selecciona método de pago:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetodoButton(
                  Icons.money,
                  'Efectivo',
                  'Efectivo',
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetodoButton(
                  Icons.credit_card,
                  'Tarjeta',
                  'Tarjeta',
                  AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onPago(_metodoPago);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    minimumSize: const Size(0, 56),
                  ),
                  child: Text('Cobrar $_metodoPago'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetodoButton(
    IconData icon,
    String texto,
    String valor,
    Color color,
  ) {
    final selected = _metodoPago == valor;
    return Material(
      color: selected ? color : color.withOpacity(0.1),
      borderRadius: BorderRadius.zero,
      child: InkWell(
        onTap: () => setState(() => _metodoPago = valor),
        borderRadius: BorderRadius.zero,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(icon, size: 40, color: selected ? Colors.white : color),
              const SizedBox(height: 12),
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
      ),
    );
  }
}

class _EditMesaDialog extends ConsumerStatefulWidget {
  final Mesa mesa;

  const _EditMesaDialog({required this.mesa});

  @override
  ConsumerState<_EditMesaDialog> createState() => _EditMesaDialogState();
}

class _EditMesaDialogState extends ConsumerState<_EditMesaDialog> {
  late TextEditingController _numeroController;
  late TextEditingController _capacidadController;

  @override
  void initState() {
    super.initState();
    _numeroController = TextEditingController(
      text: widget.mesa.numero.toString(),
    );
    _capacidadController = TextEditingController(
      text: widget.mesa.capacidad.toString(),
    );
  }

  @override
  void dispose() {
    _numeroController.dispose();
    _capacidadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Editar Mesa ${widget.mesa.numero}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _numeroController,
            decoration: const InputDecoration(
              labelText: 'Número de mesa',
              prefixIcon: Icon(Icons.tag),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _capacidadController,
            decoration: const InputDecoration(
              labelText: 'Capacidad',
              prefixIcon: Icon(Icons.people),
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final numero = int.tryParse(_numeroController.text);
            final capacidad = int.tryParse(_capacidadController.text);
            if (numero != null && capacidad != null) {
              final actualizada = widget.mesa.copyWith(
                numero: numero,
                capacidad: capacidad,
              );
              ref.read(mesasProvider.notifier).actualizar(actualizada);
              Navigator.pop(context);
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
