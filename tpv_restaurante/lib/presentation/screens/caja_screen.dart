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

class _CajaScreenState extends ConsumerState<CajaScreen> {
  final _montoController = TextEditingController();
  String _importeKeypadCaja = '0';
  bool _mostrarHistorial = false;
  DateTime? _fechaInicioFiltro;
  DateTime? _fechaFinFiltro;
  String _periodoSeleccionadoFiltro = 'todos';

  void _actualizarImporteCaja(String digito) {
    setState(() {
      if (digito == 'C' || digito == 'BORRAR TODO (C)') {
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

  double _getImporteNumerico() {
    return double.tryParse(_importeKeypadCaja.replaceAll(',', '.')) ?? 0.0;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarFondoSugerido();
    });
  }

  void _cargarFondoSugerido() {
    final historial = ref.read(cajasHistorialProvider);
    if (historial.isNotEmpty) {
      _montoController.text = historial.first.saldoCaja.toStringAsFixed(2);
    } else {
      _montoController.text = '0.00';
    }
  }

  @override
  void dispose() {
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
      child: SafeArea(
        child: _mostrarHistorial
            ? _buildHistorial(esAdmin, cajeroActual)
            : (caja == null || caja.estado == EstadoCaja.cerrada
                  ? _buildCajaCerrada(cajeroActual)
                  : _buildCajaAbierta(caja, esAdmin)),
      ),
    );
  }

  Widget _buildCajaCerrada(Cajero? cajeroActual) {
    final historial = ref.watch(cajasHistorialProvider);
    final ultimoSaldo = historial.isNotEmpty ? historial.first.saldoCaja : 0.0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: const Icon(
                      Icons.point_of_sale,
                      color: AppColors.warning,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'CAJA CERRADA',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _mostrarHistorial = true),
                    icon: const Icon(Icons.history),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                cajeroActual != null
                    ? 'Usuario: ${cajeroActual.nombre}'
                    : 'Ningún usuario logueado',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Column(
                      children: [
                        if (historial.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.05),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.1),
                              ),
                              borderRadius: BorderRadius.zero,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.history,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'SALDO ANTERIOR',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      Text(
                                        '€${ultimoSaldo.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _importeKeypadCaja = ultimoSaldo
                                          .toStringAsFixed(2)
                                          .replaceAll('.', ',');
                                      _montoController.text =
                                          _importeKeypadCaja;
                                    });
                                  },
                                  child: const Text('USAR SALDO'),
                                ),
                              ],
                            ),
                          ),
                        const Text(
                          'FONDO INICIAL',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.zero,
                          ),
                          child: Text(
                            '€${_importeKeypadCaja == "0" ? "0,00" : _importeKeypadCaja}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                        const Spacer(),
                        _buildKeypadCompacto(),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: cajeroActual != null
                                ? () => _abrirCaja()
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                            child: const Text(
                              'ABRIR CAJA',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
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
      ],
    );
  }

  void _abrirCaja() async {
    final cajeroActual = ref.read(cajeroActualProvider);
    if (cajeroActual == null) return;

    final monto = _getImporteNumerico();
    await ref
        .read(cajaProvider.notifier)
        .abrirCaja(
          fondoInicial: monto,
          cajeroId: cajeroActual.id,
          cajeroNombre: cajeroActual.nombre,
        );

    await ref.read(negocioProvider.notifier).reiniciarContadorDiario();
  }

  Widget _buildKeypadCompacto() {
    return Column(
      children: [
        Row(
          children: [
            _buildTecla('7', 56),
            _buildTecla('8', 56),
            _buildTecla('9', 56),
          ],
        ),
        Row(
          children: [
            _buildTecla('4', 56),
            _buildTecla('5', 56),
            _buildTecla('6', 56),
          ],
        ),
        Row(
          children: [
            _buildTecla('1', 56),
            _buildTecla('2', 56),
            _buildTecla('3', 56),
          ],
        ),
        Row(
          children: [
            _buildTecla(',', 56),
            _buildTecla('0', 56),
            _buildTeclaAccion('⌫', 56),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: _buildTeclaAccion('BORRAR TODO (C)', 48, expanded: false),
        ),
      ],
    );
  }

  Widget _buildTecla(String tecla, double size) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _actualizarImporteCaja(tecla),
        child: Container(
          height: size,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.zero,
          ),
          alignment: Alignment.center,
          child: Text(
            tecla,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildTeclaAccion(String tecla, double size, {bool expanded = true}) {
    final child = GestureDetector(
      onTap: () => _actualizarImporteCaja(tecla),
      onLongPress: () => _actualizarImporteCaja('C'),
      child: Container(
        height: size,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.zero,
        ),
        alignment: Alignment.center,
        child: tecla == '⌫'
            ? const Icon(Icons.backspace_outlined, size: 20)
            : Text(
                tecla,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );

    if (expanded) return Expanded(child: child);
    return child;
  }

  Widget _buildCajaAbierta(Caja caja, bool esAdmin) {
    final pedidos = ref.watch(pedidosProvider);
    final now = DateTime.now();

    final pedidosCaja = pedidos
        .where((p) => p.cajaId == caja.id && p.estado == EstadoPedido.cerrado)
        .toList();

    final efectivoCaja = pedidosCaja
        .where((p) => p.metodoPago == 'Efectivo')
        .fold<double>(0, (sum, p) => sum + p.total);
    final tarjetaCaja = pedidosCaja
        .where((p) => p.metodoPago == 'Tarjeta')
        .fold<double>(0, (sum, p) => sum + p.total);
    final totalCaja = efectivoCaja + tarjetaCaja;

    final pedidosDia = pedidos.where((p) {
      return p.estado == EstadoPedido.cerrado &&
          p.horaApertura.year == now.year &&
          p.horaApertura.month == now.month &&
          p.horaApertura.day == now.day;
    }).toList();

    final efectivoDia = pedidosDia
        .where((p) => p.metodoPago == 'Efectivo')
        .fold<double>(0, (sum, p) => sum + p.total);
    final tarjetaDia = pedidosDia
        .where((p) => p.metodoPago == 'Tarjeta')
        .fold<double>(0, (sum, p) => sum + p.total);
    final totalDia = efectivoDia + tarjetaDia;

    final horaApertura = caja.fechaApertura;
    final tiempoAbierta = DateTime.now().difference(horaApertura);
    final horas = tiempoAbierta.inHours;
    final minutos = tiempoAbierta.inMinutes % 60;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.zero,
                ),
                child: Icon(Icons.lock_open, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Caja Abierta',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${caja.cajeroNombre ?? 'Cajero'} • ${horas}h ${minutos}m',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _mostrarHistorial = true),
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Icon(Icons.history, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
        Flexible(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CAJA ACTUAL',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildResumenFila(
                        'Fondo Inicial',
                        caja.fondoInicial,
                        Icons.account_balance_wallet,
                        Colors.grey,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: _buildResumenFila(
                              'Ventas en Efectivo',
                              efectivoCaja,
                              Icons.payments,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _buildResumenFila(
                              'Ventas en Tarjeta',
                              tarjetaCaja,
                              Icons.credit_card,
                              Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: _buildResumenFila(
                              'Total Ventas',
                              totalCaja,
                              Icons.trending_up,
                              AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _buildResumenFila(
                              'Saldo en Caja',
                              caja.saldoCaja,
                              Icons.account_balance,
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VENTAS DEL DÍA',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildResumenFila(
                        'Total del Día',
                        totalDia,
                        Icons.analytics,
                        Colors.purple,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: _buildResumenFila(
                              'Ventas en Efectivo',
                              efectivoDia,
                              Icons.payments,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _buildResumenFila(
                              'Ventas en Tarjeta',
                              tarjetaDia,
                              Icons.credit_card,
                              Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _buildAccionButtonCompact(
                  Icons.add_circle,
                  'Ingreso',
                  AppColors.success,
                  () => _mostrarDialogoIngreso(caja),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAccionButtonCompact(
                  Icons.remove_circle,
                  'Retiro',
                  AppColors.error,
                  () => _mostrarDialogoRetiro(caja),
                ),
              ),
              const SizedBox(width: 8),
              if (esAdmin)
                Expanded(
                  flex: 2,
                  child: _buildAccionButtonCompact(
                    Icons.lock,
                    'Cerrar',
                    AppColors.warning,
                    () => _cerrarCaja(caja, efectivoCaja, tarjetaCaja),
                  ),
                ),
            ],
          ),
        ),
        Expanded(child: _buildMovimientosCaja(caja)),
      ],
    );
  }

  Widget _buildAccionButtonCompact(
    IconData icono,
    String texto,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                texto,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovimientosCaja(Caja caja) {
    final movimientos = caja.movimientos.reversed.take(10).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'MOVIMIENTOS',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
          Expanded(
            child: movimientos.isEmpty
                ? Center(
                    child: Text(
                      'Sin movimientos',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: movimientos.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: Colors.grey.shade200),
                          itemBuilder: (context, index) {
                            final mov = movimientos[index];
                            final esIngreso =
                                mov.tipo == 'ingreso' || mov.tipo == 'venta';
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border(
                                  left: BorderSide(
                                    color: esIngreso
                                        ? AppColors.success
                                        : AppColors.error,
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          (esIngreso
                                                  ? AppColors.success
                                                  : AppColors.error)
                                              .withOpacity(0.1),
                                      shape: BoxShape.rectangle,
                                    ),
                                    child: Icon(
                                      esIngreso
                                          ? Icons.arrow_downward
                                          : Icons.arrow_upward,
                                      color: esIngreso
                                          ? AppColors.success
                                          : AppColors.error,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          mov.descripcion ??
                                              mov.tipo.toUpperCase(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              DateFormat(
                                                'dd/MM/yyyy HH:mm',
                                              ).format(mov.fecha),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                            if (mov.metodoPago != null) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 1,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade100,
                                                  borderRadius:
                                                      BorderRadius.zero,
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      mov.metodoPago ==
                                                              'Efectivo'
                                                          ? Icons.payments
                                                          : Icons.credit_card,
                                                      size: 10,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      mov.metodoPago!
                                                          .toUpperCase(),
                                                      style: TextStyle(
                                                        fontSize: 9,
                                                        color: Colors
                                                            .grey
                                                            .shade600,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${esIngreso ? '+' : '-'}€${mov.cantidad.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: esIngreso
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorial(bool esAdmin, Cajero? cajeroActual) {
    final historial = ref.watch(cajasHistorialProvider);
    final historialFiltrado = _filtrarHistorial(historial);

    return Container(
      color: AppColors.lightBackground,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => _mostrarHistorial = false),
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Historial de Cajas',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
          ),
          // Filtros
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPeriodoChipHistorial('Hoy', 'hoy'),
                  const SizedBox(width: 8),
                  _buildPeriodoChipHistorial('Semana', 'semana'),
                  const SizedBox(width: 8),
                  _buildPeriodoChipHistorial('Mes', 'mes'),
                  const SizedBox(width: 8),
                  _buildPeriodoChipHistorial('Todos', 'todos'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Lista de cajas
          Expanded(
            child: historialFiltrado.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Sin historial de cajas',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: historialFiltrado.length,
                    itemBuilder: (context, index) {
                      final cajaHist = historialFiltrado[index];
                      final fecha =
                          cajaHist.fechaCierre ?? cajaHist.fechaApertura;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.zero,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header de la caja
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primary.withOpacity(0.8),
                                  ],
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.zero,
                                    ),
                                    child: const Icon(
                                      Icons.lock,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          DateFormat(
                                            'EEEE, dd MMM yyyy',
                                          ).format(fecha).toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${DateFormat('HH:mm').format(cajaHist.fechaApertura)} - ${cajaHist.fechaCierre != null ? DateFormat('HH:mm').format(cajaHist.fechaCierre!) : 'Abierta'}',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.8,
                                            ),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    cajaHist.cajeroNombre ?? 'Sistema',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Resumen de caja
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  // Fila 1: Fondo Inicial
                                  _buildResumenFila(
                                    'Fondo Inicial',
                                    cajaHist.fondoInicial,
                                    Icons.account_balance_wallet,
                                    Colors.grey,
                                  ),
                                  const SizedBox(height: 12),
                                  // Fila 2: Efectivo y Tarjeta
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildResumenFila(
                                          'Ventas en Efectivo',
                                          cajaHist.totalEfectivo,
                                          Icons.payments,
                                          Colors.green,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildResumenFila(
                                          'Ventas en Tarjeta',
                                          cajaHist.totalTarjeta,
                                          Icons.credit_card,
                                          Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Fila 3: Total y Saldo
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildResumenFila(
                                          'Total Ventas',
                                          cajaHist.totalVentas,
                                          Icons.trending_up,
                                          AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildResumenFila(
                                          'Saldo en Caja',
                                          cajaHist.saldoCaja,
                                          Icons.inventory_2,
                                          Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Acciones
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                border: Border(
                                  top: BorderSide(color: Colors.grey.shade200),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () async {
                                      final negocio = ref.read(negocioProvider);
                                      try {
                                        final pdf =
                                            await PrintService.buildCierreCajaPdf(
                                              negocio,
                                              cajaHist,
                                            );
                                        if (context.mounted) {
                                          await PrintService.previewCierreCaja(
                                            context: context,
                                            pdf: pdf,
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'No se pudo previsualizar: $e',
                                              ),
                                              backgroundColor: AppColors.error,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.print, size: 18),
                                    label: const Text('Imprimir'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenFila(
    String label,
    double valor,
    IconData icono,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.zero,
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.zero,
            ),
            child: Icon(icono, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '€${valor.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodoChipHistorial(String label, String value) {
    final isSelected = _periodoSeleccionadoFiltro == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _cambiarPeriodoFiltro(value),
      selectedColor: AppColors.primary.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  void _mostrarDialogoIngreso(Caja caja) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ingreso de Efectivo'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Cantidad',
            prefixText: '€ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final cantidad = double.tryParse(controller.text);
              if (cantidad != null && cantidad > 0) {
                ref
                    .read(cajaProvider.notifier)
                    .agregarIngreso(cantidad, 'Ingreso manual');
                Navigator.pop(ctx);
              }
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoRetiro(Caja caja) {
    final controller = TextEditingController();
    final causaController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retiro de Efectivo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                prefixText: '€ ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: causaController,
              decoration: const InputDecoration(
                labelText: 'Concepto (opcional)',
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
            onPressed: () {
              final cantidad = double.tryParse(controller.text);
              if (cantidad != null && cantidad > 0) {
                ref
                    .read(cajaProvider.notifier)
                    .agregarRetiro(
                      cantidad,
                      causaController.text.isEmpty
                          ? 'Retiro manual'
                          : causaController.text,
                    );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _cerrarCaja(Caja caja, double efectivo, double tarjeta) async {
    final total = efectivo + tarjeta;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar Caja'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Efectivo: €${efectivo.toStringAsFixed(2)}'),
            Text('Tarjeta: €${tarjeta.toStringAsFixed(2)}'),
            const Divider(),
            Text(
              'Total: €${total.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton.icon(
            onPressed: () async {
              final negocio = ref.read(negocioProvider);
              final cajaConCierre = caja.copyWith(
                estado: EstadoCaja.cerrada,
                fechaCierre: DateTime.now(),
                saldoFinal: efectivo + tarjeta,
              );
              try {
                final pdf = await PrintService.buildCierreCajaPdf(
                  negocio,
                  cajaConCierre,
                );
                if (context.mounted) {
                  await PrintService.previewCierreCaja(
                    context: context,
                    pdf: pdf,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('No se pudo imprimir: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
              if (context.mounted) Navigator.pop(ctx, true);
            },
            icon: const Icon(Icons.print, size: 18),
            label: const Text('Imprimir y Cerrar'),
          ),
          TextButton.icon(
            onPressed: () async {
              final negocio = ref.read(negocioProvider);
              final cajaConCierre = caja.copyWith(
                estado: EstadoCaja.cerrada,
                fechaCierre: DateTime.now(),
                saldoFinal: efectivo + tarjeta,
              );
              try {
                final pdf = await PrintService.buildCierreCajaPdf(
                  negocio,
                  cajaConCierre,
                );
                if (context.mounted) {
                  await PrintService.previewCierreCaja(
                    context: context,
                    pdf: pdf,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('No se pudo previsualizar: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
              if (context.mounted) Navigator.pop(ctx, true);
            },
            icon: const Icon(Icons.print_disabled, size: 18),
            label: const Text('Cerrar sin Imprimir'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      await ref
          .read(cajaProvider.notifier)
          .cerrarCaja(
            saldoFinal: total,
            totalEfectivo: efectivo,
            totalTarjeta: tarjeta,
            totalVentas: total,
          );
      // Limpiar datos de la sesión anterior
      if (mounted) {
        setState(() {
          _importeKeypadCaja = '0';
          _montoController.text = '0.00';
        });
      }
    }
  }

  void _cambiarPeriodoFiltro(String periodo) {
    setState(() {
      _periodoSeleccionadoFiltro = periodo;
      final now = DateTime.now();
      switch (periodo) {
        case 'hoy':
          _fechaInicioFiltro = DateTime(now.year, now.month, now.day);
          _fechaFinFiltro = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'semana':
          _fechaInicioFiltro = now.subtract(const Duration(days: 7));
          _fechaFinFiltro = now;
          break;
        case 'mes':
          _fechaInicioFiltro = now.subtract(const Duration(days: 30));
          _fechaFinFiltro = now;
          break;
        case 'trimestre':
          _fechaInicioFiltro = now.subtract(const Duration(days: 90));
          _fechaFinFiltro = now;
          break;
        case 'ano':
          _fechaInicioFiltro = now.subtract(const Duration(days: 365));
          _fechaFinFiltro = now;
          break;
        case 'todos':
        default:
          _fechaInicioFiltro = null;
          _fechaFinFiltro = null;
          break;
      }
    });
  }

  List<Caja> _filtrarHistorial(List<Caja> historial) {
    if (_fechaInicioFiltro == null && _fechaFinFiltro == null) {
      return historial;
    }
    return historial.where((caja) {
      final fecha = caja.fechaCierre ?? caja.fechaApertura;
      if (_fechaInicioFiltro != null && fecha.isBefore(_fechaInicioFiltro!)) {
        return false;
      }
      if (_fechaFinFiltro != null && fecha.isAfter(_fechaFinFiltro!)) {
        return false;
      }
      return true;
    }).toList();
  }
}
