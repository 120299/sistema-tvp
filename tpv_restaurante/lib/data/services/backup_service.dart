import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../../presentation/providers/providers.dart';
import 'database_service.dart';
import 'image_storage_service.dart';

import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

class BackupService {
  final DatabaseService _db;
  final WidgetRef _ref;

  BackupService(this._db, this._ref);

  Future<void> exportarBackup(BuildContext context) async {
    try {
      final path = await crearBackup();
      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [XFile(path)],
        text: 'Backup TPV Restaurante - ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
        sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      );
    } catch (e) {
      debugPrint('Error al exportar: $e');
      rethrow;
    }
  }

  Future<bool> importarYRestaurar() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        return await restaurarBackup(result.files.single.path!);
      }
      return false;
    } catch (e) {
      debugPrint('Error al importar: $e');
      return false;
    }
  }

  Future<String> crearBackup() async {
    final datos = <String, dynamic>{
      'version': '1.0',
      'fecha': DateTime.now().toIso8601String(),
      'negocio': _ref.read(negocioProvider).toJson(),
      'cajeros': _ref.read(cajerosProvider).map((c) => c.toJson()).toList(),
      'clientes': _ref.read(clientesProvider).map((c) => c.toJson()).toList(),
      'productos': _ref.read(productosProvider).map((p) => p.toJson()).toList(),
      'categorias': _ref
          .read(categoriasProvider)
          .map((c) => c.toJson())
          .toList(),
      'mesas': _ref.read(mesasProvider).map((m) => m.toJson()).toList(),
      'pedidos': _ref.read(pedidosProvider).map((p) => p.toJson()).toList(),
      'imagenes': _getImagenesBackup(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(datos);
    final directorio = await getApplicationDocumentsDirectory();
    final fecha = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final archivo = File('${directorio.path}/backup_tpv_$fecha.json');

    await archivo.writeAsString(jsonString);

    return archivo.path;
  }

  Future<BackupInfo?> leerBackup(String rutaArchivo) async {
    try {
      final archivo = File(rutaArchivo);
      if (!await archivo.exists()) {
        return null;
      }

      final contenido = await archivo.readAsString();
      final datos = json.decode(contenido) as Map<String, dynamic>;

      return BackupInfo.fromJson(datos);
    } catch (e) {
      debugPrint('Error al leer backup: $e');
      return null;
    }
  }

  Future<bool> restaurarBackup(String rutaArchivo) async {
    try {
      final archivo = File(rutaArchivo);
      if (!await archivo.exists()) {
        return false;
      }

      final contenido = await archivo.readAsString();
      final datos = json.decode(contenido) as Map<String, dynamic>;

      // Limpiar datos actuales antes de restaurar
      await _db.productosBox.clear();
      await _db.categoriasBox.clear();
      await _db.mesasBox.clear();
      await _db.negocioBox.clear();
      await _db.cajerosBox.clear();
      await _db.clientesBox.clear();
      await _db.pedidosBox.clear();

      if (datos['negocio'] != null) {
        final negocio = DatosNegocio.fromJson(datos['negocio']);
        await _db.negocioBox.add(negocio);
      }

      if (datos['cajeros'] != null) {
        final cajeros = (datos['cajeros'] as List)
            .map((c) => Cajero.fromJson(c))
            .toList();
        await _db.cajerosBox.addAll(cajeros);
      }

      if (datos['clientes'] != null) {
        final clientes = (datos['clientes'] as List)
            .map((c) => Cliente.fromJson(c))
            .toList();
        await _db.clientesBox.addAll(clientes);
      }

      if (datos['categorias'] != null) {
        final categorias = (datos['categorias'] as List)
            .map((c) => CategoriaProducto.fromJson(c))
            .toList();
        await _db.categoriasBox.addAll(categorias);
      }

      if (datos['productos'] != null) {
        final productos = (datos['productos'] as List)
            .map((p) => Producto.fromJson(p))
            .toList();
        await _db.productosBox.addAll(productos);
      }

      if (datos['mesas'] != null) {
        final mesas = (datos['mesas'] as List)
            .map((m) => Mesa.fromJson(m))
            .toList();
        await _db.mesasBox.addAll(mesas);
      }
      
      if (datos['pedidos'] != null) {
        final pedidos = (datos['pedidos'] as List)
            .map((p) => Pedido.fromJson(p))
            .toList();
        await _db.pedidosBox.addAll(pedidos);
      }

      if (datos['imagenes'] != null) {
        final imagenes = datos['imagenes'] as Map<String, dynamic>;
        for (final entry in imagenes.entries) {
          await imageStorageService.saveImageFromBase64(entry.key.replaceAll('products/', '').replaceAll('.jpg', ''), entry.value);
        }
      }

      // Notificar a los proveedores para que se actualicen
      _ref.read(productosProvider.notifier).actualizarLista();
      _ref.read(categoriasProvider.notifier).actualizarLista();
      _ref.read(mesasProvider.notifier).actualizarLista();
      _ref.read(pedidosProvider.notifier).actualizarLista();
      _ref.read(cajerosProvider.notifier).actualizarLista();
      _ref.read(clientesProvider.notifier).actualizarLista();
      _ref.invalidate(negocioProvider);
      triggerImageRefresh(_ref);

      return true;
    } catch (e) {
      debugPrint('Error al restaurar backup: $e');
      return false;
    }
  }

  Future<List<BackupInfo>> listarBackups() async {
    try {
      final directorio = await getApplicationDocumentsDirectory();
      final archivos = directorio
          .listSync()
          .where(
            (f) => f.path.contains('backup_tpv_') && f.path.endsWith('.json'),
          )
          .toList();

      final backups = <BackupInfo>[];
      for (final archivo in archivos) {
        final info = await leerBackup(archivo.path);
        if (info != null) {
          backups.add(info);
        }
      }

      backups.sort((a, b) => b.fecha.compareTo(a.fecha));
      return backups;
    } catch (e) {
      debugPrint('Error al listar backups: $e');
      return [];
    }
  }

  Future<bool> eliminarBackup(String rutaArchivo) async {
    try {
      final archivo = File(rutaArchivo);
      if (await archivo.exists()) {
        await archivo.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error al eliminar backup: $e');
      return false;
    }
  }
  Map<String, String> _getImagenesBackup() {
    final imagenes = <String, String>{};
    final productos = _ref.read(productosProvider);
    for (final p in productos) {
      if (p.imagenUrl != null && p.imagenUrl!.startsWith('products/')) {
        final b64 = imageStorageService.getBase64FromPath(p.imagenUrl!);
        if (b64.isNotEmpty) {
          imagenes[p.imagenUrl!] = b64;
        }
      }
    }
    return imagenes;
  }
}

class BackupInfo {
  final String version;
  final DateTime fecha;
  final int totalCajeros;
  final int totalClientes;
  final int totalProductos;
  final int totalPedidos;
  final String ruta;

  BackupInfo({
    required this.version,
    required this.fecha,
    required this.totalCajeros,
    required this.totalClientes,
    required this.totalProductos,
    required this.totalPedidos,
    required this.ruta,
  });

  factory BackupInfo.fromJson(Map<String, dynamic> json, {String? ruta}) {
    return BackupInfo(
      version: json['version'] ?? '1.0',
      fecha: DateTime.tryParse(json['fecha'] ?? '') ?? DateTime.now(),
      totalCajeros: (json['cajeros'] as List?)?.length ?? 0,
      totalClientes: (json['clientes'] as List?)?.length ?? 0,
      totalProductos: (json['productos'] as List?)?.length ?? 0,
      totalPedidos: (json['pedidos'] as List?)?.length ?? 0,
      ruta: ruta ?? '',
    );
  }
}
