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
  final _descripcionController = TextEditingController();

  @override
  void dispose() {
    _montoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final caja = ref.watch(cajaProvider);
    final pedidos = ref.watch(pedidosProvider);

    final ventasHoy = pedidos.where((p) {
      return p.estado == EstadoPedido.cerrado &&
          p.horaApertura.year == DateTime.now().year &&
          p.horaApertura.month == DateTime.now().month &&
          p.horaApertura.day == DateTime.now().day;
    }).toList();

    final totalVentasHoy = ventasHoy.fold<double>(0, (sum, p) => sum + p.total);
    final efectivoHoy = ventasHoy
        .where((p) => p.metodoPago == 'Efectivo')
        .fold<double>(0, (sum, p) => sum + p.total);
    final tarjetaHoy = ventasHoy
        .where((p) => p.metodoPago == 'Tarjeta')
        .fold<double>(0, (sum, p) => sum + p.total);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Caja'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: caja == null || caja.estado == EstadoCaja.cerrada
          ? _buildCajaCerrada()
          : _buildCajaAbierta(
              caja,
              ventasHoy,
              totalVentasHoy,
              efectivoHoy,
              tarjetaHoy,
            ),
    );
  }

  Widget _buildCajaCerrada() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
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
            const SizedBox(height: 32),
            const Text(
              'Caja Cerrada',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Ingresa el fondo inicial para abrir',
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
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Abrir Caja',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _montoController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Fondo inicial',
                      prefixText: '€ ',
                      prefixIcon: Icon(Icons.account_balance_wallet),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _abrirCaja,
                    icon: const Icon(Icons.lock_open),
                    label: const Text('Abrir Caja'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildCajaAbierta(
    Caja caja,
    List<Pedido> ventasHoy,
    double totalVentasHoy,
    double efectivoHoy,
    double tarjetaHoy,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.success,
                  AppColors.success.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.point_of_sale,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Caja Abierta',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Desde ${DateFormat('HH:mm').format(caja.fechaApertura)}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${caja.saldoCaja.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Saldo',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Ventas',
                  '${ventasHoy.length}',
                  Icons.receipt,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total',
                  '${totalVentasHoy.toStringAsFixed(2)} €',
                  Icons.euro,
                  AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Efectivo',
                  '${efectivoHoy.toStringAsFixed(2)} €',
                  Icons.money,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Tarjeta',
                  '${tarjetaHoy.toStringAsFixed(2)} €',
                  Icons.credit_card,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildAccionCard(
                  'Ingreso',
                  Icons.add_circle,
                  AppColors.success,
                  () => _mostrarDialogoIngreso(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAccionCard(
                  'Retiro',
                  Icons.remove_circle,
                  AppColors.error,
                  () => _mostrarDialogoRetiro(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  'Fondo inicial',
                  '${caja.fondoInicial.toStringAsFixed(2)} €',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  'En efectivo',
                  '${efectivoHoy.toStringAsFixed(2)} €',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSeccionVentas(ventasHoy),
          const SizedBox(height: 24),
          _buildSeccionMovimientos(caja),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _cerrarCaja(caja),
              icon: const Icon(Icons.lock),
              label: const Text('Cerrar Caja'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.warning,
                side: const BorderSide(color: AppColors.warning),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icono,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
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

  Widget _buildAccionCard(
    String label,
    IconData icono,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, color: color, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionVentas(List<Pedido> ventasHoy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ultimas Ventas',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (ventasHoy.isEmpty)
          Center(
            child: Column(
              children: [
                Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  'No hay ventas hoy',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          )
        else
          ...ventasHoy
              .take(10)
              .map(
                (pedido) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: pedido.metodoPago == 'Efectivo'
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        pedido.metodoPago == 'Efectivo'
                            ? Icons.money
                            : Icons.credit_card,
                        color: pedido.metodoPago == 'Efectivo'
                            ? Colors.green
                            : Colors.blue,
                      ),
                    ),
                    title: Text(
                      DateFormat('HH:mm').format(pedido.horaApertura),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${pedido.items.length} productos'),
                    trailing: Text(
                      '${pedido.total.toStringAsFixed(2)} €',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildSeccionMovimientos(Caja caja) {
    final ingresos = caja.movimientos
        .where((m) => m.tipo == 'ingreso')
        .toList();
    final retiros = caja.movimientos.where((m) => m.tipo == 'retiro').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Movimientos de Caja',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (caja.movimientos.isEmpty)
          Center(
            child: Column(
              children: [
                Icon(Icons.swap_horiz, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  'No hay movimientos',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: caja.movimientos.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                final movimiento =
                    caja.movimientos[caja.movimientos.length - 1 - index];
                final isIngreso = movimiento.tipo == 'ingreso';
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isIngreso
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isIngreso ? Icons.add_circle : Icons.remove_circle,
                      color: isIngreso ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(
                    movimiento.descripcion?.isNotEmpty == true
                        ? movimiento.descripcion!
                        : (isIngreso ? 'Ingreso' : 'Retiro'),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(movimiento.fecha),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  trailing: Text(
                    '${isIngreso ? '+' : '-'}${movimiento.cantidad.toStringAsFixed(2)} €',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isIngreso ? Colors.green : Colors.red,
                    ),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ingresos:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${ingresos.fold<double>(0, (sum, m) => sum + m.cantidad).toStringAsFixed(2)} €',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Retiros:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${retiros.fold<double>(0, (sum, m) => sum + m.cantidad).toStringAsFixed(2)} €',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _abrirCaja() async {
    final fondoInicial = double.tryParse(_montoController.text) ?? 0;
    await ref.read(cajaProvider.notifier).abrirCaja(fondoInicial: fondoInicial);
    _montoController.clear();
  }

  void _mostrarDialogoIngreso() {
    _montoController.clear();
    _descripcionController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.add_circle, color: AppColors.success),
            SizedBox(width: 12),
            Text('Ingreso'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _montoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                prefixText: '€ ',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripcion (opcional)',
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
              final monto = double.tryParse(_montoController.text) ?? 0;
              if (monto > 0) {
                ref
                    .read(cajaProvider.notifier)
                    .agregarIngreso(monto, _descripcionController.text);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoRetiro() {
    _montoController.clear();
    _descripcionController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.remove_circle, color: AppColors.error),
            SizedBox(width: 12),
            Text('Retiro'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _montoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                prefixText: '€ ',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripcion (opcional)',
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
              final monto = double.tryParse(_montoController.text) ?? 0;
              if (monto > 0) {
                ref
                    .read(cajaProvider.notifier)
                    .agregarRetiro(monto, _descripcionController.text);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _cerrarCaja(Caja caja) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppColors.warning),
            SizedBox(width: 12),
            Text('Cerrar Caja'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Se cerrara la caja con el saldo actual:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Saldo final:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${caja.saldoCaja.toStringAsFixed(2)} €',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: AppColors.success,
                    ),
                  ),
                ],
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
              ref
                  .read(cajaProvider.notifier)
                  .cerrarCaja(saldoFinal: caja.saldoCaja);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Cerrar Caja'),
          ),
        ],
      ),
    );
  }
}
