import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' if (dart.library.html) 'dart:io_stub.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../providers/providers.dart';

class BackupScreen extends ConsumerStatefulWidget {
  final String tipo;

  const BackupScreen({super.key, required this.tipo});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _exportarTodo = true;
  bool _exportarNegocio = true;
  bool _exportarCajeros = true;
  bool _exportarClientes = true;
  bool _exportarProductos = true;
  bool _exportarCategorias = true;
  bool _exportarMesas = true;
  bool _exportarPedidos = true;
  bool _exportarCajas = true;

  bool _importarFusionar = true;
  bool _cargando = false;
  String? _mensaje;
  bool _esError = false;

  List<Map<String, dynamic>> _backupsDisponibles = [];

  @override
  void initState() {
    super.initState();
    if (widget.tipo == 'importar') {
      _cargarBackups();
    }
  }

  Future<void> _cargarBackups() async {
    if (kIsWeb) {
      setState(() => _backupsDisponibles = []);
      return;
    }

    try {
      final basePath = Directory.current.path;
      final backupsDir = Directory('$basePath/backups');

      if (!await backupsDir.exists()) {
        setState(() => _backupsDisponibles = []);
        return;
      }

      final archivos = await backupsDir
          .list()
          .where(
            (f) => f.path.contains('backup_tpv_') && f.path.endsWith('.json'),
          )
          .toList();

      final backups = <Map<String, dynamic>>[];
      for (final archivo in archivos) {
        try {
          final contenido = await File(archivo.path).readAsString();
          final datos = jsonDecode(contenido) as Map<String, dynamic>;
          backups.add({
            'ruta': archivo.path,
            'fecha': datos['fecha'] ?? '',
            'version': datos['version'] ?? '1.0',
            'totalCajeros': (datos['cajeros'] as List?)?.length ?? 0,
            'totalClientes': (datos['clientes'] as List?)?.length ?? 0,
            'totalProductos': (datos['productos'] as List?)?.length ?? 0,
            'totalCategorias': (datos['categorias'] as List?)?.length ?? 0,
            'totalMesas': (datos['mesas'] as List?)?.length ?? 0,
            'totalPedidos': (datos['pedidos'] as List?)?.length ?? 0,
            'totalCajas': (datos['cajas'] as List?)?.length ?? 0,
          });
        } catch (e) {
          debugPrint('Error leyendo backup: $e');
        }
      }

      backups.sort(
        (a, b) => (b['fecha'] as String).compareTo(a['fecha'] as String),
      );

      setState(() {
        _backupsDisponibles = backups;
      });
    } catch (e) {
      debugPrint('Error cargando backups: $e');
    }
  }

  Future<void> _exportar() async {
    setState(() {
      _cargando = true;
      _mensaje = null;
    });

    try {
      final datos = <String, dynamic>{
        'version': '2.0',
        'fecha': DateTime.now().toIso8601String(),
      };

      if (_exportarTodo || _exportarNegocio) {
        datos['negocio'] = ref.read(negocioProvider).toJson();
      }

      if (_exportarTodo || _exportarCajeros) {
        datos['cajeros'] = ref
            .read(cajerosProvider)
            .map((c) => c.toJson())
            .toList();
      }

      if (_exportarTodo || _exportarClientes) {
        datos['clientes'] = ref
            .read(clientesProvider)
            .map((c) => c.toJson())
            .toList();
      }

      if (_exportarTodo || _exportarProductos) {
        datos['productos'] = ref
            .read(productosProvider)
            .map((p) => p.toJson())
            .toList();
      }

      if (_exportarTodo || _exportarCategorias) {
        datos['categorias'] = ref
            .read(categoriasProvider)
            .map((c) => c.toJson())
            .toList();
      }

      if (_exportarTodo || _exportarMesas) {
        datos['mesas'] = ref
            .read(mesasProvider)
            .map((m) => m.toJson())
            .toList();
      }

      if (_exportarTodo || _exportarPedidos) {
        datos['pedidos'] = ref
            .read(pedidosProvider)
            .map((p) => p.toJson())
            .toList();
      }

      if (_exportarTodo || _exportarCajas) {
        final db = ref.read(databaseServiceProvider);
        datos['cajas'] = db.cajaRepositorio
            .getAll()
            .map((c) => c.toJson())
            .toList();
      }

      final jsonString = const JsonEncoder.withIndent('  ').convert(datos);

      if (kIsWeb) {
        await _exportarWeb(jsonString);
      } else {
        await _exportarDesktop(jsonString);
      }

      setState(() {
        _mensaje = 'Backup exportado correctamente';
        _esError = false;
      });
    } catch (e) {
      setState(() {
        _mensaje = 'Error al exportar: $e';
        _esError = true;
      });
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  }

  Future<void> _exportarDesktop(String jsonString) async {
    final basePath = Directory.current.path;
    final backupsDir = Directory('$basePath/backups');

    if (!await backupsDir.exists()) {
      await backupsDir.create(recursive: true);
    }

    final fecha = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
    final nombreArchivo = 'backup_tpv_$fecha.json';
    final archivo = File('${backupsDir.path}/$nombreArchivo');

    await archivo.writeAsString(jsonString);

    await Share.shareXFiles([
      XFile(archivo.path),
    ], text: 'Copia de seguridad TPV Restaurante');
  }

  Future<void> _exportarWeb(String jsonString) async {
    final fecha = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
    final nombreArchivo = 'backup_tpv_$fecha.json';

    await Share.share(
      jsonString,
      subject: 'Copia de seguridad TPV Restaurante - $nombreArchivo',
    );
  }

  Future<void> _importar(String rutaArchivo, {bool fusionar = true}) async {
    setState(() {
      _cargando = true;
      _mensaje = null;
    });

    try {
      String contenido;

      if (kIsWeb) {
        contenido = rutaArchivo;
      } else {
        final archivo = File(rutaArchivo);
        if (!await archivo.exists()) {
          setState(() {
            _mensaje = 'Archivo no encontrado';
            _esError = true;
          });
          return;
        }
        contenido = await archivo.readAsString();
      }

      final datos = json.decode(contenido) as Map<String, dynamic>;
      await _procesarImportacion(datos, fusionar);

      setState(() {
        _mensaje = fusionar
            ? 'Datos importados correctamente (fusionando)'
            : 'Datos importados correctamente (sobrescribiendo)';
        _esError = false;
      });
    } catch (e) {
      setState(() {
        _mensaje = 'Error al importar: $e';
        _esError = true;
      });
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  }

  Future<void> _procesarImportacion(
    Map<String, dynamic> datos,
    bool fusionar,
  ) async {
    final db = ref.read(databaseServiceProvider);

    if (fusionar) {
      if (datos['negocio'] != null) {
        final negocio = DatosNegocio.fromJson(datos['negocio']);
        await db.negocioBox.putAt(0, negocio);
        ref.read(negocioProvider.notifier).actualizar(negocio);
      }

      if (datos['cajeros'] != null) {
        for (final cajeroJson in datos['cajeros']) {
          final cajero = Cajero.fromJson(cajeroJson);
          final existe = ref
              .read(cajerosProvider)
              .any((c) => c.id == cajero.id);
          if (!existe) {
            await db.cajerosBox.add(cajero);
          }
        }
        ref.read(cajerosProvider.notifier).actualizarLista();
      }

      if (datos['clientes'] != null) {
        for (final clienteJson in datos['clientes']) {
          final cliente = Cliente.fromJson(clienteJson);
          final existe = ref
              .read(clientesProvider)
              .any((c) => c.id == cliente.id);
          if (!existe) {
            await db.clientesBox.add(cliente);
          }
        }
        ref.read(clientesProvider.notifier).actualizarLista();
      }

      if (datos['categorias'] != null) {
        for (final catJson in datos['categorias']) {
          final cat = CategoriaProducto.fromJson(catJson);
          final existe = ref
              .read(categoriasProvider)
              .any((c) => c.id == cat.id);
          if (!existe) {
            await db.categoriasBox.add(cat);
          }
        }
        ref.read(categoriasProvider.notifier).actualizarLista();
      }

      if (datos['productos'] != null) {
        for (final prodJson in datos['productos']) {
          final prod = Producto.fromJson(prodJson);
          final existe = ref
              .read(productosProvider)
              .any((p) => p.id == prod.id);
          if (!existe) {
            await db.productosBox.add(prod);
          }
        }
        ref.read(productosProvider.notifier).actualizarLista();
      }

      if (datos['mesas'] != null) {
        for (final mesaJson in datos['mesas']) {
          final mesa = Mesa.fromJson(mesaJson);
          final existe = ref.read(mesasProvider).any((m) => m.id == mesa.id);
          if (!existe) {
            await db.mesasBox.add(mesa);
          }
        }
        ref.read(mesasProvider.notifier).actualizarLista();
      }

      if (datos['pedidos'] != null) {
        for (final pedJson in datos['pedidos']) {
          final ped = Pedido.fromJson(pedJson);
          final existe = ref.read(pedidosProvider).any((p) => p.id == ped.id);
          if (!existe) {
            await db.pedidosBox.add(ped);
          }
        }
        ref.read(pedidosProvider.notifier).actualizarLista();
      }

      if (datos['cajas'] != null) {
        for (final cajaJson in datos['cajas']) {
          final caja = Caja.fromJson(cajaJson);
          final existe = db.cajaRepositorio.getAll().any(
            (c) => c.id == caja.id,
          );
          if (!existe) {
            await db.cajaBox.add(caja);
          }
        }
      }
    } else {
      await db.cajerosBox.clear();
      await db.clientesBox.clear();
      await db.categoriasBox.clear();
      await db.productosBox.clear();
      await db.mesasBox.clear();
      await db.pedidosBox.clear();
      await db.cajaBox.clear();

      if (datos['negocio'] != null) {
        final negocio = DatosNegocio.fromJson(datos['negocio']);
        await db.negocioBox.putAt(0, negocio);
      }

      if (datos['cajeros'] != null) {
        for (final cajeroJson in datos['cajeros']) {
          await db.cajerosBox.add(Cajero.fromJson(cajeroJson));
        }
      }

      if (datos['clientes'] != null) {
        for (final clienteJson in datos['clientes']) {
          await db.clientesBox.add(Cliente.fromJson(clienteJson));
        }
      }

      if (datos['categorias'] != null) {
        for (final catJson in datos['categorias']) {
          await db.categoriasBox.add(CategoriaProducto.fromJson(catJson));
        }
      }

      if (datos['productos'] != null) {
        for (final prodJson in datos['productos']) {
          await db.productosBox.add(Producto.fromJson(prodJson));
        }
      }

      if (datos['mesas'] != null) {
        for (final mesaJson in datos['mesas']) {
          await db.mesasBox.add(Mesa.fromJson(mesaJson));
        }
      }

      if (datos['pedidos'] != null) {
        for (final pedJson in datos['pedidos']) {
          await db.pedidosBox.add(Pedido.fromJson(pedJson));
        }
      }

      if (datos['cajas'] != null) {
        for (final cajaJson in datos['cajas']) {
          await db.cajaBox.add(Caja.fromJson(cajaJson));
        }
      }

      ref.read(cajerosProvider.notifier).actualizarLista();
      ref.read(clientesProvider.notifier).actualizarLista();
      ref.read(categoriasProvider.notifier).actualizarLista();
      ref.read(productosProvider.notifier).actualizarLista();
      ref.read(mesasProvider.notifier).actualizarLista();
      ref.read(pedidosProvider.notifier).actualizarLista();
    }
  }

  Future<void> _seleccionarArchivoYImportar() async {
    try {
      final resultado = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: kIsWeb,
      );

      if (resultado != null) {
        if (kIsWeb && resultado.files.single.bytes != null) {
          final contenido = String.fromCharCodes(resultado.files.single.bytes!);
          await _importar(contenido, fusionar: _importarFusionar);
        } else if (resultado.files.single.path != null) {
          await _importar(
            resultado.files.single.path!,
            fusionar: _importarFusionar,
          );
        }
      }
    } catch (e) {
      setState(() {
        _mensaje = 'Error al seleccionar archivo: $e';
        _esError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final negocio = ref.watch(negocioProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.tipo == 'exportar' ? 'Exportar Datos' : 'Importar Datos',
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: widget.tipo == 'exportar'
          ? _buildExportar()
          : _buildImportar(negocio),
    );
  }

  Widget _buildExportar() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.cloud_upload,
                        color: AppColors.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Exportar Copia de Seguridad',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selecciona qué datos quieres exportar',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Exportar TODO el sistema'),
                    subtitle: const Text('Incluye todos los datos'),
                    value: _exportarTodo,
                    onChanged: (value) {
                      setState(() => _exportarTodo = value ?? false);
                    },
                    activeColor: AppColors.primary,
                  ),
                  const Divider(),
                  if (!_exportarTodo) ...[
                    _buildModuloCheck(
                      'negocio',
                      'Datos del negocio',
                      Icons.business,
                      _exportarNegocio,
                      (v) => setState(() => _exportarNegocio = v),
                    ),
                    _buildModuloCheck(
                      'cajeros',
                      'Usuarios del sistema',
                      Icons.people,
                      _exportarCajeros,
                      (v) => setState(() => _exportarCajeros = v),
                    ),
                    _buildModuloCheck(
                      'clientes',
                      'Clientes',
                      Icons.person,
                      _exportarClientes,
                      (v) => setState(() => _exportarClientes = v),
                    ),
                    _buildModuloCheck(
                      'productos',
                      'Productos',
                      Icons.inventory_2,
                      _exportarProductos,
                      (v) => setState(() => _exportarProductos = v),
                    ),
                    _buildModuloCheck(
                      'categorias',
                      'Categorías',
                      Icons.category,
                      _exportarCategorias,
                      (v) => setState(() => _exportarCategorias = v),
                    ),
                    _buildModuloCheck(
                      'mesas',
                      'Mesas',
                      Icons.table_restaurant,
                      _exportarMesas,
                      (v) => setState(() => _exportarMesas = v),
                    ),
                    _buildModuloCheck(
                      'pedidos',
                      'Historial de pedidos',
                      Icons.receipt_long,
                      _exportarPedidos,
                      (v) => setState(() => _exportarPedidos = v),
                    ),
                    _buildModuloCheck(
                      'cajas',
                      'Cajas y movimientos',
                      Icons.account_balance_wallet,
                      _exportarCajas,
                      (v) => setState(() => _exportarCajas = v),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_mensaje != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _esError ? Colors.red.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.zero,
                border: Border.all(color: _esError ? Colors.red : Colors.green),
              ),
              child: Row(
                children: [
                  Icon(
                    _esError ? Icons.error : Icons.check_circle,
                    color: _esError ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_mensaje!)),
                ],
              ),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _cargando ? null : _exportar,
              icon: _cargando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.file_upload),
              label: Text(_cargando ? 'Exportando...' : 'Exportar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuloCheck(
    String id,
    String titulo,
    IconData icono,
    bool valor,
    ValueChanged<bool> onChanged,
  ) {
    return CheckboxListTile(
      title: Text(titulo),
      secondary: Icon(icono, color: AppColors.primary),
      value: valor,
      onChanged: (v) => onChanged(v ?? false),
      activeColor: AppColors.primary,
    );
  }

  Widget _buildImportar(DatosNegocio negocio) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.cloud_download,
                        color: AppColors.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Importar Copia de Seguridad',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Restaura datos desde un archivo JSON',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Opciones de importación:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  RadioListTile<bool>(
                    title: const Text('Fusionar datos'),
                    subtitle: const Text('Añade sin duplicar (recomendado)'),
                    value: true,
                    groupValue: _importarFusionar,
                    onChanged: (v) =>
                        setState(() => _importarFusionar = v ?? true),
                    activeColor: AppColors.primary,
                  ),
                  RadioListTile<bool>(
                    title: const Text('Sobrescribir todo'),
                    subtitle: const Text('Elimina datos existentes y restaura'),
                    value: false,
                    groupValue: _importarFusionar,
                    onChanged: (v) =>
                        setState(() => _importarFusionar = v ?? true),
                    activeColor: AppColors.primary,
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _cargando
                          ? null
                          : _seleccionarArchivoYImportar,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Seleccionar archivo JSON'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_mensaje != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _esError ? Colors.red.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.zero,
                border: Border.all(color: _esError ? Colors.red : Colors.green),
              ),
              child: Row(
                children: [
                  Icon(
                    _esError ? Icons.error : Icons.check_circle,
                    color: _esError ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_mensaje!)),
                ],
              ),
            ),
          const SizedBox(height: 24),
          Text(
            kIsWeb
                ? 'Backups disponibles (usa compartir para enviar archivo):'
                : 'Backups disponibles en este dispositivo:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          if (_backupsDisponibles.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.zero,
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      kIsWeb ? Icons.share : Icons.folder_off,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      kIsWeb
                          ? 'No hay backups en este dispositivo.\nPuedes importar un archivo JSON.'
                          : 'No hay backups guardados',
                      style: TextStyle(color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _backupsDisponibles.length,
              itemBuilder: (context, index) {
                final backup = _backupsDisponibles[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.rectangle,
                      ),
                      child: Icon(Icons.backup, color: AppColors.primary),
                    ),
                    title: Text(
                      DateFormat(
                        'dd/MM/yyyy HH:mm',
                      ).format(DateTime.parse(backup['fecha'])),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${backup['totalCajeros']} usuarios | '
                      '${backup['totalClientes']} clientes | '
                      '${backup['totalProductos']} productos | '
                      '${backup['totalPedidos']} pedidos',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.restore),
                      onPressed: _cargando
                          ? null
                          : () => _importar(
                              backup['ruta'],
                              fusionar: _importarFusionar,
                            ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
