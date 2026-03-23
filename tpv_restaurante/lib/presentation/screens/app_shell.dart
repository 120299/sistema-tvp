import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../providers/providers.dart';
import 'venta_libre_screen.dart';
import 'productos_screen.dart';
import 'informes_screen.dart';
import 'mesas_screen.dart';
import 'configuracion_screen.dart';
import 'caja_screen.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indiceActual = ref.watch(indiceNavegacionProvider);
    final negocio = ref.watch(negocioProvider);
    final caja = ref.watch(cajaProvider);

    final pantallas = [
      const VentaLibreScreen(),
      const ProductosScreen(),
      const MesasScreen(),
      const ConfiguracionScreen(),
      const InformesScreen(),
    ];

    return Scaffold(
      body: Column(
        children: [
          _buildCabecera(context, negocio, caja),
          Expanded(
            child: IndexedStack(index: indiceActual, children: pantallas),
          ),
          _buildMenuFijo(context, ref, indiceActual),
        ],
      ),
    );
  }

  Widget _buildCabecera(
    BuildContext context,
    DatosNegocio negocio,
    Caja? caja,
  ) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.restaurant, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  negocio.nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: caja?.estado == EstadoCaja.abierta
                            ? AppColors.success
                            : AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      caja?.estado == EstadoCaja.abierta
                          ? 'Caja abierta'
                          : 'Caja cerrada',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.point_of_sale, color: Colors.white),
            tooltip: 'Caja',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CajaScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuFijo(BuildContext context, WidgetRef ref, int indiceActual) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NavigationBar(
              selectedIndex: indiceActual,
              onDestinationSelected: (index) {
                ref.read(indiceNavegacionProvider.notifier).state = index;
              },
              backgroundColor: Colors.transparent,
              indicatorColor: AppColors.primary.withValues(alpha: 0.3),
              height: 70,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: const [
                NavigationDestination(
                  icon: Icon(
                    Icons.point_of_sale_outlined,
                    color: Colors.white70,
                  ),
                  selectedIcon: Icon(Icons.point_of_sale, color: Colors.white),
                  label: 'Venta',
                ),
                NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined, color: Colors.white70),
                  selectedIcon: Icon(Icons.inventory_2, color: Colors.white),
                  label: 'Productos',
                ),
                NavigationDestination(
                  icon: Icon(
                    Icons.table_restaurant_outlined,
                    color: Colors.white70,
                  ),
                  selectedIcon: Icon(
                    Icons.table_restaurant,
                    color: Colors.white,
                  ),
                  label: 'Mesas',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined, color: Colors.white70),
                  selectedIcon: Icon(Icons.settings, color: Colors.white),
                  label: 'Config',
                ),
                NavigationDestination(
                  icon: Icon(Icons.analytics_outlined, color: Colors.white70),
                  selectedIcon: Icon(Icons.analytics, color: Colors.white),
                  label: 'Informes',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
