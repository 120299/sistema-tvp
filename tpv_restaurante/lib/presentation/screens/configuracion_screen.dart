import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/services/backup_service.dart';
import '../providers/providers.dart';

class ConfiguracionScreen extends ConsumerStatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  ConsumerState<ConfiguracionScreen> createState() =>
      _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends ConsumerState<ConfiguracionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _sloganController;
  late TextEditingController _razonSocialController;
  late TextEditingController _direccionController;
  late TextEditingController _ciudadController;
  late TextEditingController _telefonoController;
  late TextEditingController _emailController;
  late TextEditingController _cifController;
  late TextEditingController _ivaController;
  late TextEditingController _webController;
  late TextEditingController _numeroSerieController;
  late TextEditingController _numeroLicenciaController;
  late TextEditingController _actividadController;
  bool _imprimeLogo = true;

  @override
  void initState() {
    super.initState();
    final negocio = ref.read(negocioProvider);
    _nombreController = TextEditingController(text: negocio.nombre);
    _sloganController = TextEditingController(text: negocio.slogan ?? '');
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
    _webController = TextEditingController(text: negocio.website ?? '');
    _numeroSerieController = TextEditingController(
      text: negocio.numeroSerie ?? '',
    );
    _numeroLicenciaController = TextEditingController(
      text: negocio.numeroLicencia ?? '',
    );
    _actividadController = TextEditingController(text: negocio.actividad ?? '');
    _imprimeLogo = negocio.imprimeLogo;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _sloganController.dispose();
    _razonSocialController.dispose();
    _direccionController.dispose();
    _ciudadController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _cifController.dispose();
    _ivaController.dispose();
    _webController.dispose();
    _numeroSerieController.dispose();
    _numeroLicenciaController.dispose();
    _actividadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

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
              _buildSeccion('Dirección Fiscal', [
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
                    labelText: 'Ciudad y Código Postal',
                    prefixIcon: Icon(Icons.map),
                    hintText: 'Ej: 28001 Madrid',
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              // Datos del TPV eliminado
              const SizedBox(height: 24),
              _buildSeccion('Datos del Negocio', [
                TextFormField(
                  controller: _sloganController,
                  decoration: const InputDecoration(
                    labelText: 'Slogan (opcional)',
                    prefixIcon: Icon(Icons.format_quote),
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
                TextFormField(
                  controller: _webController,
                  decoration: const InputDecoration(
                    labelText: 'Website',
                    prefixIcon: Icon(Icons.language),
                  ),
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
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('4%'),
                      selected: _ivaController.text == '4',
                      onSelected: (s) {
                        if (s) setState(() => _ivaController.text = '4');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('10%'),
                      selected: _ivaController.text == '10',
                      onSelected: (s) {
                        if (s) setState(() => _ivaController.text = '10');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('21%'),
                      selected: _ivaController.text == '21',
                      onSelected: (s) {
                        if (s) setState(() => _ivaController.text = '21');
                      },
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 24),
              // Almacenamiento eliminado
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
              ]),
              const SizedBox(height: 24),
              _buildSeccion('Apariencia', [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    themeMode == ThemeMode.dark
                        ? Icons.dark_mode
                        : Icons.light_mode,
                    color: AppColors.primary,
                  ),
                  title: const Text('Tema de la aplicación'),
                  subtitle: Text(_getThemeText(themeMode)),
                  trailing: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.settings_suggest),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode),
                      ),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (selection) {
                      ref.read(themeModeProvider.notifier).state =
                          selection.first;
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              _buildSeccion('Información Legal', [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
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
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
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

  Widget _buildUbicacionTile(
    String title,
    String subtitle,
    IconData icon,
    UbicacionAlmacenamiento value,
  ) {
    final currentValue = ref.watch(ubicacionAlmacenamientoProvider);
    final isSelected = currentValue == value;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : null,
        ),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : const Icon(Icons.circle_outlined, color: Colors.grey),
      onTap: () {
        ref.read(ubicacionAlmacenamientoProvider.notifier).state = value;
      },
    );
  }

  void _cambiarUbicacion() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.folder_open, color: AppColors.primary),
            SizedBox(width: 12),
            Text('Cambiar ubicación'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Selecciona la nueva ubicación para los datos:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.phone_android),
              title: const Text('Documentos/TPV_Datos'),
              subtitle: const Text('Ubicación predeterminada'),
              trailing: Radio<UbicacionAlmacenamiento>(
                value: UbicacionAlmacenamiento.local,
                groupValue: ref.read(ubicacionAlmacenamientoProvider),
                onChanged: (v) {
                  ref.read(ubicacionAlmacenamientoProvider.notifier).state = v!;
                  Navigator.pop(ctx);
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.usb),
              title: const Text('USB/TPV_Datos'),
              subtitle: const Text('Dispositivo USB o SD'),
              trailing: Radio<UbicacionAlmacenamiento>(
                value: UbicacionAlmacenamiento.usb,
                groupValue: ref.read(ubicacionAlmacenamientoProvider),
                onChanged: (v) {
                  ref.read(ubicacionAlmacenamientoProvider.notifier).state = v!;
                  Navigator.pop(ctx);
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.folder_special),
              title: const Text('Personalizado'),
              subtitle: const Text('Seleccionar carpeta'),
              trailing: Radio<UbicacionAlmacenamiento>(
                value: UbicacionAlmacenamiento.personalizado,
                groupValue: ref.read(ubicacionAlmacenamientoProvider),
                onChanged: (v) async {
                  ref.read(ubicacionAlmacenamientoProvider.notifier).state = v!;
                  Navigator.pop(ctx);
                  _mostrarDialogoRutaPersonalizada();
                },
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'El cambio de ubicación se aplicará al reiniciar la app',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoRutaPersonalizada() {
    final controller = TextEditingController(
      text: ref.read(rutaPersonalizadaProvider) ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.folder_special, color: AppColors.primary),
            SizedBox(width: 12),
            Text('Ruta personalizada'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Introduce la ruta de la carpeta:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Ruta',
                hintText: 'Ej: C:\\DatosTPV o /home/user/tpv',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.folder),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(rutaPersonalizadaProvider.notifier).state = controller
                  .text
                  .trim();
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  String _getThemeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Oscuro';
      case ThemeMode.system:
        return 'Sistema';
    }
  }

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      final negocio = DatosNegocio(
        nombre: _nombreController.text.trim(),
        slogan: _sloganController.text.isEmpty
            ? null
            : _sloganController.text.trim(),
        razonSocial: _razonSocialController.text.isEmpty
            ? null
            : _razonSocialController.text.trim(),
        direccion: _direccionController.text.trim(),
        ciudad: _ciudadController.text.trim(),
        telefono: _telefonoController.text.trim(),
        email: _emailController.text.isEmpty
            ? null
            : _emailController.text.trim(),
        cifNif: _cifController.text.isEmpty ? null : _cifController.text.trim(),
        website: _webController.text.isEmpty
            ? null
            : _webController.text.trim(),
        ivaPorcentaje: double.tryParse(_ivaController.text) ?? 10.0,
        imprimeLogo: _imprimeLogo,
        numeroSerie: _numeroSerieController.text.isEmpty
            ? null
            : _numeroSerieController.text.trim(),
        numeroLicencia: _numeroLicenciaController.text.isEmpty
            ? null
            : _numeroLicenciaController.text.trim(),
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
    }
  }

  void _crearBackup() async {
    try {
      final db = ref.read(databaseServiceProvider);
      final backupService = BackupService(db, ref);

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
      final db = ref.read(databaseServiceProvider);
      final backupService = BackupService(db, ref);

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
