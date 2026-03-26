import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../providers/providers.dart';
import '../widgets/cocina_ticket.dart';

class CocinaScreen extends ConsumerWidget {
  const CocinaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenH = MediaQuery.of(context).size.height;
    final isCompact = screenH < 600;
    final pedidos = ref.watch(pedidosProvider);
    final mesas = ref.watch(mesasProvider);

    final pendientes = pedidos
        .where((p) => p.estado == EstadoPedido.enviadoCocina)
        .toList();
    final enPreparacion = pedidos
        .where((p) => p.estado == EstadoPedido.enPreparacion)
        .toList();
    final listos = pedidos
        .where((p) => p.estado == EstadoPedido.listo)
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(isCompact ? 12 : 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cocina',
                        style: TextStyle(
                          fontSize: isCompact ? 22 : 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: isCompact ? 2 : 4),
                      Text(
                        'Pedidos en cola',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: isCompact ? 12 : 14,
                        ),
                      ),
                    ],
                  ),
                  _buildContador(
                    pendientes.length,
                    enPreparacion.length,
                    listos.length,
                    isCompact: isCompact,
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildColumna(
                      context,
                      ref,
                      'Nuevos',
                      pendientes,
                      AppColors.error,
                      AppColors.error,
                      mesas,
                      isCompact: isCompact,
                    ),
                    _buildColumna(
                      context,
                      ref,
                      'Preparando',
                      enPreparacion,
                      AppColors.warning,
                      AppColors.warning,
                      mesas,
                      isCompact: isCompact,
                    ),
                    _buildColumna(
                      context,
                      ref,
                      'Listos',
                      listos,
                      AppColors.success,
                      AppColors.success,
                      mesas,
                      isCompact: isCompact,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContador(
    int pendientes,
    int preparacion,
    int listos, {
    bool isCompact = false,
  }) {
    return Row(
      children: [
        _contadorBadge(
          pendientes,
          AppColors.error,
          'Pendientes',
          isCompact: isCompact,
        ),
        SizedBox(width: isCompact ? 8 : 12),
        _contadorBadge(
          preparacion,
          AppColors.warning,
          'Preparando',
          isCompact: isCompact,
        ),
        SizedBox(width: isCompact ? 8 : 12),
        _contadorBadge(
          listos,
          AppColors.success,
          'Listos',
          isCompact: isCompact,
        ),
      ],
    );
  }

  Widget _contadorBadge(
    int count,
    Color color,
    String texto, {
    bool isCompact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.zero,
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isCompact ? 4 : 6),
            decoration: BoxDecoration(color: color, shape: BoxShape.rectangle),
            child: Text(
              '$count',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isCompact ? 10 : 12,
              ),
            ),
          ),
          SizedBox(width: isCompact ? 4 : 8),
          Text(
            texto,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: isCompact ? 10 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumna(
    BuildContext context,
    WidgetRef ref,
    String titulo,
    List<Pedido> pedidos,
    Color colorHeader,
    Color colorAccent,
    List<Mesa> mesas, {
    bool isCompact = false,
  }) {
    return Container(
      width: isCompact ? 280 : 300,
      margin: EdgeInsets.only(right: isCompact ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 12 : 16,
              vertical: isCompact ? 8 : 12,
            ),
            decoration: BoxDecoration(
              color: colorAccent,
              borderRadius: BorderRadius.zero,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isCompact ? 14 : 16,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 8 : 10,
                    vertical: isCompact ? 2 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Text(
                    '${pedidos.length}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isCompact ? 12 : 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isCompact ? 10 : 16),
          if (pedidos.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: isCompact ? 36 : 48,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: isCompact ? 8 : 12),
                    Text(
                      'Sin pedidos',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: isCompact ? 12 : 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: pedidos.length,
                itemBuilder: (context, index) {
                  final pedido = pedidos[index];
                  final mesa = mesas.firstWhere(
                    (m) => m.id == pedido.mesaId,
                    orElse: () => Mesa(id: '', numero: 0, capacidad: 0),
                  );
                  return Padding(
                    padding: EdgeInsets.only(bottom: isCompact ? 10 : 16),
                    child: CocinaTicket(
                      pedido: pedido,
                      numeroMesa: mesa.numero.toString(),
                      onEstadoChange: () => _avanzarEstado(ref, pedido),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _avanzarEstado(WidgetRef ref, Pedido pedido) {
    final notifier = ref.read(pedidosProvider.notifier);
    switch (pedido.estado) {
      case EstadoPedido.enviadoCocina:
        notifier.marcarEnPreparacion(pedido.id);
        break;
      case EstadoPedido.enPreparacion:
        notifier.marcarListo(pedido.id);
        break;
      case EstadoPedido.listo:
        notifier.cerrar(pedido.id, 'Entregado');
        break;
      default:
        break;
    }
  }
}
