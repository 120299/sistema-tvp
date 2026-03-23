import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../providers/providers.dart';

class CommonScaffold extends ConsumerWidget {
  final Widget? child;
  final String title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBackButton;
  final Widget? body;

  const CommonScaffold({
    super.key,
    this.child,
    required this.title,
    this.actions,
    this.floatingActionButton,
    this.showBackButton = false,
    this.body,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions:
            actions ??
            [
              IconButton(
                icon: Icon(
                  themeMode == ThemeMode.dark
                      ? Icons.light_mode
                      : Icons.dark_mode,
                ),
                tooltip: themeMode == ThemeMode.dark
                    ? 'Modo Claro'
                    : 'Modo Oscuro',
                onPressed: () {
                  ref
                      .read(themeModeProvider.notifier)
                      .state = themeMode == ThemeMode.dark
                      ? ThemeMode.light
                      : ThemeMode.dark;
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'ver_datos':
                      _showDataManager(context);
                      break;
                    case 'config':
                      Navigator.pushNamed(context, '/configuracion');
                      break;
                    case 'acerca':
                      showAboutDialog(
                        context: context,
                        applicationName: 'TPV Restaurante Pro',
                        applicationVersion: '2.0.0',
                        applicationIcon: const Icon(
                          Icons.restaurant,
                          size: 48,
                          color: AppColors.primary,
                        ),
                        children: const [
                          Text(
                            'Sistema profesional de Terminal Punto de Venta.',
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Cumple con el Real Decreto 1496/2003 sobre facturación.',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      );
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'ver_datos',
                    child: Row(
                      children: [
                        Icon(Icons.storage, color: AppColors.primary),
                        SizedBox(width: 12),
                        Text('Ver Datos'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'config',
                    child: Row(
                      children: [
                        Icon(Icons.settings, color: AppColors.textPrimary),
                        SizedBox(width: 12),
                        Text('Configuración'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'acerca',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.textPrimary),
                        SizedBox(width: 12),
                        Text('Acerca de'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
      ),
      body: body ?? child,
      floatingActionButton: floatingActionButton,
    );
  }

  void _showDataManager(BuildContext context) {
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
        builder: (context, scrollController) =>
            _DataManagerWidget(scrollController: scrollController),
      ),
    );
  }
}

class _DataManagerWidget extends ConsumerWidget {
  final ScrollController scrollController;

  const _DataManagerWidget({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return Container(
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
          const Row(
            children: [
              Icon(Icons.storage, color: AppColors.primary),
              SizedBox(width: 12),
              Text(
                'Datos Guardados',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Aquí puedes ver toda la información guardada en el sistema',
            style: TextStyle(color: Colors.grey),
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
              _buildDataItem(
                'Último pedido',
                pedidos.isNotEmpty
                    ? '${pedidos.last.horaApertura.day}/${pedidos.last.horaApertura.month}/${pedidos.last.horaApertura.year}'
                    : 'Sin pedidos',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDataSection(
            context,
            'Productos (${productos.length})',
            Icons.inventory_2,
            productos
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
                    '${productos.where((p) => p.categoriaId == c.id).length} productos',
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
          if (pedidosCerrados.isNotEmpty) ...[
            const Text(
              'Últimas Ventas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...pedidosCerrados
                .take(5)
                .map(
                  (pedido) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(
                        Icons.receipt,
                        color: AppColors.success,
                      ),
                      title: Text(
                        '${pedido.total.toStringAsFixed(2)} € - ${pedido.metodoPago ?? 'N/A'}',
                      ),
                      subtitle: Text(
                        '${pedido.items.length} productos - ${pedido.horaApertura.day}/${pedido.horaApertura.month}/${pedido.horaApertura.year}',
                      ),
                    ),
                  ),
                ),
          ],
          const SizedBox(height: 20),
        ],
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
