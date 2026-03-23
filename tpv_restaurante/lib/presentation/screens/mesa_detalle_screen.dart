import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../providers/providers.dart';
import '../widgets/ticket_widget.dart';

class MesaDetalleScreen extends ConsumerStatefulWidget {
  final Mesa mesa;

  const MesaDetalleScreen({super.key, required this.mesa});

  @override
  ConsumerState<MesaDetalleScreen> createState() => _MesaDetalleScreenState();
}

class _MesaDetalleScreenState extends ConsumerState<MesaDetalleScreen> {
  String _filtroMetodo = 'Todos';
  DateTime? _fechaFiltro;
  bool _showPedido = false;

  @override
  Widget build(BuildContext context) {
    final mesaActual = ref
        .watch(mesasProvider)
        .firstWhere((m) => m.id == widget.mesa.id, orElse: () => widget.mesa);

    return Scaffold(
      appBar: AppBar(
        title: Text('Mesa ${widget.mesa.numero}'),
        actions: [
          if (mesaActual.estado == EstadoMesa.ocupada)
            IconButton(
              icon: const Icon(Icons.receipt),
              tooltip: 'Ver pedido actual',
              onPressed: () => setState(() => _showPedido = !_showPedido),
            ),
        ],
      ),
      body: mesaActual.estado == EstadoMesa.ocupada && _showPedido
          ? _buildPedidoActual(mesaActual)
          : _buildInfoMesa(mesaActual),
      floatingActionButton: _buildFab(mesaActual),
    );
  }

  Widget _buildInfoMesa(Mesa mesa) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEstadoCard(mesa),
          const SizedBox(height: 20),
          _buildDetallesCard(mesa),
          const SizedBox(height: 20),
          _buildAccionesCard(mesa),
          const SizedBox(height: 20),
          _buildHistorialHeader(),
          _buildHistorialList(mesa),
        ],
      ),
    );
  }

  Widget _buildEstadoCard(Mesa mesa) {
    Color estadoColor;
    String estadoTexto;
    IconData estadoIcono;

    switch (mesa.estado) {
      case EstadoMesa.libre:
        estadoColor = AppColors.mesaLibre;
        estadoTexto = 'Libre';
        estadoIcono = Icons.check_circle;
        break;
      case EstadoMesa.ocupada:
        estadoColor = AppColors.mesaOcupada;
        estadoTexto = 'Ocupada';
        estadoIcono = Icons.circle;
        break;
      case EstadoMesa.reservada:
        estadoColor = AppColors.mesaReservada;
        estadoTexto = 'Reservada';
        estadoIcono = Icons.event;
        break;
      case EstadoMesa.necesitaAtencion:
        estadoColor = AppColors.mesaAtencion;
        estadoTexto = 'Necesita Atención';
        estadoIcono = Icons.warning;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: estadoColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: estadoColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: estadoColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(estadoIcono, color: estadoColor, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  estadoTexto,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: estadoColor,
                  ),
                ),
                if (mesa.horaApertura != null)
                  Text(
                    'Desde: ${DateFormat('HH:mm').format(mesa.horaApertura!)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
              ],
            ),
          ),
          if (mesa.estado == EstadoMesa.ocupada)
            IconButton(
              icon: const Icon(Icons.receipt_long, color: AppColors.primary),
              onPressed: () => setState(() => _showPedido = true),
              tooltip: 'Ver pedido',
            ),
        ],
      ),
    );
  }

  Widget _buildDetallesCard(Mesa mesa) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detalles de la Mesa',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDetalleItem(Icons.tag, 'Número', '${mesa.numero}'),
              ),
              Expanded(
                child: _buildDetalleItem(
                  Icons.people,
                  'Capacidad',
                  '${mesa.capacidad} personas',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleItem(IconData icono, String label, String valor) {
    return Row(
      children: [
        Icon(icono, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(valor, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _buildAccionesCard(Mesa mesa) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Acciones Rápidas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildAccionBoton(
                Icons.restaurant,
                'Nuevo Pedido',
                () => _nuevoPedido(mesa),
                AppColors.secondary,
              ),
              _buildAccionBoton(
                Icons.event_available,
                'Reservar',
                () => _reservarMesa(mesa),
                AppColors.primary,
              ),
              _buildAccionBoton(
                Icons.warning,
                'Llamar',
                () => _llamarMozo(mesa),
                AppColors.warning,
              ),
              if (mesa.estado == EstadoMesa.libre)
                _buildAccionBoton(
                  Icons.delete,
                  'Eliminar Mesa',
                  () => _eliminarMesa(mesa),
                  AppColors.error,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccionBoton(
    IconData icono,
    String texto,
    VoidCallback onPressed,
    Color color,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icono, size: 18),
      label: Text(texto),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildHistorialHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Historial de Pedidos',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            DropdownButton<String>(
              value: _filtroMetodo,
              items: const [
                DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                DropdownMenuItem(value: 'Efectivo', child: Text('Efectivo')),
                DropdownMenuItem(value: 'Tarjeta', child: Text('Tarjeta')),
              ],
              onChanged: (value) {
                setState(() => _filtroMetodo = value ?? 'Todos');
              },
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                _fechaFiltro != null
                    ? Icons.filter_alt
                    : Icons.filter_alt_outlined,
                color: _fechaFiltro != null ? AppColors.primary : Colors.grey,
              ),
              onPressed: _seleccionarFecha,
              tooltip: 'Filtrar por fecha',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHistorialList(Mesa mesa) {
    final pedidosNotifier = ref.watch(pedidosProvider.notifier);
    var historialPedidos = pedidosNotifier
        .getPorMesa(mesa.id)
        .where((p) => p.estado == EstadoPedido.cerrado)
        .toList();

    if (_filtroMetodo != 'Todos') {
      historialPedidos = historialPedidos
          .where((p) => p.metodoPago == _filtroMetodo)
          .toList();
    }

    if (_fechaFiltro != null) {
      historialPedidos = historialPedidos.where((p) {
        return p.horaApertura.year == _fechaFiltro!.year &&
            p.horaApertura.month == _fechaFiltro!.month &&
            p.horaApertura.day == _fechaFiltro!.day;
      }).toList();
    }

    if (historialPedidos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Sin pedidos en el historial',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: historialPedidos.length,
      itemBuilder: (context, index) {
        return _buildTicketCard(historialPedidos[index]);
      },
    );
  }

  Widget _buildTicketCard(Pedido pedido) {
    final negocio = ref.read(negocioProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _verDetalleTicket(pedido, negocio),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat(
                        'dd/MM/yyyy HH:mm',
                      ).format(pedido.horaApertura),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${pedido.items.length} productos - ${pedido.metodoPago ?? 'N/A'}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Text(
                '${pedido.total.toStringAsFixed(2)} €',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.print, size: 20),
                onPressed: () => _imprimirTicket(pedido, negocio),
                tooltip: 'Imprimir ticket',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPedidoActual(Mesa mesa) {
    final pedidos = ref.watch(pedidosProvider);
    final pedidoActual = mesa.pedidoActualId != null
        ? pedidos.where((p) => p.id == mesa.pedidoActualId).firstOrNull
        : null;

    if (pedidoActual == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('No hay pedido activo'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _nuevoPedido(mesa),
              icon: const Icon(Icons.add),
              label: const Text('Crear Pedido'),
            ),
          ],
        ),
      );
    }

    return _buildPedidoContent(mesa, pedidoActual);
  }

  Widget _buildPedidoContent(Mesa mesa, Pedido pedido) {
    final negocio = ref.read(negocioProvider);
    final baseImponible = pedido.total / (1 + negocio.ivaPorcentaje / 100);
    final importeIva = pedido.total - baseImponible;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.mesaOcupada.withValues(alpha: 0.1),
          child: Row(
            children: [
              const Icon(Icons.receipt, color: AppColors.mesaOcupada),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pedido en Curso',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${pedido.items.length} productos - Total: ${pedido.total.toStringAsFixed(2)} €',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _showPedido = false),
                tooltip: 'Cerrar',
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pedido.items.length,
            itemBuilder: (context, index) {
              final item = pedido.items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${item.cantidad}x',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(item.productoNombre),
                  subtitle: Text('${item.precioUnitario.toStringAsFixed(2)} €'),
                  trailing: Text(
                    '${item.subtotal.toStringAsFixed(2)} €',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _imprimirTicket(pedido, negocio),
                      icon: const Icon(Icons.print),
                      label: const Text('Imprimir'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _cobrarPedido(mesa, pedido, negocio),
                      icon: const Icon(Icons.payment),
                      label: const Text('Cobrar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget? _buildFab(Mesa mesa) {
    if (mesa.estado == EstadoMesa.libre) {
      return FloatingActionButton.extended(
        onPressed: () => _nuevoPedido(mesa),
        icon: const Icon(Icons.add),
        label: const Text('Abrir Mesa'),
        backgroundColor: AppColors.secondary,
      );
    } else if (mesa.estado == EstadoMesa.ocupada) {
      return FloatingActionButton.extended(
        onPressed: () => _cobrarYLiberar(mesa),
        icon: const Icon(Icons.payment),
        label: const Text('Cobrar y Liberar'),
        backgroundColor: AppColors.success,
      );
    }
    return null;
  }

  void _nuevoPedido(Mesa mesa) async {
    final pedidoId = await ref.read(pedidosProvider.notifier).crear(mesa.id);

    await ref.read(mesasProvider.notifier).ocupar(mesa.id, pedidoId);

    if (mounted) {
      setState(() => _showPedido = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pedido creado para la mesa'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _reservarMesa(Mesa mesa) {
    ref.read(mesasProvider.notifier).marcarReservada(mesa.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mesa marcada como reservada'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _llamarMozo(Mesa mesa) {
    ref.read(mesasProvider.notifier).marcarAtencion(mesa.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mozo notificado'),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  void _eliminarMesa(Mesa mesa) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppColors.error),
            SizedBox(width: 12),
            Text('Eliminar Mesa'),
          ],
        ),
        content: Text(
          '¿Eliminar la Mesa ${mesa.numero}?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(mesasProvider.notifier).eliminar(mesa.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _cobrarPedido(Mesa mesa, Pedido pedido, DatosNegocio negocio) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CobroMesaDialog(
        total: pedido.total,
        onPago: (metodoPago, importeRecibido, cambio) {
          _procesarPago(mesa, pedido, metodoPago);
        },
      ),
    );
  }

  void _procesarPago(Mesa mesa, Pedido pedido, String metodoPago) async {
    await ref.read(pedidosProvider.notifier).cerrar(pedido.id, metodoPago);
    await ref.read(mesasProvider.notifier).liberar(mesa.id);

    final negocio = ref.read(negocioProvider);

    TicketPrintHelper.showPrintDialog(
      context,
      items: pedido.items,
      total: pedido.total,
      porcentajePropina: pedido.porcentajePropina,
      ivaPorcentaje: negocio.ivaPorcentaje,
      metodoPago: metodoPago,
      negocio: negocio,
      mesaNumero: mesa.numero.toString(),
      onCerrar: () {
        if (mounted) {
          setState(() => _showPedido = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Venta completada con $metodoPago'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
    );
  }

  void _cobrarYLiberar(Mesa mesa) async {
    final pedidos = ref.read(pedidosProvider);
    final pedidoActual = mesa.pedidoActualId != null
        ? pedidos.where((p) => p.id == mesa.pedidoActualId).firstOrNull
        : null;

    if (pedidoActual != null) {
      _cobrarPedido(mesa, pedidoActual, ref.read(negocioProvider));
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
    final numeroTicket =
        'T-${pedido.horaApertura.year}${pedido.horaApertura.month.toString().padLeft(2, '0')}${pedido.horaApertura.day.toString().padLeft(2, '0')}-${pedido.id.substring(pedido.id.length > 10 ? pedido.id.length - 6 : 0)}';

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
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
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
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      negocio.nombre,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (negocio.razonSocial != null)
                      Text(
                        negocio.razonSocial!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      negocio.direccion,
                      style: const TextStyle(fontSize: 11),
                    ),
                    Text(negocio.ciudad, style: const TextStyle(fontSize: 11)),
                    Text(
                      'CIF/NIF: ${negocio.cifNif ?? "N/A"}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nº Ticket: $numeroTicket',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${pedido.horaApertura.day.toString().padLeft(2, '0')}/${pedido.horaApertura.month.toString().padLeft(2, '0')}/${pedido.horaApertura.year} ${pedido.horaApertura.hour.toString().padLeft(2, '0')}:${pedido.horaApertura.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              ...pedido.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(width: 30, child: Text('${item.cantidad}')),
                      Expanded(child: Text(item.productoNombre)),
                      SizedBox(
                        width: 60,
                        child: Text(
                          '${item.precioUnitario.toStringAsFixed(2)} €',
                          textAlign: TextAlign.right,
                        ),
                      ),
                      SizedBox(
                        width: 70,
                        child: Text(
                          '${item.subtotal.toStringAsFixed(2)} €',
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(),
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
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Column(
                  children: [
                    Text(
                      'FACTURA SIMPLIFICADA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Sin efectos fiscales según Real Decreto 1496/2003',
                      style: TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _imprimirTicket(pedido, negocio);
                  },
                  icon: const Icon(Icons.print),
                  label: const Text('Imprimir Ticket'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _imprimirTicket(Pedido pedido, DatosNegocio negocio) {
    TicketPrintHelper.printTicket(
      items: pedido.items,
      total: pedido.total,
      porcentajePropina: pedido.porcentajePropina,
      ivaPorcentaje: negocio.ivaPorcentaje,
      metodoPago: pedido.metodoPago ?? 'Efectivo',
      negocio: negocio,
      mesaNumero: widget.mesa.numero.toString(),
    );
  }
}

class _CobroMesaDialog extends StatefulWidget {
  final double total;
  final Function(String metodoPago, double? importeRecibido, double cambio)
  onPago;

  const _CobroMesaDialog({required this.total, required this.onPago});

  @override
  State<_CobroMesaDialog> createState() => _CobroMesaDialogState();
}

class _CobroMesaDialogState extends State<_CobroMesaDialog> {
  String _metodoPago = 'Efectivo';
  final _efectivoController = TextEditingController();
  double _cambio = 0;

  @override
  void dispose() {
    _efectivoController.dispose();
    super.dispose();
  }

  void _calcularCambio() {
    if (_efectivoController.text.isEmpty) {
      setState(() => _cambio = 0);
      return;
    }
    final importe = double.tryParse(_efectivoController.text) ?? 0;
    setState(() => _cambio = importe - widget.total);
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Total a Cobrar',
              style: TextStyle(color: AppColors.primary, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.total.toStringAsFixed(2)} €',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
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
                  child: _buildMetodoPagoButton(
                    Icons.money,
                    'Efectivo',
                    'Efectivo',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetodoPagoButton(
                    Icons.credit_card,
                    'Tarjeta',
                    'Tarjeta',
                  ),
                ),
              ],
            ),
            if (_metodoPago == 'Efectivo') ...[
              const SizedBox(height: 20),
              TextField(
                controller: _efectivoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Importe recibido',
                  prefixText: '€ ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payments),
                ),
                onChanged: (_) => _calcularCambio(),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _cambio >= 0
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _cambio >= 0 ? AppColors.success : AppColors.error,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _cambio >= 0 ? 'Cambio a devolver:' : 'Falta por pagar:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _cambio >= 0
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                    Text(
                      '${_cambio.abs().toStringAsFixed(2)} €',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _cambio >= 0
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
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
                  child: ElevatedButton(
                    onPressed: _puedeCobrar()
                        ? () {
                            final efectivo = _metodoPago == 'Efectivo'
                                ? double.tryParse(_efectivoController.text) ?? 0
                                : null;
                            Navigator.pop(context);
                            widget.onPago(_metodoPago, efectivo, _cambio);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cobrar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetodoPagoButton(IconData icono, String texto, String valor) {
    final selected = _metodoPago == valor;
    return GestureDetector(
      onTap: () => setState(() => _metodoPago = valor),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icono,
              size: 32,
              color: selected ? Colors.white : AppColors.primary,
            ),
            const SizedBox(height: 8),
            Text(
              texto,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _puedeCobrar() {
    if (_metodoPago == 'Tarjeta') return true;
    if (_efectivoController.text.isEmpty) return false;
    final importe = double.tryParse(_efectivoController.text) ?? 0;
    return importe >= widget.total;
  }
}
