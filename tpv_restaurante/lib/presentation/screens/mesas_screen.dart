import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../providers/providers.dart';
import '../widgets/mesa_dialog.dart';
import '../widgets/common_scaffold.dart';
import 'mesa_detalle_screen.dart';

class MesasScreen extends ConsumerWidget {
  const MesasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mesas = ref.watch(mesasProvider);
    final stats = _calculateStats(mesas);

    return CommonScaffold(
      title: 'Mesas',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _agregarMesa(context),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Mesa'),
      ),
      body: Column(
        children: [
          _buildHeader(context, stats, mesas.length),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  int crossAxisCount = 6;
                  if (width < 1400) crossAxisCount = 5;
                  if (width < 1200) crossAxisCount = 4;
                  if (width < 900) crossAxisCount = 3;
                  if (width < 600) crossAxisCount = 2;

                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: mesas.length,
                    itemBuilder: (context, index) {
                      final mesa = mesas[index];
                      return _buildMesaCard(context, ref, mesa);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, int> _calculateStats(List<Mesa> mesas) {
    return {
      'libres': mesas.where((m) => m.estado == EstadoMesa.libre).length,
      'ocupadas': mesas.where((m) => m.estado == EstadoMesa.ocupada).length,
      'reservadas': mesas.where((m) => m.estado == EstadoMesa.reservada).length,
      'atencion': mesas
          .where((m) => m.estado == EstadoMesa.necesitaAtencion)
          .length,
    };
  }

  Widget _buildHeader(BuildContext context, Map<String, int> stats, int total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.table_restaurant, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestión de Mesas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Toca una mesa para gestionar',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
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
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$total mesas',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatChip(
                  Icons.check_circle,
                  '${stats['libres']}',
                  'Libres',
                  AppColors.mesaLibre,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatChip(
                  Icons.circle,
                  '${stats['ocupadas']}',
                  'Ocupadas',
                  AppColors.mesaOcupada,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatChip(
                  Icons.event,
                  '${stats['reservadas']}',
                  'Reservadas',
                  AppColors.mesaReservada,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatChip(
                  Icons.warning,
                  '${stats['atencion']}',
                  'Atención',
                  AppColors.mesaAtencion,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
    IconData icon,
    String count,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 4),
              Text(
                count,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMesaCard(BuildContext context, WidgetRef ref, Mesa mesa) {
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
        estadoTexto = 'Atención';
        estadoIcono = Icons.warning;
        break;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: estadoColor.withValues(alpha: 0.3), width: 2),
      ),
      child: InkWell(
        onTap: () => _abrirDetalleMesa(context, mesa),
        onLongPress: () => _mostrarOpcionesMesa(context, ref, mesa),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [estadoColor.withValues(alpha: 0.1), Colors.white],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: estadoColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.table_restaurant,
                  size: 32,
                  color: estadoColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Mesa ${mesa.numero}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: estadoColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(estadoIcono, size: 14, color: estadoColor),
                    const SizedBox(width: 4),
                    Text(
                      estadoTexto,
                      style: TextStyle(
                        fontSize: 12,
                        color: estadoColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${mesa.capacidad}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _abrirDetalleMesa(BuildContext context, Mesa mesa) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MesaDetalleScreen(mesa: mesa)),
    );
  }

  void _agregarMesa(BuildContext context) {
    showDialog(context: context, builder: (context) => const MesaDialog());
  }

  void _mostrarOpcionesMesa(BuildContext context, WidgetRef ref, Mesa mesa) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Mesa ${mesa.numero}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.visibility, color: AppColors.primary),
              title: const Text('Ver detalles'),
              onTap: () {
                Navigator.pop(context);
                _abrirDetalleMesa(context, mesa);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.orange),
              title: const Text('Editar mesa'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => MesaDialog(mesa: mesa),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text('Eliminar mesa'),
              onTap: () {
                Navigator.pop(context);
                _eliminarMesa(context, ref, mesa);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _eliminarMesa(BuildContext context, WidgetRef ref, Mesa mesa) {
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Mesa eliminada'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
