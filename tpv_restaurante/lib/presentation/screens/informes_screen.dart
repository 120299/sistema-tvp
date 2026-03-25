import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../providers/providers.dart';

class InformesScreen extends ConsumerStatefulWidget {
  const InformesScreen({super.key});

  @override
  ConsumerState<InformesScreen> createState() => _InformesScreenState();
}

class _InformesScreenState extends ConsumerState<InformesScreen> {
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String _filtroMetodo = 'Todos';
  String? _filtroCajero;
  String _periodoSeleccionado = 'semana';

  @override
  void initState() {
    super.initState();
    _fechaFin = DateTime.now();
    _fechaInicio = DateTime.now().subtract(const Duration(days: 7));
  }

  void _cambiarPeriodo(String periodo) {
    setState(() {
      _periodoSeleccionado = periodo;
      _fechaFin = DateTime.now();
      switch (periodo) {
        case 'hoy':
          _fechaInicio = DateTime.now();
          break;
        case 'semana':
          _fechaInicio = DateTime.now().subtract(const Duration(days: 7));
          break;
        case 'mes':
          _fechaInicio = DateTime.now().subtract(const Duration(days: 30));
          break;
        case 'trimestre':
          _fechaInicio = DateTime.now().subtract(const Duration(days: 90));
          break;
        case 'ano':
          _fechaInicio = DateTime.now().subtract(const Duration(days: 365));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final negocio = ref.watch(negocioProvider);
    final pedidosNotifier = ref.watch(pedidosProvider.notifier);
    final cajeros = ref.watch(cajerosProvider);
    final cajeroActual = ref.watch(cajeroActualProvider);
    final isAdmin = cajeroActual?.isAdministrador ?? false;

    final pedidosFiltrados = pedidosNotifier.getFiltrados(
      fechaInicio: _fechaInicio,
      fechaFin: _fechaFin,
      metodoPago: _filtroMetodo != 'Todos' ? _filtroMetodo : null,
      cajeroId: isAdmin ? _filtroCajero : null,
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
    final datosGrafico = _getDatosGrafico(pedidosFiltrados);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;

            return Column(
              children: [
                _buildFiltros(context, cajeros, isAdmin),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: isWide
                        ? _buildLayoutWide(
                            totalVentas,
                            pedidosFiltrados.length,
                            ticketPromedio,
                            productosMasVendidos,
                            ventasPorMetodo,
                            datosGrafico,
                            pedidosFiltrados,
                          )
                        : _buildLayoutNarrow(
                            totalVentas,
                            pedidosFiltrados.length,
                            ticketPromedio,
                            productosMasVendidos,
                            ventasPorMetodo,
                            datosGrafico,
                            pedidosFiltrados,
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLayoutWide(
    double totalVentas,
    int numPedidos,
    double ticketPromedio,
    List<MapEntry<String, int>> productosMasVendidos,
    Map<String, double> ventasPorMetodo,
    List<MapEntry<DateTime, double>> datosGrafico,
    List<Pedido> pedidosFiltrados,
  ) {
    return Column(
      children: [
        _buildResumenCards(totalVentas, numPedidos, ticketPromedio),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _buildGraficoTendencia(datosGrafico),
                  const SizedBox(height: 20),
                  _buildAccionesExport(pedidosFiltrados, totalVentas),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                children: [
                  _buildGraficoMetodosPago(ventasPorMetodo),
                  const SizedBox(height: 20),
                  _buildProductosMasVendidos(productosMasVendidos),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLayoutNarrow(
    double totalVentas,
    int numPedidos,
    double ticketPromedio,
    List<MapEntry<String, int>> productosMasVendidos,
    Map<String, double> ventasPorMetodo,
    List<MapEntry<DateTime, double>> datosGrafico,
    List<Pedido> pedidosFiltrados,
  ) {
    return Column(
      children: [
        _buildResumenCards(totalVentas, numPedidos, ticketPromedio),
        const SizedBox(height: 20),
        _buildGraficoTendencia(datosGrafico),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildGraficoMetodosPago(ventasPorMetodo)),
            const SizedBox(width: 16),
            Expanded(child: _buildProductosMasVendidos(productosMasVendidos)),
          ],
        ),
        const SizedBox(height: 20),
        _buildAccionesExport(pedidosFiltrados, totalVentas),
      ],
    );
  }

  Widget _buildFiltros(
    BuildContext context,
    List<Cajero> cajeros,
    bool isAdmin,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPeriodoChip('Hoy', 'hoy'),
                const SizedBox(width: 8),
                _buildPeriodoChip('Semana', 'semana'),
                const SizedBox(width: 8),
                _buildPeriodoChip('Mes', 'mes'),
                const SizedBox(width: 8),
                _buildPeriodoChip('Trimestre', 'trimestre'),
                const SizedBox(width: 8),
                _buildPeriodoChip('Año', 'ano'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _seleccionarFecha(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _fechaInicio != null
                              ? DateFormat('dd/MM/yyyy').format(_fechaInicio!)
                              : 'Desde',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('→'),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => _seleccionarFecha(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _fechaFin != null
                              ? DateFormat('dd/MM/yyyy').format(_fechaFin!)
                              : 'Hasta',
                        ),
                      ],
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
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filtroMetodo,
                      isExpanded: true,
                      items: ['Todos', 'Efectivo', 'Tarjeta'].map((m) {
                        return DropdownMenuItem(value: m, child: Text(m));
                      }).toList(),
                      onChanged: (v) {
                        setState(() => _filtroMetodo = v!);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (isAdmin) ...[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _filtroCajero,
                        hint: const Text('Todos'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Todos'),
                          ),
                          ...cajeros.map((c) {
                            return DropdownMenuItem(
                              value: c.id,
                              child: Text(c.nombre),
                            );
                          }),
                        ],
                        onChanged: (v) {
                          setState(() => _filtroCajero = v);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodoChip(String label, String value) {
    final isSelected = _periodoSeleccionado == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _cambiarPeriodo(value),
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildResumenCards(
    double totalVentas,
    int numPedidos,
    double ticketPromedio,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Ventas',
            '€${totalVentas.toStringAsFixed(2)}',
            Icons.euro,
            AppColors.success,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Pedidos',
            '$numPedidos',
            Icons.receipt_long,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Ticket Promedio',
            '€${ticketPromedio.toStringAsFixed(2)}',
            Icons.trending_up,
            AppColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildGraficoTendencia(List<MapEntry<DateTime, double>> datos) {
    if (datos.isEmpty) {
      return Container(
        height: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                'Sin datos para el período seleccionado',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < datos.length; i++) {
      spots.add(FlSpot(i.toDouble(), datos[i].value));
    }

    final maxY =
        datos.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2;

    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Tendencia de Ventas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 12, height: 3, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      '€',
                      style: TextStyle(fontSize: 10, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? maxY / 4 : 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: datos.length > 7
                          ? (datos.length / 7).ceilToDouble()
                          : 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < datos.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('dd').format(datos[index].key),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '€${value.toInt()}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (datos.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '€${spot.y.toStringAsFixed(2)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraficoMetodosPago(Map<String, double> ventasPorMetodo) {
    if (ventasPorMetodo.isEmpty ||
        ventasPorMetodo.values.every((v) => v == 0)) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          children: [
            const Text(
              'Método de Pago',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            Icon(
              Icons.pie_chart_outline,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin datos de métodos de pago',
              style: TextStyle(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 40),
          ],
        ),
      );
    }

    final total = ventasPorMetodo.values.fold<double>(0, (a, b) => a + b);
    final secciones = <PieChartSectionData>[];
    final colores = {'Efectivo': Colors.green, 'Tarjeta': Colors.blue};

    ventasPorMetodo.forEach((metodo, cantidad) {
      if (cantidad > 0) {
        final porcentaje = (cantidad / total * 100);
        secciones.add(
          PieChartSectionData(
            color: colores[metodo] ?? Colors.grey,
            value: cantidad,
            title: '${porcentaje.toStringAsFixed(0)}%',
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Método de Pago',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sections: secciones,
                centerSpaceRadius: 40,
                sectionsSpace: 4,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...ventasPorMetodo.entries.where((e) => e.value > 0).map((e) {
            final porcentaje = (e.value / total * 100);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: colores[e.key] ?? Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.key,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: porcentaje / 100,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(
                            colores[e.key] ?? Colors.grey,
                          ),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '€${e.value.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${porcentaje.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProductosMasVendidos(List<MapEntry<String, int>> productos) {
    if (productos.isEmpty) {
      return Container(
        height: 200,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Center(
          child: Text(
            'Sin productos vendidos',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ),
      );
    }

    final maxCantidad = productos.first.value.toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Productos Más Vendidos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...productos.take(5).map((producto) {
            final porcentaje = producto.value / maxCantidad;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          producto.key,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${producto.value}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: porcentaje,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAccionesExport(List<Pedido> pedidos, double total) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _exportarCSV(pedidos, total),
            icon: const Icon(Icons.table_chart),
            label: const Text('Exportar CSV'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _exportarPDF(pedidos, total),
            icon: const Icon(Icons.print),
            label: const Text('Imprimir'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _seleccionarFecha(bool esInicio) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: esInicio
          ? _fechaInicio ?? DateTime.now()
          : _fechaFin ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (fecha != null) {
      setState(() {
        if (esInicio) {
          _fechaInicio = fecha;
        } else {
          _fechaFin = fecha;
        }
        _periodoSeleccionado = '';
      });
    }
  }

  List<MapEntry<String, int>> _getProductosMasVendidos(
    List<Pedido> pedidos,
    List<Producto> productos,
  ) {
    final ventas = <String, int>{};
    for (final pedido in pedidos) {
      for (final item in pedido.items) {
        ventas[item.productoNombre] =
            (ventas[item.productoNombre] ?? 0) + item.cantidad;
      }
    }
    final lista = ventas.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return lista;
  }

  Map<String, double> _getVentasPorMetodo(List<Pedido> pedidos) {
    final ventas = <String, double>{'Efectivo': 0, 'Tarjeta': 0};
    for (final pedido in pedidos) {
      final metodo = pedido.metodoPago ?? 'Efectivo';
      ventas[metodo] = (ventas[metodo] ?? 0) + pedido.total;
    }
    return ventas;
  }

  List<MapEntry<DateTime, double>> _getDatosGrafico(List<Pedido> pedidos) {
    final ventasPorDia = <DateTime, double>{};
    for (final pedido in pedidos) {
      final dia = DateTime(
        pedido.horaApertura.year,
        pedido.horaApertura.month,
        pedido.horaApertura.day,
      );
      ventasPorDia[dia] = (ventasPorDia[dia] ?? 0) + pedido.total;
    }
    final lista = ventasPorDia.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return lista;
  }

  void _exportarCSV(List<Pedido> pedidos, double total) async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('Fecha,Hora,Productos,Total,Método,Cajero');
      for (final p in pedidos) {
        final productos = p.items
            .map((i) => '${i.cantidad}x ${i.productoNombre}')
            .join('; ');
        buffer.writeln(
          '${DateFormat('dd/MM/yyyy').format(p.horaApertura)},'
          '${DateFormat('HH:mm').format(p.horaApertura)},'
          '"$productos",'
          '${p.total.toStringAsFixed(2)},'
          '${p.metodoPago ?? "N/A"},'
          '${p.cajeroNombre ?? "N/A"}',
        );
      }
      buffer.writeln('');
      buffer.writeln('Total,,,${total.toStringAsFixed(2)}');

      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/informe_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv',
      );
      await file.writeAsString(buffer.toString());

      await Share.shareXFiles([XFile(file.path)], text: 'Informe de ventas');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al exportar: $e')));
      }
    }
  }

  void _exportarPDF(List<Pedido> pedidos, double total) async {
    try {
      final negocio = ref.read(negocioProvider);
      final buffer = StringBuffer();
      buffer.writeln('=================================');
      buffer.writeln('  ${negocio.nombre}');
      buffer.writeln('=================================');
      buffer.writeln('');
      buffer.writeln('INFORME DE VENTAS');
      buffer.writeln(
        'Fecha: ${DateFormat('dd/MM/yyyy').format(_fechaInicio!)} - ${DateFormat('dd/MM/yyyy').format(_fechaFin!)}',
      );
      buffer.writeln('=================================');
      buffer.writeln('');
      buffer.writeln('TOTAL VENTAS: €${total.toStringAsFixed(2)}');
      buffer.writeln('NUM PEDIDOS: ${pedidos.length}');
      buffer.writeln('=================================');
      buffer.writeln('');

      for (final p in pedidos) {
        buffer.writeln(
          '${DateFormat('dd/MM HH:mm').format(p.horaApertura)} - €${p.total.toStringAsFixed(2)} (${p.metodoPago})',
        );
      }

      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/informe_${DateFormat('yyyyMMdd').format(DateTime.now())}.txt',
      );
      await file.writeAsString(buffer.toString());

      await Share.shareXFiles([XFile(file.path)], text: 'Informe de ventas');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al generar informe: $e')));
      }
    }
  }
}
