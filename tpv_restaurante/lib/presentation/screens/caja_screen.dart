import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/services/print_service.dart';
import '../providers/providers.dart';

class CajaScreen extends ConsumerStatefulWidget {
  const CajaScreen({super.key});

  @override
  ConsumerState<CajaScreen> createState() => _CajaScreenState();
}

class _CajaScreenState extends ConsumerState<CajaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _montoController = TextEditingController();
  String _importeKeypadCaja = '0';

  void _actualizarImporteCaja(String digito) {
    setState(() {
      if (digito == 'C') {
        _importeKeypadCaja = '0';
      } else if (digito == '⌫') {
        if (_importeKeypadCaja.length > 1) {
          _importeKeypadCaja = _importeKeypadCaja.substring(
            0,
            _importeKeypadCaja.length - 1,
          );
        } else {
          _importeKeypadCaja = '0';
        }
      } else if (digito == ',') {
        if (!_importeKeypadCaja.contains(',')) {
          _importeKeypadCaja += ',';
        }
      } else {
        if (_importeKeypadCaja == '0') {
          _importeKeypadCaja = digito;
        } else {
          final partes = _importeKeypadCaja.split(',');
          if (partes.length == 2 && partes[1].length >= 2) return;
          _importeKeypadCaja += digito;
        }
      }
    });
  }

  String _formatearImporte(String valor) {
    if (valor.isEmpty || valor == '0') return '0,00';
    if (!valor.contains(',')) return '$valor,00';
    final partes = valor.split(',');
    if (partes[1].isEmpty) return '$partes[0],00';
    if (partes[1].length == 1) return '$partes[0],${partes[1]}0';
    return '${partes[0]},${partes[1].substring(0, 2)}';
  }

  double _getImporteNumerico() {
    return double.tryParse(_importeKeypadCaja.replaceAll(',', '.')) ?? 0.0;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarFondoSugerido();
    });
  }

  void _cargarFondoSugerido() {
    final historial = ref.read(cajasHistorialProvider);
    if (historial.isNotEmpty) {
      final ultimaCaja = historial.first;
      final saldoSugerido = ultimaCaja.saldoCaja;
      setState(() {
        _montoController.text = saldoSugerido.toStringAsFixed(2);
      });
    } else {
      setState(() {
        _montoController.text = '0.00';
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final caja = ref.watch(cajaProvider);
    final cajeroActual = ref.watch(cajeroActualProvider);
    final esAdmin = cajeroActual?.isAdministrador ?? false;

    return Container(
      color: AppColors.lightBackground,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Caja Actual'),
                Tab(text: 'Historial'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCajaActual(caja, cajeroActual, esAdmin),
                _buildHistorial(esAdmin, cajeroActual),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCajaActual(Caja? caja, Cajero? cajeroActual, bool esAdmin) {
    if (caja == null || caja.estado == EstadoCaja.cerrada) {
      return _buildCajaCerrada(cajeroActual);
    }
    return _buildCajaAbierta(caja, esAdmin);
  }

  Widget _buildCajaCerrada(Cajero? cajeroActual) {
    final historial = ref.read(cajasHistorialProvider);
    double ultimoSaldo = 0.0;
    if (historial.isNotEmpty) {
      ultimoSaldo = historial.first.saldoCaja;
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.point_of_sale,
                size: 80,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'CAJA CERRADA',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              cajeroActual != null
                  ? 'Usuario: ${cajeroActual.nombre}'
                  : 'Ningún usuario logueado',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'FONDO INICIAL',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '€ ',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                        Text(
                          _formatearImporte(_importeKeypadCaja),
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final buttonSize = constraints.maxWidth > 350
                          ? 70.0
                          : 60.0;
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildTeclaKeypad(
                                '7',
                                buttonSize,
                                _actualizarImporteCaja,
                              ),
                              _buildTeclaKeypad(
                                '8',
                                buttonSize,
                                _actualizarImporteCaja,
                              ),
                              _buildTeclaKeypad(
                                '9',
                                buttonSize,
                                _actualizarImporteCaja,
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildTeclaKeypad(
                                '4',
                                buttonSize,
                                _actualizarImporteCaja,
                              ),
                              _buildTeclaKeypad(
                                '5',
                                buttonSize,
                                _actualizarImporteCaja,
                              ),
                              _buildTeclaKeypad(
                                '6',
                                buttonSize,
                                _actualizarImporteCaja,
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildTeclaKeypad(
                                '1',
                                buttonSize,
                                _actualizarImporteCaja,
                              ),
                              _buildTeclaKeypad(
                                '2',
                                buttonSize,
                                _actualizarImporteCaja,
                              ),
                              _buildTeclaKeypad(
                                '3',
                                buttonSize,
                                _actualizarImporteCaja,
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildTeclaKeypad(
                                'C',
                                buttonSize,
                                _actualizarImporteCaja,
                                esAccion: true,
                              ),
                              _buildTeclaKeypad(
                                '0',
                                buttonSize,
                                _actualizarImporteCaja,
                              ),
                              _buildTeclaKeypad(
                                '⌫',
                                buttonSize,
                                _actualizarImporteCaja,
                                esAccion: true,
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.history,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Última caja: €${ultimoSaldo.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: cajeroActual != null
                        ? () {
                            final monto = _getImporteNumerico();
                            _montoController.text = monto.toStringAsFixed(2);
                            _abrirCaja();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_open),
                        SizedBox(width: 12),
                        Text(
                          'ABRIR CAJA',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

  Widget _buildTeclaKeypad(
    String tecla,
    double size,
    Function(String) onTap, {
    bool esAccion = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: esAccion ? Colors.grey.shade300 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(size / 4),
        child: InkWell(
          onTap: () => onTap(tecla),
          borderRadius: BorderRadius.circular(size / 4),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            child: tecla == '⌫'
                ? Icon(
                    Icons.backspace_outlined,
                    color: Colors.grey.shade700,
                    size: 24,
                  )
                : Text(
                    tecla,
                    style: TextStyle(
                      fontSize: size > 65 ? 28 : 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildCajaAbierta(Caja caja, bool esAdmin) {
    final pedidos = ref.watch(pedidosProvider);
    final ventasHoy = pedidos.where((p) {
      return p.estado == EstadoPedido.cerrado &&
          p.horaApertura.year == DateTime.now().year &&
          p.horaApertura.month == DateTime.now().month &&
          p.horaApertura.day == DateTime.now().day;
    }).toList();

    final efectivo = ventasHoy
        .where((p) => p.metodoPago == 'Efectivo')
        .fold<double>(0, (sum, p) => sum + p.total);
    final tarjeta = ventasHoy
        .where((p) => p.metodoPago == 'Tarjeta')
        .fold<double>(0, (sum, p) => sum + p.total);
    final totalVentas = efectivo + tarjeta;

    double ultimoTotal = 0.0;
    if (caja.movimientos.isNotEmpty) {
      final ultimoMovimiento = caja.movimientos.last;
      if (ultimoMovimiento.tipo == 'venta') {
        ultimoTotal = ultimoMovimiento.cantidad;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCaja(caja),
          const SizedBox(height: 20),
          _buildResumenCaja(efectivo, tarjeta, totalVentas, 0),
          const SizedBox(height: 20),
          _buildAccionesCaja(esAdmin, caja),
          const SizedBox(height: 20),
          _buildMovimientosCaja(caja),
        ],
      ),
    );
  }

  Widget _buildInfoCaja(Caja caja) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CAJA ABIERTA',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      caja.cajeroNombre ?? 'Cajero',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(caja.fechaApertura),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
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
                  DateFormat('HH:mm').format(caja.fechaApertura),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Fondo inicial:',
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  '€${caja.fondoInicial.toStringAsFixed(2)}',
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
    );
  }

  Widget _buildResumenCaja(
    double efectivo,
    double tarjeta,
    double total,
    double ultimo,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          const Row(
            children: [
              Icon(Icons.analytics, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Resumen del día',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('EFECTIVO', efectivo, Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('TARJETA', tarjeta, Colors.blue)),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('TOTAL', total, AppColors.success),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '€${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccionesCaja(bool esAdmin, Caja caja) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _mostrarDialogoIngreso,
            icon: const Icon(Icons.add),
            label: const Text('Ingreso'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _mostrarDialogoRetiro,
            icon: const Icon(Icons.remove),
            label: const Text('Retiro'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _mostrarDialogoCerrarCaja(caja),
            icon: const Icon(Icons.lock),
            label: const Text('Cerrar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMovimientosCaja(Caja caja) {
    if (caja.movimientos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'No hay movimientos',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final movimientosRecientes = caja.movimientos.reversed.take(10).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          const Row(
            children: [
              Icon(Icons.receipt_long, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Últimos movimientos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...movimientosRecientes.map((m) => _buildMovimientoItem(m)),
        ],
      ),
    );
  }

  Widget _buildMovimientoItem(MovimientoCaja m) {
    IconData icon;
    Color color;
    String tipoTexto;
    final bool esVenta = m.tipo == 'venta';

    switch (m.tipo) {
      case 'venta':
        icon = Icons.shopping_cart;
        color = AppColors.success;
        tipoTexto = 'Venta';
        break;
      case 'ingreso':
        icon = Icons.add_circle;
        color = AppColors.success;
        tipoTexto = 'Ingreso';
        break;
      case 'retiro':
        icon = Icons.remove_circle;
        color = AppColors.error;
        tipoTexto = 'Retiro';
        break;
      default:
        icon = Icons.money;
        color = Colors.grey;
        tipoTexto = m.tipo;
    }

    return InkWell(
      onTap: esVenta ? () => _mostrarTicket(m.pedidoId) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          color: esVenta ? Colors.grey.shade50 : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        tipoTexto,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (esVenta) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.print,
                          size: 14,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    m.descripcion ?? m.metodoPago ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${m.tipo == 'retiro' ? '-' : '+'}€${m.cantidad.toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                Text(
                  DateFormat('HH:mm').format(m.fecha),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarTicket(String? pedidoId) {
    if (pedidoId == null) return;

    final pedidos = ref.read(pedidosProvider);
    final pedido = pedidos.firstWhere(
      (p) => p.id == pedidoId,
      orElse: () => Pedido(
        id: '',
        mesaId: '',
        items: [],
        estado: EstadoPedido.abierto,
        horaApertura: DateTime.now(),
      ),
    );

    if (pedido.id.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pedido no encontrado')));
      return;
    }

    final negocio = ref.read(negocioProvider);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long, color: AppColors.primary),
                  const SizedBox(width: 12),
                  const Text(
                    'Ticket de Venta',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(pedido.horaApertura)}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              if (pedido.cajeroNombre != null)
                Text(
                  'Cajero: ${pedido.cajeroNombre}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              if (pedido.mesaId.isNotEmpty)
                Text(
                  'Mesa: ${pedido.mesaId}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              const SizedBox(height: 16),
              const Text(
                'Productos:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...pedido.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('${item.cantidad}x ${item.productoNombre}'),
                      ),
                      Text('€${item.subtotal.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    '€${pedido.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Método de pago: ${pedido.metodoPago ?? "No especificado"}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                      label: const Text('Cerrar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        PrintService.printTicket(
                          items: pedido.items,
                          subtotal: pedido.total,
                          ivaPorcentaje: negocio.ivaPorcentaje,
                          metodoPago: pedido.metodoPago ?? 'Efectivo',
                          negocio: negocio,
                          mesaNumero: pedido.mesaId,
                          cajeroNombre: pedido.cajeroNombre,
                        );
                      },
                      icon: const Icon(Icons.print),
                      label: const Text('Imprimir'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
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

  Widget _buildHistorial(bool esAdmin, Cajero? cajeroActual) {
    final historial = ref.watch(cajasHistorialProvider);

    final cajasFiltradas = esAdmin || cajeroActual == null
        ? historial
        : historial.where((c) => c.cajeroId == cajeroActual.id).toList();

    if (cajasFiltradas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No hay cajas cerradas',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: cajasFiltradas.length,
      itemBuilder: (context, index) {
        final caja = cajasFiltradas[index];
        return _buildHistorialItem(caja, esAdmin);
      },
    );
  }

  Widget _buildHistorialItem(Caja caja, bool esAdmin) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lock, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      caja.cajeroNombre ?? 'Cajero',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${DateFormat('dd/MM/yyyy').format(caja.fechaApertura)} - ${DateFormat('HH:mm').format(caja.fechaApertura)} hasta ${caja.fechaCierre != null ? DateFormat('HH:mm').format(caja.fechaCierre!) : 'En curso'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '€${caja.saldoCaja.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildResumenItem('Fondo inicial', caja.fondoInicial),
              ),
              Expanded(child: _buildResumenItem('Ventas', caja.totalVentas)),
              Expanded(
                child: _buildResumenItem('Efectivo', caja.totalEfectivo),
              ),
              Expanded(child: _buildResumenItem('Tarjeta', caja.totalTarjeta)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResumenItem(String label, double value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          '€${value.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  void _abrirCaja() async {
    final cajeroActual = ref.read(cajeroActualProvider);
    if (cajeroActual == null) return;

    final fondoInicial = double.tryParse(_montoController.text) ?? 0;

    await ref
        .read(cajaProvider.notifier)
        .abrirCaja(
          fondoInicial: fondoInicial,
          cajeroId: cajeroActual.id,
          cajeroNombre: cajeroActual.nombre,
        );

    _montoController.text = '0.00';

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Caja abierta correctamente'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _mostrarDialogoCerrarCaja(Caja caja) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock, color: AppColors.error),
            SizedBox(width: 12),
            Text('Cerrar Caja'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildResumenCierre('Fondo inicial', caja.fondoInicial),
            _buildResumenCierre('Ventas efectivo', caja.totalEfectivo),
            _buildResumenCierre('Ventas tarjeta', caja.totalTarjeta),
            const Divider(),
            _buildResumenCierre('Saldo en caja', caja.saldoCaja, isTotal: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(cajaProvider.notifier)
                  .cerrarCaja(saldoFinal: caja.saldoCaja);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Caja cerrada correctamente'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Confirmar cierre'),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenCierre(
    String label,
    double value, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            '€${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 14,
              color: isTotal ? AppColors.success : null,
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoIngreso() {
    final montoCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.add_circle, color: AppColors.success),
            SizedBox(width: 12),
            Text('Nuevo Ingreso'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: montoCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                prefixText: '€ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final cantidad = double.tryParse(montoCtrl.text);
              if (cantidad != null && cantidad > 0) {
                Navigator.pop(ctx);
                await ref
                    .read(cajaProvider.notifier)
                    .agregarIngreso(
                      cantidad,
                      descCtrl.text.isEmpty ? 'Ingreso manual' : descCtrl.text,
                    );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoRetiro() {
    final montoCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.remove_circle, color: AppColors.warning),
            SizedBox(width: 12),
            Text('Nuevo Retiro'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: montoCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                prefixText: '€ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final cantidad = double.tryParse(montoCtrl.text);
              if (cantidad != null && cantidad > 0) {
                Navigator.pop(ctx);
                await ref
                    .read(cajaProvider.notifier)
                    .agregarRetiro(
                      cantidad,
                      descCtrl.text.isEmpty ? 'Retiro manual' : descCtrl.text,
                    );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}
