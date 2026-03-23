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
import 'configuracion_screen.dart';

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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'config':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ConfiguracionScreen(),
                    ),
                  );
                  break;
                case 'Acerca de':
                  _showAboutDialog(context);
                  break;
                case 'ver_datos':
                  _showDataManager(context, ref);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'config',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: AppColors.primary),
                    SizedBox(width: 12),
                    Text('Configuración'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'ver_datos',
                child: Row(
                  children: [
                    Icon(Icons.storage, color: AppColors.secondary),
                    SizedBox(width: 12),
                    Text('Ver Datos'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'Acerca de',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.textSecondary),
                    SizedBox(width: 12),
                    Text('Acerca de'),
                  ],
                ),
              ),
            ],
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

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.restaurant, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            const Text('TPV Restaurante'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Versión 2.0.0',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Sistema profesional de Terminal Punto de Venta para restaurantes y cafeterías.',
            ),
            SizedBox(height: 16),
            Text(
              'Cumple con el Real Decreto 1496/2003 sobre facturación.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showDataManager(BuildContext context, WidgetRef ref) {
    final productos = ref.watch(productosProvider);
    final categorias = ref.watch(categoriasProvider);
    final mesas = ref.watch(mesasProvider);
    final pedidos = ref.watch(pedidosProvider);
    final negocio = ref.watch(negocioProvider);

    final pedidosCerrados = pedidos
        .where((p) => p.estado == EstadoPedido.cerrado)
        .toList();
    final totalVentas = pedidosCerrados.fold<double>(
      0,
      (sum, p) => sum + p.total,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.storage, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Datos Guardados',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Información almacenada en el sistema',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              _buildDataSection(context, 'Negocio', Icons.store, [
                _buildDataItem('Nombre', negocio.nombre),
                _buildDataItem('CIF/NIF', negocio.cifNif ?? 'No configurado'),
                _buildDataItem('IVA', '${negocio.ivaPorcentaje}%'),
                _buildDataItem('Dirección', negocio.direccion),
                _buildDataItem('Ciudad', negocio.ciudad),
              ]),
              const SizedBox(height: 16),
              _buildDataSection(
                context,
                'Pedidos (${pedidosCerrados.length} ventas)',
                Icons.receipt_long,
                [
                  _buildDataItem(
                    'Total Ventas',
                    '${totalVentas.toStringAsFixed(2)} €',
                  ),
                  _buildDataItem('Pedidos Totales', '${pedidos.length}'),
                ],
              ),
              const SizedBox(height: 16),
              _buildDataSection(
                context,
                'Productos (${productos.length})',
                Icons.inventory_2,
                productos
                    .take(5)
                    .map(
                      (p) => _buildDataItem(
                        p.nombre,
                        '${p.precio.toStringAsFixed(2)} €',
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              _buildDataSection(
                context,
                'Categorías (${categorias.length})',
                Icons.category,
                categorias
                    .map(
                      (c) => _buildDataItem(
                        c.icono + ' ' + c.nombre,
                        '${productos.where((p) => p.categoriaId == c.id).length} prod.',
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              _buildDataSection(
                context,
                'Mesas (${mesas.length})',
                Icons.table_restaurant,
                mesas
                    .map(
                      (m) => _buildDataItem(
                        'Mesa ${m.numero}',
                        m.estado == EstadoMesa.ocupada ? 'Ocupada' : 'Libre',
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataSection(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightDivider),
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: children,
      ),
    );
  }

  Widget _buildDataItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
