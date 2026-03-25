import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
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
    final historial = ref.read(cajasHistorialProvider);
    final ultimoSaldo = historial.isNotEmpty ? historial.first.saldoCaja : 0.0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
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
          const SizedBox(height: 8),
          Text(
            cajeroActual != null
                ? 'Usuario: ${cajeroActual.nombre}'
                : 'Ningún usuario logueado',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text('FONDO INICIAL', style: TextStyle(letterSpacing: 1)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_formatearImporte(_importeKeypadCaja)} €',
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Última caja: €${ultimoSaldo.toStringAsFixed(2)}',
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: cajeroActual != null
                        ? () {
                            final monto = _getImporteNumerico();
                            _montoController.text = monto.toStringAsFixed(2);
                            _abrirCaja();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
          const Spacer(),
        ],
      ),
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
            _buildTeclaAccion('C', 56),
            _buildTecla('0', 56),
            _buildTeclaAccion('⌫', 56),
          ],
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
            borderRadius: BorderRadius.circular(8),
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

  Widget _buildTeclaAccion(String tecla, double size) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _actualizarImporteCaja(tecla),
        onLongPress: () => _actualizarImporteCaja('C'),
        child: Container(
          height: size,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
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
                      '${caja.cajeroNombre ?? 'Cajero'} - ${DateFormat('HH:mm').format(caja.fechaApertura)}',
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Expanded(child: _buildMovimientosCaja(caja)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, double valor, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
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
        borderRadius: BorderRadius.circular(12),
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
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(
                              esIngreso
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: esIngreso
                                  ? AppColors.success
                                  : AppColors.error,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mov.descripcion ?? mov.tipo,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('HH:mm').format(mov.fecha),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${esIngreso ? '+' : '-'}€${mov.cantidad.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
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
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final cajaHist = historial[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('dd/MM/yyyy').format(
                                    cajaHist.fechaCierre ??
                                        cajaHist.fechaApertura,
                                  ),
                                ),
                                Text(
                                  DateFormat('HH:mm').format(
                                    cajaHist.fechaCierre ??
                                        cajaHist.fechaApertura,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Cajero:',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      Text(
                                        cajaHist.cajeroNombre ?? '-',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Efectivo:',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      Text(
                                        '€${cajaHist.totalEfectivo.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tarjeta:',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      Text(
                                        '€${cajaHist.totalTarjeta.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '€${cajaHist.saldoCaja.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
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
}
