import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/services/database_service.dart';
import '../../data/services/producto_import_service.dart';
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
              const SizedBox(height: 24),
              _buildSeccion('Gestión de Productos', [
                const Text(
                  'Importa o exporta productos desde un archivo JSON.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  'El archivo debe tener formato JSON con la estructura: {"categorias": [...], "productos": [...]}',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _importarProductos,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Importar'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _exportarProductos,
                        icon: const Icon(Icons.download),
                        label: const Text('Exportar'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _descargarPlantilla,
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('Descargar plantilla de ejemplo'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
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

  Future<void> _importarProductos() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Seleccionar archivo de productos',
      );

      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        final content = await _leerArchivo(file.path!);

        if (content.isEmpty) {
          _mostrarMensajeError('El archivo está vacío');
          return;
        }

        final db = ref.read(databaseServiceProvider);
        final importResult = await ProductoImportService.importarDesdeJson(
          content,
          db,
        );

        if (!mounted) return;

        final confirmar = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirmar Importación'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Se importarán los siguientes elementos:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildResumenImportacion(
                    icon: Icons.folder,
                    titulo: 'Categorías',
                    cantidad: importResult.categoriasImportadas,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 8),
                  _buildResumenImportacion(
                    icon: Icons.shopping_bag,
                    titulo: 'Productos',
                    cantidad: importResult.productosImportados,
                    color: Colors.green,
                  ),
                  if (importResult.errores > 0) ...[
                    const SizedBox(height: 8),
                    _buildResumenImportacion(
                      icon: Icons.warning,
                      titulo: 'Errores',
                      cantidad: importResult.errores,
                      color: Colors.red,
                    ),
                  ],
                  if (importResult.mensajesError.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Detalles de errores:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      constraints: const BoxConstraints(maxHeight: 100),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: importResult.mensajesError
                              .take(5)
                              .map(
                                (e) => Text(
                                  '- $e',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Confirmar'),
              ),
            ],
          ),
        );

        if (confirmar == true) {
          if (importResult.categoriasImportadas > 0 ||
              importResult.productosImportados > 0) {
            ref.invalidate(productosProvider);
            ref.invalidate(categoriasProvider);
          }
          _mostrarMensaje(
            'Importación completada:\n'
            '- Categorías: ${importResult.categoriasImportadas}\n'
            '- Productos: ${importResult.productosImportados}\n'
            '- Errores: ${importResult.errores}',
          );
        }
      }
    } catch (e) {
      _mostrarMensajeError('Error al importar: $e');
    }
  }

  Widget _buildResumenImportacion({
    required IconData icon,
    required String titulo,
    required int cantidad,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(titulo),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color),
          ),
          child: Text(
            cantidad.toString(),
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }

  Future<void> _exportarProductos() async {
    try {
      final productos = ref.read(productosProvider);
      final categorias = ref.read(categoriasProvider);

      final jsonContent = await ProductoImportService.exportarProductosJson(
        productos,
        categorias,
      );

      if (jsonContent == null) {
        _mostrarMensajeError('Error al generar el archivo');
        return;
      }

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar productos',
        fileName: 'productos_exportacion.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        await File(result).writeAsString(jsonContent);
        _mostrarMensaje('Productos exportados a:\n$result');
      }
    } catch (e) {
      _mostrarMensajeError('Error al exportar: $e');
    }
  }

  Future<void> _descargarPlantilla() async {
    const plantilla = '''
{
  "version": "1.0",
  "descripcion": "Plantilla de importacion de productos para TPV",
  "categorias": [
    {
      "nombre": "Bebidas",
      "icono": "🥤",
      "color": "#2196F3"
    },
    {
      "nombre": "Comidas",
      "icono": "🍽️",
      "color": "#4CAF50"
    },
    {
      "nombre": "Postres",
      "icono": "🍰",
      "color": "#E91E63"
    }
  ],
  "productos": [
    {
      "nombre": "Cafe",
      "precio": 1.50,
      "categoriaId": "Bebidas",
      "descripcion": "Cafe solo",
      "disponible": true,
      "esAlergenico": false
    },
    {
      "nombre": "Refresco de Cola",
      "precio": 2.00,
      "categoriaId": "Bebidas",
      "descripcion": "Refresco de cola 33cl",
      "disponible": true,
      "codigoBarras": "1234567890123"
    },
    {
      "nombre": "Cerveza",
      "precio": 3.00,
      "categoriaId": "Bebidas",
      "descripcion": "Cerveza nacional",
      "disponible": true,
      "esVariable": true,
      "variantes": [
        {"nombre": "Caña", "precio": 0, "disponible": true},
        {"nombre": "Jarra", "precio": 2.00, "disponible": true},
        {"nombre": "Botella", "precio": 1.00, "disponible": true}
      ]
    },
    {
      "nombre": "Camiseta",
      "precio": 15.00,
      "categoriaId": "Comidas",
      "descripcion": "Camiseta de marca",
      "disponible": true,
      "esVariable": true,
      "variantes": [
        {"nombre": "S", "precio": 0, "disponible": true},
        {"nombre": "M", "precio": 0, "disponible": true},
        {"nombre": "L", "precio": 0, "disponible": true},
        {"nombre": "XL", "precio": 1.00, "disponible": true}
      ]
    },
    {
      "nombre": "Paella",
      "precio": 12.00,
      "categoriaId": "Comidas",
      "descripcion": "Paella Valenciana",
      "disponible": true,
      "esAlergenico": true
    },
    {
      "nombre": "Tarta de Queso",
      "precio": 4.50,
      "categoriaId": "Postres",
      "descripcion": "Tarta de queso casera",
      "disponible": true,
      "imagenUrl": ""
    }
  ]
}
''';

    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar plantilla',
        fileName: 'plantilla_productos.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        await File(result).writeAsString(plantilla);
        _mostrarMensaje('Plantilla guardada en:\n$result');
      }
    } catch (e) {
      _mostrarMensajeError('Error al guardar plantilla: $e');
    }
  }

  Future<String> _leerArchivo(String path) async {
    final file = File(path);
    return await file.readAsString();
  }

  void _mostrarMensaje(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _mostrarMensajeError(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _guardar() async {
    if (_formKey.currentState!.validate()) {
      try {
        final negocioActual = ref.read(negocioProvider);

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
          configuracionCompletada: negocioActual.configuracionCompletada,
        );

        await ref.read(negocioProvider.notifier).actualizar(negocio);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Configuración guardada correctamente'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar configuración: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(2)} €';
  }
}
