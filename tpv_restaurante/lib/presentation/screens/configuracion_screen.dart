import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
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

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(2)} €';
  }
}
