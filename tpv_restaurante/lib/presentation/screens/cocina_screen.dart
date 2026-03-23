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
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cocina',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Pedidos en cola',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  _buildContador(
                    pendientes.length,
                    enPreparacion.length,
                    listos.length,
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    ),
                    _buildColumna(
                      context,
                      ref,
                      'Preparando',
                      enPreparacion,
                      AppColors.warning,
                      AppColors.warning,
                      mesas,
                    ),
                    _buildColumna(
                      context,
                      ref,
                      'Listos',
                      listos,
                      AppColors.success,
                      AppColors.success,
                      mesas,
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

  Widget _buildContador(int pendientes, int preparacion, int listos) {
    return Row(
      children: [
        _contadorBadge(pendientes, AppColors.error, 'Pendientes'),
        const SizedBox(width: 12),
        _contadorBadge(preparacion, AppColors.warning, 'Preparando'),
        const SizedBox(width: 12),
        _contadorBadge(listos, AppColors.success, 'Listos'),
      ],
    );
  }

  Widget _contadorBadge(int count, Color color, String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            texto,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
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
    List<Mesa> mesas,
  ) {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorAccent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${pedidos.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (pedidos.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sin pedidos',
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
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
                    padding: const EdgeInsets.only(bottom: 16),
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
