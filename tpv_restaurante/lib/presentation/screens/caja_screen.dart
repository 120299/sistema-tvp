import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ticket_helper.dart';
import '../../data/models/models.dart';
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Removed top module as requested, moved inside Fondo Inicial container

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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
          const SizedBox(height: 40),
          Container(
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
                      border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.history, color: AppColors.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                '${ultimoSaldo.toStringAsFixed(2)} €',
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
                              _importeKeypadCaja = ultimoSaldo.toStringAsFixed(2).replaceAll('.', ',');
                              _montoController.text = _importeKeypadCaja;
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
                    '${_importeKeypadCaja == "0" ? "0,00" : _importeKeypadCaja} €',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildKeypadCompacto(),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: cajeroActual != null ? () => _abrirCaja() : null,
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
          const SizedBox(height: 40),
        ],
      ),
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

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: const Icon(
                        Icons.point_of_sale,
                        color: AppColors.success,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CAJA ABIERTA',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${caja.cajeroNombre ?? 'Cajero'} - ${_formatTime(caja.fechaApertura)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _mostrarHistorial = true),
                      icon: const Icon(Icons.history),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard('EFECTIVO', efectivo, Colors.green),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStatCard('TARJETA', tarjeta, Colors.blue)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard('TOTAL', totalVentas, AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildAccionButton(
                        Icons.add,
                        'Ingreso',
                        AppColors.success,
                        () => _mostrarDialogoIngreso(caja),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildAccionButton(
                        Icons.remove,
                        'Retiro',
                        AppColors.error,
                        () => _mostrarDialogoRetiro(caja),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (esAdmin)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _cerrarCaja(caja, efectivo, tarjeta),
                      icon: const Icon(Icons.lock),
                      label: const Text('CERRAR CAJA'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Expanded(child: _buildMovimientosCaja(caja)),
              ],
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildStatCard(String label, double valor, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${valor.toStringAsFixed(2)} €',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccionButton(
    IconData icono,
    String texto,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.zero,
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              texto,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
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
                : ListView.separated(
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
                              color:
                                  esIngreso
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
                                color:
                                    esIngreso
                                        ? AppColors.success
                                        : AppColors.error,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mov.descripcion ?? mov.tipo.toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        DateFormat('HH:mm').format(mov.fecha),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                      if (mov.metodoPago != null) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.zero,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                mov.metodoPago == 'Efectivo'
                                                    ? Icons.payments
                                                    : Icons.credit_card,
                                                size: 10,
                                                color: Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                mov.metodoPago!.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  color: Colors.grey.shade600,
                                                  fontWeight: FontWeight.bold,
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
                                color:
                                    esIngreso
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
    );
  }

  Widget _buildHistorial(bool esAdmin, Cajero? cajeroActual) {
    final historial = ref.watch(cajasHistorialProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _mostrarHistorial = false),
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 8),
              const Text(
                'HISTORIAL DE CAJAS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: historial.isEmpty
                ? Center(
                    child: Text(
                      'Sin historial',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  )
                : ListView.separated(
                    itemCount: historial.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final cajaHist = historial[index];
                      final fecha = cajaHist.fechaCierre ?? cajaHist.fechaApertura;
                      
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            left: BorderSide(color: AppColors.primary, width: 4),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Fecha y Horas
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('dd MMM').format(fecha).toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${DateFormat('HH:mm').format(cajaHist.fechaApertura)} - ${cajaHist.fechaCierre != null ? DateFormat('HH:mm').format(cajaHist.fechaCierre!) : '--:--'}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 20),
                            // Detalles
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cajaHist.cajeroNombre ?? 'SISTEMA',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      _buildSmallBadge('EF:', cajaHist.totalEfectivo, Colors.green),
                                      const SizedBox(width: 8),
                                      _buildSmallBadge('TA:', cajaHist.totalTarjeta, Colors.blue),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Total
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'TOTAL',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  '€${cajaHist.saldoCaja.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.print_outlined, size: 20),
                              onPressed: () {
                                final negocio = ref.read(negocioProvider);
                                TicketHelper.imprimirCierreCaja(negocio, cajaHist);
                              },
                              tooltip: 'Imprimir Cierre',
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

  Widget _buildSmallBadge(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.zero,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          Text(
            '€${value.toStringAsFixed(0)}',
            style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
          ),
        ],
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
          autofocus: true,
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
              autofocus: true,
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
              await TicketHelper.imprimirCierreCaja(negocio, caja);
              if (context.mounted) Navigator.pop(ctx, true);
            },
            icon: const Icon(Icons.print, size: 18),
            label: const Text('Imprimir y Cerrar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      await ref.read(cajaProvider.notifier).cerrarCaja();
    }
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '--:--';
    try {
      return DateFormat('HH:mm').format(date);
    } catch (_) {
      return '--:--';
    }
  }
}
