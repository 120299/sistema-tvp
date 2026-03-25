import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../providers/providers.dart';

class UsuariosScreen extends ConsumerStatefulWidget {
  const UsuariosScreen({super.key});

  @override
  ConsumerState<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends ConsumerState<UsuariosScreen> {
  @override
  Widget build(BuildContext context) {
    final cajeros = ref.watch(cajerosProvider);

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(cajeros),
          Expanded(
            child: cajeros.isEmpty
                ? _buildEmptyState()
                : _buildUsuarioList(cajeros),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'nuevo_usuario',
        onPressed: () => _mostrarDialogoUsuario(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          'Nuevo Usuario',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildHeader(List<Cajero> cajeros) {
    final activos = cajeros.where((c) => c.activo).length;
    final admins = cajeros.where((c) => c.isAdministrador && c.activo).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.manage_accounts,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Usuarios',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$activos activos • $admins administradores',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Total', '${cajeros.length}', Icons.people),
                  Container(height: 30, width: 1, color: Colors.white30),
                  _buildStatItem('Activos', '$activos', Icons.check_circle),
                  Container(height: 30, width: 1, color: Colors.white30),
                  _buildStatItem(
                    'Admin',
                    '$admins',
                    Icons.admin_panel_settings,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No hay usuarios registrados',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca el botón + para añadir un usuario',
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildUsuarioList(List<Cajero> cajeros) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cajeros.length,
      itemBuilder: (context, index) {
        final cajero = cajeros[index];
        return _buildUsuarioCard(cajero);
      },
    );
  }

  Widget _buildUsuarioCard(Cajero cajero) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _mostrarDialogoUsuario(context, cajero: cajero),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: cajero.isAdministrador
                    ? AppColors.warning.withValues(alpha: 0.2)
                    : AppColors.primary.withValues(alpha: 0.1),
                child: Icon(
                  cajero.isAdministrador
                      ? Icons.admin_panel_settings
                      : Icons.person,
                  color: cajero.isAdministrador
                      ? AppColors.warning
                      : AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          cajero.nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: cajero.isAdministrador
                                ? AppColors.warning.withValues(alpha: 0.2)
                                : AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            cajero.isAdministrador ? 'Admin' : 'Cajero',
                            style: TextStyle(
                              fontSize: 11,
                              color: cajero.isAdministrador
                                  ? AppColors.warning
                                  : AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cajero.activo ? 'Activo' : 'Inactivo',
                      style: TextStyle(
                        color: cajero.activo ? AppColors.success : Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: cajero.activo,
                onChanged: (value) {
                  ref
                      .read(cajerosProvider.notifier)
                      .actualizar(cajero.copyWith(activo: value));
                },
                activeColor: AppColors.success,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoUsuario(BuildContext context, {Cajero? cajero}) {
    final esEdicion = cajero != null;
    final nombreController = TextEditingController(text: cajero?.nombre ?? '');
    final pinController = TextEditingController(text: cajero?.pin ?? '');
    RolCajero rolSeleccionado = cajero?.rol ?? RolCajero.cajero;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(
                esEdicion ? Icons.edit : Icons.person_add,
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              Text(esEdicion ? 'Editar Usuario' : 'Nuevo Usuario'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pinController,
                  decoration: const InputDecoration(
                    labelText: 'PIN (opcional)',
                    prefixIcon: Icon(Icons.pin),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Rol',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setDialogState(
                          () => rolSeleccionado = RolCajero.cajero,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: rolSeleccionado == RolCajero.cajero
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: rolSeleccionado == RolCajero.cajero
                                  ? AppColors.primary
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person,
                                color: rolSeleccionado == RolCajero.cajero
                                    ? AppColors.primary
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Cajero',
                                style: TextStyle(
                                  color: rolSeleccionado == RolCajero.cajero
                                      ? AppColors.primary
                                      : Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => setDialogState(
                          () => rolSeleccionado = RolCajero.administrador,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: rolSeleccionado == RolCajero.administrador
                                ? AppColors.warning.withValues(alpha: 0.2)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: rolSeleccionado == RolCajero.administrador
                                  ? AppColors.warning
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.admin_panel_settings,
                                color:
                                    rolSeleccionado == RolCajero.administrador
                                    ? AppColors.warning
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Admin',
                                style: TextStyle(
                                  color:
                                      rolSeleccionado == RolCajero.administrador
                                      ? AppColors.warning
                                      : Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            if (esEdicion)
              TextButton(
                onPressed: () {
                  showDialog(
                    context: ctx,
                    builder: (ctx2) => AlertDialog(
                      title: const Text('Eliminar Usuario'),
                      content: Text('¿Eliminar a ${cajero.nombre}?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx2),
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            ref
                                .read(cajerosProvider.notifier)
                                .eliminar(cajero.id);
                            Navigator.pop(ctx2);
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                          ),
                          child: const Text('Eliminar'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nombreController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('El nombre es obligatorio')),
                  );
                  return;
                }

                final nuevoCajero = Cajero(
                  id:
                      cajero?.id ??
                      'cajero_${DateTime.now().millisecondsSinceEpoch}',
                  nombre: nombreController.text.trim(),
                  pin: pinController.text.trim().isNotEmpty
                      ? pinController.text.trim()
                      : null,
                  fechaCreacion: cajero?.fechaCreacion ?? DateTime.now(),
                  activo: cajero?.activo ?? true,
                  rol: rolSeleccionado,
                );

                if (esEdicion) {
                  ref.read(cajerosProvider.notifier).actualizar(nuevoCajero);
                } else {
                  ref.read(cajerosProvider.notifier).agregar(nuevoCajero);
                }
                Navigator.pop(ctx);
              },
              child: Text(esEdicion ? 'Guardar' : 'Añadir'),
            ),
          ],
        ),
      ),
    );
  }
}
