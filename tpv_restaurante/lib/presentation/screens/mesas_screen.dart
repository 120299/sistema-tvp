import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../providers/providers.dart';
import '../widgets/mesa_dialog.dart';
import 'mesa_detalle_screen.dart';

class MesasScreen extends ConsumerStatefulWidget {
  const MesasScreen({super.key});

  @override
  ConsumerState<MesasScreen> createState() => _MesasScreenState();
}

class _MesasScreenState extends ConsumerState<MesasScreen> {
  String _filtroEstado = 'todas';

  @override
  Widget build(BuildContext context) {
    final mesas = ref.watch(mesasProvider);
    final mesasFiltradas = _filtrarMesas(mesas);
    final stats = _calculateStats(mesas);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(stats, mesas.length),
          _buildFilterChips(),
          _buildMesasGrid(mesasFiltradas),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _agregarMesa(context),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Mesa'),
      ),
    );
  }

  List<Mesa> _filtrarMesas(List<Mesa> mesas) {
    switch (_filtroEstado) {
      case 'libres':
        return mesas.where((m) => m.estado == EstadoMesa.libre).toList();
      case 'ocupadas':
        return mesas.where((m) => m.estado == EstadoMesa.ocupada).toList();
      case 'reservadas':
        return mesas.where((m) => m.estado == EstadoMesa.reservada).toList();
      case 'atencion':
        return mesas
            .where((m) => m.estado == EstadoMesa.necesitaAtencion)
            .toList();
      default:
        return mesas;
    }
  }

  Widget _buildAppBar(Map<String, int> stats, int total) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                          Icons.table_restaurant,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mesas',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Gestión de salas y pedidos',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
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
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _buildStatBadge(
                        icon: Icons.check_circle,
                        count: stats['libres'] ?? 0,
                        label: 'Libres',
                        color: AppColors.mesaLibre,
                      ),
                      const SizedBox(width: 12),
                      _buildStatBadge(
                        icon: Icons.restaurant,
                        count: stats['ocupadas'] ?? 0,
                        label: 'Ocupadas',
                        color: AppColors.mesaOcupada,
                      ),
                      const SizedBox(width: 12),
                      _buildStatBadge(
                        icon: Icons.event,
                        count: stats['reservadas'] ?? 0,
                        label: 'Reservas',
                        color: AppColors.mesaReservada,
                      ),
                      const SizedBox(width: 12),
                      _buildStatBadge(
                        icon: Icons.notification_important,
                        count: stats['atencion'] ?? 0,
                        label: 'Atención',
                        color: AppColors.mesaAtencion,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required int count,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
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
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 18,
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
      ),
    );
  }

  Widget _buildFilterChips() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('todas', 'Todas', Icons.grid_view, null),
              const SizedBox(width: 8),
              _buildFilterChip(
                'libres',
                'Libres',
                Icons.check_circle,
                AppColors.mesaLibre,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'ocupadas',
                'Ocupadas',
                Icons.restaurant,
                AppColors.mesaOcupada,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'reservadas',
                'Reservadas',
                Icons.event,
                AppColors.mesaReservada,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'atencion',
                'Atención',
                Icons.notification_important,
                AppColors.mesaAtencion,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String value,
    String label,
    IconData icon,
    Color? color,
  ) {
    final isSelected = _filtroEstado == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected
                ? (color ?? AppColors.primary)
                : AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      onSelected: (_) => setState(() => _filtroEstado = value),
      backgroundColor: AppColors.lightSurface,
      selectedColor: (color ?? AppColors.primary).withValues(alpha: 0.15),
      checkmarkColor: color ?? AppColors.primary,
      side: BorderSide(
        color: isSelected
            ? (color ?? AppColors.primary)
            : AppColors.lightDivider,
      ),
    );
  }

  Widget _buildMesasGrid(List<Mesa> mesas) {
    if (mesas.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.table_restaurant,
                size: 80,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No hay mesas',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Toca el botón + para agregar mesas',
                style: TextStyle(color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.9,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildMesaCard(mesas[index]),
          childCount: mesas.length,
        ),
      ),
    );
  }

  Widget _buildMesaCard(Mesa mesa) {
    final estadoData = _getEstadoData(mesa.estado);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _abrirDetalleMesa(context, mesa),
        onLongPress: () => _mostrarMenuMesa(context, mesa),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [estadoData.color.withValues(alpha: 0.08), Colors.white],
            ),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: estadoData.color.withValues(alpha: 0.15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          estadoData.icono,
                          size: 16,
                          color: estadoData.color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          estadoData.texto,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: estadoData.color,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.people,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${mesa.capacidad}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: estadoData.color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.table_restaurant,
                          size: 40,
                          color: estadoData.color,
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
                      if (mesa.estado == EstadoMesa.ocupada &&
                          mesa.tiempoTranscurrido != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getTiempoColor(
                              mesa.tiempoTranscurrido!,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: _getTiempoColor(
                                  mesa.tiempoTranscurrido!,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatearTiempo(mesa.tiempoTranscurrido!),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _getTiempoColor(
                                    mesa.tiempoTranscurrido!,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _EstadoData _getEstadoData(EstadoMesa estado) {
    switch (estado) {
      case EstadoMesa.libre:
        return _EstadoData(AppColors.mesaLibre, 'Libre', Icons.check_circle);
      case EstadoMesa.ocupada:
        return _EstadoData(AppColors.mesaOcupada, 'Ocupada', Icons.restaurant);
      case EstadoMesa.reservada:
        return _EstadoData(AppColors.mesaReservada, 'Reservada', Icons.event);
      case EstadoMesa.necesitaAtencion:
        return _EstadoData(
          AppColors.mesaAtencion,
          'Atención',
          Icons.notification_important,
        );
    }
  }

  Color _getTiempoColor(Duration duracion) {
    if (duracion.inMinutes < 30) return AppColors.success;
    if (duracion.inMinutes < 60) return AppColors.warning;
    return AppColors.error;
  }

  String _formatearTiempo(Duration duracion) {
    if (duracion.inMinutes < 60) return '${duracion.inMinutes}m';
    return '${duracion.inHours}h ${duracion.inMinutes % 60}m';
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

  void _abrirDetalleMesa(BuildContext context, Mesa mesa) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MesaDetalleScreen(mesa: mesa)),
    );
  }

  void _agregarMesa(BuildContext context) {
    showDialog(context: context, builder: (context) => const MesaDialog());
  }

  void _mostrarMenuMesa(BuildContext context, Mesa mesa) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getEstadoData(
                        mesa.estado,
                      ).color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.table_restaurant,
                      color: _getEstadoData(mesa.estado).color,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mesa ${mesa.numero}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${mesa.capacidad} personas',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildMenuItem(
              icon: Icons.visibility,
              title: 'Ver detalles',
              color: AppColors.primary,
              onTap: () {
                Navigator.pop(context);
                _abrirDetalleMesa(context, mesa);
              },
            ),
            _buildMenuItem(
              icon: Icons.edit,
              title: 'Editar mesa',
              color: AppColors.warning,
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => MesaDialog(mesa: mesa),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.delete,
              title: 'Eliminar mesa',
              color: AppColors.error,
              onTap: () {
                Navigator.pop(context);
                _eliminarMesa(context, ref, mesa);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      onTap: onTap,
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

class _EstadoData {
  final Color color;
  final String texto;
  final IconData icono;

  _EstadoData(this.color, this.texto, this.icono);
}
