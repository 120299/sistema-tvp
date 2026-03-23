import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../providers/providers.dart';
import '../widgets/ticket_widget.dart';

class InformesScreen extends ConsumerStatefulWidget {
  const InformesScreen({super.key});

  @override
  ConsumerState<InformesScreen> createState() => _InformesScreenState();
}

class _InformesScreenState extends ConsumerState<InformesScreen> {
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String _filtroMetodo = 'Todos';
  String? _filtroMesa;

  @override
  void initState() {
    super.initState();
    _fechaFin = DateTime.now();
    _fechaInicio = DateTime.now().subtract(const Duration(days: 7));
  }

  @override
  Widget build(BuildContext context) {
    final negocio = ref.watch(negocioProvider);
    final pedidosNotifier = ref.watch(pedidosProvider.notifier);

    final pedidosFiltrados = pedidosNotifier.getFiltrados(
      fechaInicio: _fechaInicio,
      fechaFin: _fechaFin?.add(const Duration(days: 1)),
      metodoPago: _filtroMetodo != 'Todos' ? _filtroMetodo : null,
      mesaId: _filtroMesa,
    );

    final totalVentas = pedidosFiltrados.fold<double>(
      0,
      (sum, p) => sum + p.total,
    );
    final ticketPromedio = pedidosFiltrados.isEmpty
        ? 0.0
        : totalVentas / pedidosFiltrados.length;

    final productos = ref.watch(productosProvider);
    final productosMasVendidos = _getProductosMasVendidos(
      pedidosFiltrados,
      productos,
    );
    final ventasPorMetodo = _getVentasPorMetodo(pedidosFiltrados);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildFiltros(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildTarjetaEstadistica(
                            'Total Ventas',
                            '${totalVentas.toStringAsFixed(2)} €',
                            Icons.euro,
                            AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTarjetaEstadistica(
                            'Pedidos',
                            '${pedidosFiltrados.length}',
                            Icons.receipt_long,
                            AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTarjetaEstadistica(
                            'Ticket Promedio',
                            '${ticketPromedio.toStringAsFixed(2)} €',
                            Icons.trending_up,
                            AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTarjetaEstadistica(
                            'Mesas Activas',
                            '${ref.watch(mesasProvider).where((m) => m.estado == EstadoMesa.ocupada).length}',
                            Icons.table_restaurant,
                            AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSeccion(
                      'Productos Más Vendidos',
                      productosMasVendidos.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  'Sin datos disponibles',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            )
                          : Column(
                              children: productosMasVendidos.take(10).map((
                                entry,
                              ) {
                                return _buildItemLista(
                                  entry.key,
                                  '${entry.value} uds',
                                );
                              }).toList(),
                            ),
                    ),
                    const SizedBox(height: 24),
                    _buildSeccion(
                      'Ventas por Método de Pago',
                      ventasPorMetodo.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  'Sin datos disponibles',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            )
                          : Column(
                              children: ventasPorMetodo.entries.map((entry) {
                                return _buildItemLista(
                                  entry.key,
                                  '${entry.value.toStringAsFixed(2)} €',
                                );
                              }).toList(),
                            ),
                    ),
                    const SizedBox(height: 24),
                    _buildSeccion(
                      'Detalle de Pedidos',
                      pedidosFiltrados.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  'No hay pedidos en este período',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            )
                          : Column(
                              children: pedidosFiltrados.take(20).map((pedido) {
                                final mesa = ref
                                    .read(mesasProvider.notifier)
                                    .getPorId(pedido.mesaId);
                                return _buildPedidoItem(pedido, mesa, negocio);
                              }).toList(),
                            ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltros(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informes y Estadísticas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _fechaInicio != null && _fechaFin != null
                ? 'Desde ${DateFormat('dd/MM/yyyy').format(_fechaInicio!)} hasta ${DateFormat('dd/MM/yyyy').format(_fechaFin!)}'
                : 'Selecciona un período',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _seleccionarFechaInicio(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Desde',
                      prefixIcon: Icon(Icons.calendar_today),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      _fechaInicio != null
                          ? DateFormat('dd/MM/yyyy').format(_fechaInicio!)
                          : 'Seleccionar',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _seleccionarFechaFin(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Hasta',
                      prefixIcon: Icon(Icons.calendar_today),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      _fechaFin != null
                          ? DateFormat('dd/MM/yyyy').format(_fechaFin!)
                          : 'Seleccionar',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filtroMetodo,
                  decoration: const InputDecoration(
                    labelText: 'Método de pago',
                    prefixIcon: Icon(Icons.payment),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                    DropdownMenuItem(
                      value: 'Efectivo',
                      child: Text('Efectivo'),
                    ),
                    DropdownMenuItem(value: 'Tarjeta', child: Text('Tarjeta')),
                  ],
                  onChanged: (value) {
                    setState(() => _filtroMetodo = value ?? 'Todos');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _filtroMesa,
                  decoration: const InputDecoration(
                    labelText: 'Mesa',
                    prefixIcon: Icon(Icons.table_restaurant),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todas')),
                    ...ref
                        .watch(mesasProvider)
                        .map(
                          (m) => DropdownMenuItem(
                            value: m.id,
                            child: Text('Mesa ${m.numero}'),
                          ),
                        ),
                  ],
                  onChanged: (value) {
                    setState(() => _filtroMesa = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _hoy,
                icon: const Icon(Icons.today, size: 18),
                label: const Text('Hoy'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _semana,
                icon: const Icon(Icons.date_range, size: 18),
                label: const Text('Esta semana'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _mes,
                icon: const Icon(Icons.calendar_month, size: 18),
                label: const Text('Este mes'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaEstadistica(
    String titulo,
    String valor,
    IconData icono,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icono, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            valor,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccion(String titulo, Widget contenido) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: contenido,
        ),
      ],
    );
  }

  Widget _buildItemLista(String titulo, String valor, {String? subtitulo}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitulo != null)
                  Text(
                    subtitulo,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            valor,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPedidoItem(Pedido pedido, Mesa? mesa, DatosNegocio negocio) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.receipt,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mesa ${mesa?.numero ?? '?'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  DateFormat('dd/MM HH:mm').format(pedido.horaApertura),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${pedido.total.toStringAsFixed(2)} €',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  pedido.metodoPago ?? 'N/A',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.print, size: 20),
            onPressed: () => _imprimirTicket(pedido, negocio),
            tooltip: 'Imprimir ticket',
          ),
        ],
      ),
    );
  }

  List<MapEntry<String, int>> _getProductosMasVendidos(
    List<Pedido> pedidos,
    List<Producto> productos,
  ) {
    final Map<String, int> conteo = {};
    for (final pedido in pedidos) {
      for (final item in pedido.items) {
        conteo[item.productoNombre] =
            (conteo[item.productoNombre] ?? 0) + item.cantidad;
      }
    }
    final entries = conteo.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  Map<String, double> _getVentasPorMetodo(List<Pedido> pedidos) {
    final Map<String, double> ventas = {};
    for (final pedido in pedidos) {
      final metodo = pedido.metodoPago ?? 'Otro';
      ventas[metodo] = (ventas[metodo] ?? 0) + pedido.total;
    }
    return ventas;
  }

  void _imprimirTicket(Pedido pedido, DatosNegocio negocio) {
    TicketPrintHelper.showPrintDialog(
      context,
      items: pedido.items,
      total: pedido.total,
      porcentajePropina: pedido.porcentajePropina,
      ivaPorcentaje: negocio.ivaPorcentaje,
      metodoPago: pedido.metodoPago ?? 'Efectivo',
      negocio: negocio,
      mesaNumero: ref
          .read(mesasProvider.notifier)
          .getPorId(pedido.mesaId)
          ?.numero
          .toString(),
      onImprimir: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Abriendo diálogo de impresión...'),
            backgroundColor: AppColors.primary,
          ),
        );
      },
      onCerrar: () {},
    );
  }

  Future<void> _seleccionarFechaInicio(BuildContext context) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (fecha != null) {
      setState(() => _fechaInicio = fecha);
    }
  }

  Future<void> _seleccionarFechaFin(BuildContext context) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaFin ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (fecha != null) {
      setState(() => _fechaFin = fecha);
    }
  }

  void _hoy() {
    setState(() {
      _fechaInicio = DateTime.now();
      _fechaFin = DateTime.now();
    });
  }

  void _semana() {
    final now = DateTime.now();
    setState(() {
      _fechaInicio = now.subtract(Duration(days: now.weekday - 1));
      _fechaFin = now;
    });
  }

  void _mes() {
    final now = DateTime.now();
    setState(() {
      _fechaInicio = DateTime(now.year, now.month, 1);
      _fechaFin = now;
    });
  }
}
