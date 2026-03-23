import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
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
              _buildSeccion('Datos del TPV', [
                TextFormField(
                  controller: _numeroSerieController,
                  decoration: const InputDecoration(
                    labelText: 'Número de serie del terminal',
                    prefixIcon: Icon(Icons.confirmation_number),
                    helperText: 'Identificador único del terminal TPV',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _numeroLicenciaController,
                  decoration: const InputDecoration(
                    labelText: 'Número de licencia software',
                    prefixIcon: Icon(Icons.key),
                  ),
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
              _buildSeccion('Configuración de IVA', [
                TextFormField(
                  controller: _ivaController,
                  decoration: const InputDecoration(
                    labelText: 'IVA (%)',
                    prefixIcon: Icon(Icons.percent),
                    helperText:
                        'Tipo de IVA general (10% reducido, 21% general)',
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
                    ChoiceChip(
                      label: const Text('4%'),
                      selected: _ivaController.text == '4',
                      onSelected: (s) {
                        if (s) setState(() => _ivaController.text = '4');
                      },
                    ),
                  ],
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
            borderRadius: BorderRadius.circular(16),
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
}
