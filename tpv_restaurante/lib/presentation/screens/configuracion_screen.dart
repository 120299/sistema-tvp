import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/services/backup_service.dart';
import '../../data/services/database_service.dart';
import '../providers/providers.dart';
import '../widgets/producto_import_dialog.dart';

class ConfiguracionScreen extends ConsumerStatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  ConsumerState<ConfiguracionScreen> createState() =>
      _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends ConsumerState<ConfiguracionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _razonSocialController;
  late TextEditingController _direccionController;
  late TextEditingController _ciudadController;
  late TextEditingController _telefonoController;
  late TextEditingController _emailController;
  late TextEditingController _cifController;
  late TextEditingController _ivaController;
  late TextEditingController _actividadController;
  bool _imprimeLogo = true;

  @override
  void initState() {
    super.initState();
    final negocio = ref.read(negocioProvider);
    _nombreController = TextEditingController(text: negocio.nombre);
    _razonSocialController = TextEditingController(
      text: negocio.razonSocial ?? '',
    );
    _direccionController = TextEditingController(text: negocio.direccion);
    _ciudadController = TextEditingController(text: negocio.ciudad);
    _telefonoController = TextEditingController(text: negocio.telefono);
    _emailController = TextEditingController(text: negocio.email ?? '');
    _cifController = TextEditingController(text: negocio.cifNif ?? '');
    _ivaController = TextEditingController(
      text: negocio.ivaPorcentaje.toString(),
    );
    _actividadController = TextEditingController(text: negocio.actividad ?? '');
    _imprimeLogo = negocio.imprimeLogo;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _razonSocialController.dispose();
    _direccionController.dispose();
    _ciudadController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _cifController.dispose();
    _ivaController.dispose();
    _actividadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración del Negocio'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _guardar),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSeccion('Datos Fiscales (Ley Española)', [
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre comercial *',
                    prefixIcon: Icon(Icons.store),
                  ),
                  validator: (v) => v?.isEmpty == true ? 'Obligatorio' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _razonSocialController,
                  decoration: const InputDecoration(
                    labelText: 'Razón Social',
                    prefixIcon: Icon(Icons.business),
                    helperText: 'Nombre legal de la empresa',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cifController,
                  decoration: const InputDecoration(
                    labelText: 'CIF/NIF *',
                    prefixIcon: Icon(Icons.badge),
                    helperText: 'Ej: B12345678 o 12345678A',
                  ),
                  validator: (v) => v?.isEmpty == true ? 'Obligatorio' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _actividadController,
                  decoration: const InputDecoration(
                    labelText: 'Actividad económica',
                    prefixIcon: Icon(Icons.category),
                    helperText: 'Ej: Hostelería, Restauración',
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              _buildSeccion('Datos del Negocio y Dirección', [
                TextFormField(
                  controller: _direccionController,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ciudadController,
                  decoration: const InputDecoration(
                    labelText: 'Ciudad',
                    prefixIcon: Icon(Icons.location_city),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _telefonoController,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono',
                          prefixIcon: Icon(Icons.phone),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Imprimir logo en tickets'),
                  subtitle: const Text(
                    'Incluye el logo del negocio en los tickets',
                  ),
                  value: _imprimeLogo,
                  onChanged: (value) => setState(() => _imprimeLogo = value),
                ),
              ]),
              const SizedBox(height: 24),
              _buildSeccion('Configuración de IVA (España)', [
                TextFormField(
                  controller: _ivaController,
                  decoration: const InputDecoration(
                    labelText: 'IVA (%)',
                    prefixIcon: Icon(Icons.percent),
                    helperText:
                        'IVA General: 21% | IVA Reducido: 10% | IVA Superreducido: 4%',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v?.isEmpty == true) return 'Obligatorio';
                    final iva = double.tryParse(v!);
                    if (iva == null || iva < 0 || iva > 100) {
                      return 'Introduce un porcentaje válido (0-100)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            setState(() => _ivaController.text = '4'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _ivaController.text == '4'
                              ? AppColors.primary
                              : Colors.grey.shade200,
                          foregroundColor: _ivaController.text == '4'
                              ? Colors.white
                              : Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          '4%',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            setState(() => _ivaController.text = '10'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _ivaController.text == '10'
                              ? AppColors.primary
                              : Colors.grey.shade200,
                          foregroundColor: _ivaController.text == '10'
                              ? Colors.white
                              : Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          '10%',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            setState(() => _ivaController.text = '21'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _ivaController.text == '21'
                              ? AppColors.primary
                              : Colors.grey.shade200,
                          foregroundColor: _ivaController.text == '21'
                              ? Colors.white
                              : Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          '21%',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 24),
              _buildSeccion('Copia de Seguridad', [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.backup, color: AppColors.primary),
                  title: const Text('Crear copia de seguridad'),
                  subtitle: const Text('Exporta todos los datos del sistema'),
                  trailing: ElevatedButton.icon(
                    onPressed: _crearBackup,
                    icon: const Icon(Icons.download),
                    label: const Text('Exportar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.restore,
                    color: AppColors.secondary,
                  ),
                  title: const Text('Restaurar copia de seguridad'),
                  subtitle: const Text(
                    'Importa datos desde un archivo de backup',
                  ),
                  trailing: ElevatedButton.icon(
                    onPressed: _mostrarDialogoRestaurar,
                    icon: const Icon(Icons.upload),
                    label: const Text('Importar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                // Reset del sistema
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Resetear sistema completo'),
                  subtitle: const Text(
                    'Borra todos los datos y reinicia el estado inicial',
                  ),
                  trailing: ElevatedButton.icon(
                    onPressed: _resetSystem,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reset'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              _buildSeccion('Gestión de Productos', [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border.all(color: Colors.orange.shade200),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.inventory_2,
                            size: 20,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Importar / Exportar',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Importa productos desde un archivo JSON o exporta los productos '
                        'actuales para editarlos y volver a importarlos.',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) =>
                                      const ProductoImportDialog(),
                                );
                              },
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Importar / Exportar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              _buildSeccion('Información Legal', [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.zero,
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Cumplimiento Legal',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Este sistema cumple con el Real Decreto 1496/2003 sobre facturación. '
                        'Los tickets emitidos son facturas simplificadas válidas para el consumidor. '
                        'Para requisitos fiscales adicionales, consulte con su asesor contable.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeccion(String titulo, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.zero,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      try {
        final negocio = DatosNegocio(
          nombre: _nombreController.text.trim(),
          razonSocial: _razonSocialController.text.isEmpty
              ? null
              : _razonSocialController.text.trim(),
          direccion: _direccionController.text.trim(),
          ciudad: _ciudadController.text.trim(),
          telefono: _telefonoController.text.trim(),
          email: _emailController.text.isEmpty
              ? null
              : _emailController.text.trim(),
          cifNif: _cifController.text.isEmpty
              ? null
              : _cifController.text.trim(),
          ivaPorcentaje: double.tryParse(_ivaController.text) ?? 10.0,
          imprimeLogo: _imprimeLogo,
          actividad: _actividadController.text.isEmpty
              ? null
              : _actividadController.text.trim(),
        );
        ref.read(negocioProvider.notifier).actualizar(negocio);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración guardada correctamente'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar configuración: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _crearBackup() async {
    try {
      final backupService = BackupService(ref);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final ruta = await backupService.crearBackup();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup creado: ${ruta.split('/').last}'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear backup: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _resetSystem() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Resetear Sistema'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que quieres borrar TODOS los datos?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Se eliminarán:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            SizedBox(height: 8),
            Text('• Mesas'),
            Text('• Productos'),
            Text('• Categorías'),
            Text('• Clientes'),
            Text('• Pedidos'),
            Text('• Movimientos de caja'),
            Text('• Cajeros'),
            Text('• Configuración'),
            SizedBox(height: 16),
            Text(
              'Los datos fiscales (nombre, CIF, dirección) se mantendrán.',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, borrar todo'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Reseteando sistema...'),
          ],
        ),
      ),
    );

    try {
      final db = DatabaseService();
      await db.resetAll();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sistema reseteado correctamente. Los datos fiscales se han mantenido.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al resetear: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _mostrarDialogoRestaurar() async {
    try {
      final resultado = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (resultado == null || resultado.files.single.path == null) {
        return;
      }

      final rutaArchivo = resultado.files.single.path!;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: AppColors.warning),
              SizedBox(width: 12),
              Text('Confirmar Restauración'),
            ],
          ),
          content: const Text(
            '¿Está seguro de restaurar el backup?\n\n'
            'Esta acción puede sobrescribir datos actuales.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _restaurarBackup(rutaArchivo);
              },
              child: const Text('Restaurar'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar archivo: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _restaurarBackup(String rutaArchivo) async {
    try {
      final backupService = BackupService(ref);

      final exito = await backupService.restaurarBackup(rutaArchivo);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              exito
                  ? 'Backup restaurado correctamente'
                  : 'Error al restaurar backup',
            ),
            backgroundColor: exito ? AppColors.success : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
