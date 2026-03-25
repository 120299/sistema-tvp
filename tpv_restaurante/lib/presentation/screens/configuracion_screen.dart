import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/backup_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/services/database_service.dart';
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
              _buildSeccion('Opciones de Sistema', [
                ListTile(
                  leading: const Icon(Icons.share, color: AppColors.primary),
                  title: const Text('Exportar Datos'),
                  subtitle: const Text('Crea y comparte un archivo con todos los datos.'),
                  onTap: _exportarDatos,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.file_upload, color: AppColors.secondary),
                  title: const Text('Importar Datos'),
                  subtitle: const Text('Restaura los datos desde un archivo .json.'),
                  onTap: _importarDatos,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: AppColors.error),
                  title: const Text(
                    'Limpiar Sistema',
                    style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Borra todos los datos y restablece los valores iniciales.'),
                  onTap: _limpiarSistema,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
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



  Future<void> _exportarDatos() async {
    try {
      final db = ref.read(databaseServiceProvider);
      final backupService = BackupService(db, ref);
      await backupService.exportarBackup(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _importarDatos() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Importar datos?'),
        content: const Text(
          'Esta acción reemplazará todos los datos actuales con los del archivo seleccionado. '
          'Se recomienda hacer una exportación previa.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
            child: const Text('Seleccionar Archivo'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final db = ref.read(databaseServiceProvider);
      final backupService = BackupService(db, ref);
      final exito = await backupService.importarYRestaurar();
      
      if (mounted) {
        if (exito) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Datos importados correctamente'), backgroundColor: AppColors.success),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al importar los datos'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  void _limpiarSistema() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Limpiar todo el sistema?'),
        content: const Text(
          'Esta acción eliminará todos los pedidos, productos, clientes y configuraciones. '
          'El sistema se reiniciará con los datos de ejemplo predeterminados.\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final db = ref.read(databaseServiceProvider);
              await db.resetSystem();
              
              // Recargar todos los proveedores
              ref.read(productosProvider.notifier).actualizarLista();
              ref.read(categoriasProvider.notifier).actualizarLista();
              ref.read(mesasProvider.notifier).actualizarLista();
              ref.read(pedidosProvider.notifier).actualizarLista();
              ref.read(cajerosProvider.notifier).actualizarLista();
              ref.read(clientesProvider.notifier).actualizarLista();
              ref.invalidate(negocioProvider);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sistema restablecido correctamente'),
                    backgroundColor: AppColors.success,
                  ),
                );
                Navigator.pop(context); // Salir de configuración
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Limpiar y Reiniciar'),
          ),
        ],
      ),
    );
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


}
