import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../adapters/hive_adapters.dart';
import 'image_storage_service.dart';

class MigrationService {
  static const _uuid = Uuid();

  static Future<String> migrateFromOldData(
    String oldDataPath,
    String targetPath,
  ) async {
    final StringBuffer log = StringBuffer();

    try {
      log.writeln('=== Iniciando migración de datos ===');
      log.writeln('Origen: $oldDataPath');
      log.writeln('Destino: $targetPath');

      await Hive.initFlutter();
      _registerAdapters();

      final oldCategoriasBox = await Hive.openBox(
        'categorias',
        path: oldDataPath,
      );
      final oldProductosBox = await Hive.openBox(
        'productos',
        path: oldDataPath,
      );
      final oldImagesBox = await Hive.openBox(
        'product_images',
        path: oldDataPath,
      );

      log.writeln('Cajas abiertas correctamente');
      log.writeln('Categorías encontradas: ${oldCategoriasBox.length}');
      log.writeln('Productos encontrados: ${oldProductosBox.length}');
      log.writeln('Imágenes encontradas: ${oldImagesBox.length}');

      final targetDir = Directory(targetPath);
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final newCategoriasBox = await Hive.openBox<CategoriaProducto>(
        'categorias',
        path: targetPath,
      );
      final newProductosBox = await Hive.openBox<Producto>(
        'productos',
        path: targetPath,
      );

      final categoryMapping = <String, String>{};

      for (var i = 0; i < oldCategoriasBox.length; i++) {
        final oldCat = oldCategoriasBox.getAt(i);
        if (oldCat != null) {
          final oldCatMap = Map<String, dynamic>.from(oldCat);
          final oldId = oldCatMap['id'] ?? oldCatMap['nombre'] ?? '';
          final newId = 'cat_${_uuid.v4()}';
          categoryMapping[oldId.toString()] = newId;

          final newCat = CategoriaProducto(
            id: newId,
            nombre: oldCatMap['nombre']?.toString() ?? '',
            icono: oldCatMap['icono']?.toString() ?? '',
            color: _parseColor(oldCatMap['color']),
            orden: oldCatMap['orden'] ?? i,
          );

          await newCategoriasBox.add(newCat);
          log.writeln('  Categoría migrada: ${newCat.nombre}');
        }
      }

      int productosMigrados = 0;

      for (var i = 0; i < oldProductosBox.length; i++) {
        final oldProd = oldProductosBox.getAt(i);
        if (oldProd != null) {
          final oldProdMap = Map<String, dynamic>.from(oldProd);
          final oldCategoria = oldProdMap['categoria']?.toString() ?? '';
          final newCategoriaId = categoryMapping[oldCategoria] ?? '';

          List<VarianteProducto>? variantes;
          if (oldProdMap['variantes'] != null) {
            variantes = (oldProdMap['variantes'] as List).map((v) {
              final vMap = Map<String, dynamic>.from(v);
              return VarianteProducto(
                id: vMap['id'] ?? 'var_${_uuid.v4()}',
                nombre: vMap['nombre']?.toString() ?? '',
                precio: (vMap['precio'] ?? 0).toDouble(),
              );
            }).toList();
          }

          final newProd = Producto(
            id: 'prod_${_uuid.v4()}',
            nombre: oldProdMap['nombre']?.toString() ?? '',
            precio: (oldProdMap['precio'] ?? 0).toDouble(),
            categoriaId: newCategoriaId,
            disponible: oldProdMap['disponible'] ?? true,
            descripcion: oldProdMap['descripcion']?.toString(),
            precioCompra: oldProdMap['precioCompra']?.toDouble(),
            esAlergenico: oldProdMap['esAlergenico'] ?? false,
            codigoBarras: oldProdMap['codigoBarras']?.toString(),
            esVariable: oldProdMap['esVariable'] ?? false,
            variantes: variantes,
            stockActual: oldProdMap['stockActual'] as int?,
            stockMinimo: oldProdMap['stockMinimo'] as int?,
            controlStock: oldProdMap['controlStock'] ?? false,
          );

          await newProductosBox.add(newProd);
          productosMigrados++;

          if (productosMigrados <= 10) {
            log.writeln('  Producto migrado: ${newProd.nombre}');
          }
        }
      }

      log.writeln('Productos migrados: $productosMigrados');

      if (oldImagesBox.isNotEmpty) {
        log.writeln('Imágenes encontradas: ${oldImagesBox.length}');
        log.writeln(
          'Nota: Las imágenes se migrarán automáticamente al iniciar la app',
        );

        for (var i = 0; i < oldImagesBox.length; i++) {
          final key = oldImagesBox.keyAt(i);
          final value = oldImagesBox.getAt(i);
          if (key != null && value != null) {
            final keyStr = key.toString();
            if (value is Uint8List) {
              await imageStorageService.saveImage(keyStr, value);
            } else if (value is List<int>) {
              await imageStorageService.saveImage(
                keyStr,
                Uint8List.fromList(value),
              );
            }
          }
        }
      }

      log.writeln('=== Migración completada ===');

      await Hive.close();

      return log.toString();
    } catch (e, st) {
      log.writeln('ERROR durante migración: $e');
      log.writeln('Stack trace: $st');
      await Hive.close();
      rethrow;
    }
  }

  static void _registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CategoriaProductoAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ProductoAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(MesaAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(PedidoItemAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(PedidoAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(DatosNegocioAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(MovimientoCajaAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(CajaAdapter());
    }
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(CajeroAdapter());
    }
    if (!Hive.isAdapterRegistered(9)) {
      Hive.registerAdapter(ClienteAdapter());
    }
  }

  static Color _parseColor(dynamic colorValue) {
    if (colorValue == null) return const Color(0xFF6200EE);
    if (colorValue is int) return Color(colorValue);
    if (colorValue is String) {
      try {
        if (colorValue.startsWith('#')) {
          final hex = colorValue.replaceFirst('#', '');
          return Color(int.parse('FF$hex', radix: 16));
        }
        return Color(int.parse(colorValue));
      } catch (_) {
        return const Color(0xFF6200EE);
      }
    }
    return const Color(0xFF6200EE);
  }
}
