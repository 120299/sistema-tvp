import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../providers/providers.dart';
import '../../data/services/database_service.dart';
import '../../data/services/producto_import_service.dart';

class ProductoImportDialog extends ConsumerStatefulWidget {
  const ProductoImportDialog({super.key});

  @override
  ConsumerState<ProductoImportDialog> createState() =>
      _ProductoImportDialogState();
}

class _ProductoImportDialogState extends ConsumerState<ProductoImportDialog> {
  bool _cargando = false;
  String? _mensaje;
  bool _esError = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: const Icon(
                    Icons.upload_file,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Importar Productos',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Desde archivo JSON',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_mensaje != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _esError
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.success.withValues(alpha: 0.1),
                  border: Border.all(
                    color: _esError ? AppColors.error : AppColors.success,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _esError ? Icons.error : Icons.check_circle,
                      color: _esError ? AppColors.error : AppColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _mensaje!,
                        style: TextStyle(
                          color: _esError ? AppColors.error : AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border.all(color: Colors.blue.shade200),
                borderRadius: BorderRadius.zero,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Formato esperado',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Archivo JSON con productos y categorías\n'
                    '• Los productos pueden incluir variantes\n'
                    '• Se generarán nuevos IDs automáticamente\n'
                    '• Categorías y productos se importarán juntos',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _cargando ? null : _exportarPlantilla,
                    icon: const Icon(Icons.download),
                    label: const Text('Descargar Plantilla'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _cargando ? null : _importarArchivo,
                    icon: _cargando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.upload),
                    label: Text(
                      _cargando ? 'Importando...' : 'Importar Archivo',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!_cargando)
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _cargando ? null : _exportarProductosActuales,
                  child: const Text('Exportar productos actuales como JSON'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _importarArchivo() async {
    setState(() {
      _cargando = true;
      _mensaje = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _cargando = false;
        });
        return;
      }

      final file = result.files.first;
      String jsonContent;

      if (file.bytes != null) {
        jsonContent = String.fromCharCodes(file.bytes!);
      } else if (file.path != null) {
        jsonContent = await File(file.path!).readAsString();
      } else {
        throw Exception('No se pudo leer el archivo');
      }

      final db = DatabaseService();
      final resultado = await ProductoImportService.importarDesdeJson(
        jsonContent,
        db,
      );

      if (mounted) {
        if (resultado.productosImportados > 0 ||
            resultado.categoriasImportadas > 0) {
          ref.read(productosProvider.notifier).actualizarLista();
          ref.read(categoriasProvider.notifier).actualizarLista();

          setState(() {
            _mensaje =
                '✓ Importación exitosa: '
                '${resultado.categoriasImportadas} categorías y '
                '${resultado.productosImportados} productos';
            _esError = false;
            _cargando = false;
          });
        } else {
          setState(() {
            _mensaje = resultado.mensajesError.isNotEmpty
                ? resultado.mensajesError.first
                : 'No se encontraron productos para importar';
            _esError = true;
            _cargando = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _mensaje = 'Error: $e';
        _esError = true;
        _cargando = false;
      });
    }
  }

  Future<void> _exportarPlantilla() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/productos_ejemplo.json',
      );

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/productos_plantilla_$timestamp.json';
      final file = File(filePath);
      await file.writeAsString(jsonString);

      await Share.shareXFiles([
        XFile(filePath),
      ], subject: 'Plantilla de Productos TPV');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar plantilla: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _exportarProductosActuales() async {
    setState(() {
      _cargando = true;
    });

    try {
      final productos = ref.read(productosProvider);
      final categorias = ref.read(categoriasProvider);

      final jsonString = await ProductoImportService.exportarProductosJson(
        productos,
        categorias,
      );

      if (jsonString == null) {
        throw Exception('Error al generar JSON');
      }

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/productos_export_$timestamp.json';
      final file = File(filePath);
      await file.writeAsString(jsonString);

      await Share.shareXFiles([
        XFile(filePath),
      ], subject: 'Exportación de Productos TPV');

      setState(() {
        _mensaje = '✓ Productos exportados correctamente';
        _esError = false;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _mensaje = 'Error al exportar: $e';
        _esError = true;
        _cargando = false;
      });
    }
  }
}
