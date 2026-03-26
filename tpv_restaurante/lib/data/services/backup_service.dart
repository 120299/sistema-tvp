import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../../presentation/providers/providers.dart';
import 'database_service.dart';

class BackupService {
  final DatabaseService _db;
  final WidgetRef _ref;

  BackupService(this._db, this._ref);

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
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(datos);
    final basePath = Directory.current.path;
    final fecha = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final backupsDir = Directory('$basePath/backups');

    if (!await backupsDir.exists()) {
      await backupsDir.create(recursive: true);
    }

    final archivo = File('${backupsDir.path}/backup_tpv_$fecha.json');

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

      if (datos['negocio'] != null) {
        final negocio = DatosNegocio.fromJson(datos['negocio']);
        await _ref.read(negocioProvider.notifier).actualizar(negocio);
      }

      if (datos['cajeros'] != null) {
        final cajeros = (datos['cajeros'] as List)
            .map((c) => Cajero.fromJson(c))
            .toList();
        for (final cajero in cajeros) {
          await _ref.read(cajerosProvider.notifier).agregar(cajero);
        }
      }

      if (datos['clientes'] != null) {
        final clientes = (datos['clientes'] as List)
            .map((c) => Cliente.fromJson(c))
            .toList();
        for (final cliente in clientes) {
          await _ref.read(clientesProvider.notifier).agregar(cliente);
        }
      }

      if (datos['categorias'] != null) {
        final categorias = (datos['categorias'] as List)
            .map((c) => CategoriaProducto.fromJson(c))
            .toList();
        for (final categoria in categorias) {
          await _ref.read(categoriasProvider.notifier).agregar(categoria);
        }
      }

      if (datos['productos'] != null) {
        final productos = (datos['productos'] as List)
            .map((p) => Producto.fromJson(p))
            .toList();
        for (final producto in productos) {
          await _ref.read(productosProvider.notifier).agregar(producto);
        }
      }

      if (datos['mesas'] != null) {
        final mesas = (datos['mesas'] as List)
            .map((m) => Mesa.fromJson(m))
            .toList();
        for (final mesa in mesas) {
          await _ref.read(mesasProvider.notifier).agregar(mesa);
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error al restaurar backup: $e');
      return false;
    }
  }

  Future<List<BackupInfo>> listarBackups() async {
    try {
      final basePath = Directory.current.path;
      final backupsDir = Directory('$basePath/backups');

      if (!await backupsDir.exists()) {
        return [];
      }

      final archivos = backupsDir
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
