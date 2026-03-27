import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../providers/providers.dart';
import 'venta_libre_screen.dart';
import 'productos_screen.dart';
import 'informes_screen.dart';
import 'mesas_screen.dart';
import 'configuracion_screen.dart';
import 'caja_screen.dart';
import 'clientes_screen.dart';
import 'usuarios_screen.dart';
import 'package:window_manager/window_manager.dart';

class AppShell extends ConsumerWidget {
  final VoidCallback? onLogout;

  const AppShell({super.key, this.onLogout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final negocio = ref.watch(negocioProvider);
    final caja = ref.watch(cajaProvider);
    final cajeroActual = ref.watch(cajeroActualProvider);
    final indiceActual = ref.watch(indiceNavegacionProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        final isMedium =
            constraints.maxWidth > 600 && constraints.maxWidth <= 900;

        return Scaffold(
          body: Row(
            children: [
              _buildMenuVertical(
                context,
                ref,
                indiceActual,
                cajeroActual,
                isWide: isWide,
                isMedium: isMedium,
              ),
              Expanded(
                child: Column(
                  children: [
                    _buildHeader(context, ref, negocio, caja, cajeroActual),
                    Expanded(child: _buildContenido(indiceActual)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    DatosNegocio negocio,
    Caja? caja,
    Cajero? cajeroActual,
  ) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 20,
        right: 20,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.85)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.zero,
            ),
            child: const Icon(Icons.restaurant, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  negocio.nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: caja?.estado == EstadoCaja.abierta
                            ? Colors.greenAccent
                            : Colors.red.shade300,
                        shape: BoxShape.rectangle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      caja?.estado == EstadoCaja.abierta
                          ? 'Caja abierta'
                          : 'Caja cerrada',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.person,
                      size: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      cajeroActual?.nombre ?? 'Usuario',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildUserMenu(ref, cajeroActual),
        ],
      ),
    );
  }

  Widget _buildUserMenu(WidgetRef ref, Cajero? cajeroActual) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.zero,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.rectangle,
              ),
              child: Icon(
                cajeroActual?.isAdministrador == true
                    ? Icons.admin_panel_settings
                    : Icons.person,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              cajeroActual?.nombre ?? 'Usuario',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white),
          ],
        ),
      ),
      onSelected: (value) async {
        if (value == 'logout') {
          await _borrarSesion();
          ref.read(cajeroActualProvider.notifier).state = null;
          ref.read(isLoggedInProvider.notifier).state = false;
          onLogout?.call();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cajeroActual?.nombre ?? 'Usuario',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
              if (cajeroActual?.isAdministrador == true)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: const Text(
                    'Administrador',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.red, size: 20),
              SizedBox(width: 10),
              Text('Cerrar sesión'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuVertical(
    BuildContext context,
    WidgetRef ref,
    int indiceActual,
    Cajero? cajeroActual, {
    bool isWide = false,
    bool isMedium = false,
  }) {
    final anchoMenu = isWide ? 120.0 : 60.0;
    final mostrarTexto = isWide;

    return Container(
      width: anchoMenu,
      height: double.infinity,
      color: AppColors.primary,
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildMenuVerticalItem(
            icon: Icons.point_of_sale,
            label: 'Venta',
            isSelected: indiceActual == 0,
            onTap: () => ref.read(indiceNavegacionProvider.notifier).state = 0,
            mostrarTexto: mostrarTexto,
          ),
          _buildMenuVerticalItem(
            icon: Icons.inventory_2,
            label: 'Productos',
            isSelected: indiceActual == 1,
            onTap: () => ref.read(indiceNavegacionProvider.notifier).state = 1,
            mostrarTexto: mostrarTexto,
          ),
          _buildMenuVerticalItem(
            icon: Icons.table_restaurant,
            label: 'Mesas',
            isSelected: indiceActual == 2,
            onTap: () => ref.read(indiceNavegacionProvider.notifier).state = 2,
            mostrarTexto: mostrarTexto,
          ),
          _buildMenuVerticalItem(
            icon: Icons.people,
            label: 'Clientes',
            isSelected: indiceActual == 3,
            onTap: () => ref.read(indiceNavegacionProvider.notifier).state = 3,
            mostrarTexto: mostrarTexto,
          ),
          const Divider(color: Colors.white24, height: 24),
          _buildMenuVerticalItem(
            icon: Icons.account_balance_wallet,
            label: 'Caja',
            isSelected: indiceActual == 4,
            onTap: () => ref.read(indiceNavegacionProvider.notifier).state = 4,
            mostrarTexto: mostrarTexto,
          ),
          if (cajeroActual?.isAdministrador == true)
            _buildMenuVerticalItem(
              icon: Icons.people_alt,
              label: 'Usuarios',
              isSelected: indiceActual == 5,
              onTap: () =>
                  ref.read(indiceNavegacionProvider.notifier).state = 5,
              mostrarTexto: mostrarTexto,
            ),
          _buildMenuVerticalItem(
            icon: Icons.analytics,
            label: 'Informes',
            isSelected: indiceActual == 6,
            onTap: () => ref.read(indiceNavegacionProvider.notifier).state = 6,
            mostrarTexto: mostrarTexto,
          ),
          _buildMenuVerticalItem(
            icon: Icons.settings,
            label: 'Config',
            isSelected: indiceActual == 7,
            onTap: () => ref.read(indiceNavegacionProvider.notifier).state = 7,
            mostrarTexto: mostrarTexto,
          ),
          _buildMenuVerticalItem(
            icon: Icons.exit_to_app,
            label: 'Salir',
            isSelected: false,
            onTap: () async {
              final confirmar = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Salir'),
                  content: const Text('¿Salir de la aplicación?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Salir'),
                    ),
                  ],
                ),
              );
              if (confirmar == true) {
                exit(0);
              }
            },
            mostrarTexto: mostrarTexto,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuVerticalItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool mostrarTexto = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.zero,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : Colors.white70,
              size: 22,
            ),
            if (mostrarTexto) ...[
              const SizedBox(height: 3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : Colors.white70,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContenido(int indice) {
    switch (indice) {
      case 0:
        return const VentaLibreScreen();
      case 1:
        return const ProductosScreen();
      case 2:
        return const MesasScreen();
      case 3:
        return const ClientesScreen();
      case 4:
        return const CajaScreen();
      case 5:
        return const UsuariosScreen();
      case 6:
        return const InformesScreen();
      case 7:
        return const ConfiguracionScreen();
      default:
        return const VentaLibreScreen();
    }
  }

  Future<void> _borrarSesion() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/tpv_session.json');
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('Error borrando sesión: $e');
    }
  }
}
