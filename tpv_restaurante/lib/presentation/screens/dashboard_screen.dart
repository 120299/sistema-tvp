import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../providers/providers.dart';
import 'venta_libre_screen.dart';
import 'productos_screen.dart';
import 'informes_screen.dart';
import 'mesas_screen.dart';
import 'caja_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indiceActual = ref.watch(indiceNavegacionProvider);
    final themeMode = ref.watch(themeModeProvider);
    final negocio = ref.watch(negocioProvider);
    final caja = ref.watch(cajaProvider);

    final pantallas = [
      const VentaLibreScreen(),
      const ProductosScreen(),
      const InformesScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.restaurant, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                negocio.nombre,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              caja?.estado == EstadoCaja.abierta
                  ? Icons.point_of_sale
                  : Icons.point_of_sale_outlined,
              color: caja?.estado == EstadoCaja.abierta
                  ? AppColors.success
                  : null,
            ),
            tooltip: 'Caja',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CajaScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.table_restaurant),
            tooltip: 'Mesas',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MesasScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(
              themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
            ),
            tooltip: themeMode == ThemeMode.dark ? 'Modo Claro' : 'Modo Oscuro',
            onPressed: () {
              ref
                  .read(themeModeProvider.notifier)
                  .state = themeMode == ThemeMode.dark
                  ? ThemeMode.light
                  : ThemeMode.dark;
            },
          ),
        ],
      ),
      body: IndexedStack(index: indiceActual, children: pantallas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: indiceActual,
        onDestinationSelected: (index) {
          ref.read(indiceNavegacionProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale),
            label: 'Venta',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Productos',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Informes',
          ),
        ],
      ),
    );
  }
}
