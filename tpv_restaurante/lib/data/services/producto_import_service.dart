import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import 'database_service.dart';

class ProductoImportResult {
  final int categoriasImportadas;
  final int productosImportados;
  final int errores;
  final List<String> mensajesError;

  const ProductoImportResult({
    required this.categoriasImportadas,
    required this.productosImportados,
    required this.errores,
    required this.mensajesError,
  });
}

class ProductoImportService {
  static const _uuid = Uuid();

  static Future<ProductoImportResult> importarDesdeJson(
    String jsonContent,
    DatabaseService db,
  ) async {
    int categoriasImportadas = 0;
    int productosImportados = 0;
    int errores = 0;
    final List<String> mensajesError = [];

    try {
      final Map<String, dynamic> data = json.decode(jsonContent);

      final List<dynamic>? categoriasJson = data['categorias'];
      final List<dynamic>? productosJson = data['productos'];

      if (categoriasJson == null && productosJson == null) {
        return const ProductoImportResult(
          categoriasImportadas: 0,
          productosImportados: 0,
          errores: 1,
          mensajesError: [
            'El archivo JSON no contiene categorías ni productos',
          ],
        );
      }

      final Map<String, String> mapeoCategorias = {};

      if (categoriasJson != null && categoriasJson.isNotEmpty) {
        for (final catJson in categoriasJson) {
          try {
            final String nombreCat = catJson['nombre']?.toString() ?? '';
            if (nombreCat.isEmpty) continue;

            final String idGenerado = 'cat_${_uuid.v4().substring(0, 8)}';
            final String icono = catJson['icono']?.toString() ?? '📦';
            final String colorHex = catJson['color']?.toString() ?? '#795548';
            final Color color = _parseColor(colorHex);

            final categoria = CategoriaProducto(
              id: idGenerado,
              nombre: nombreCat,
              icono: icono,
              color: color,
            );

            await db.categoriaRepositorio.add(categoria);
            mapeoCategorias[nombreCat.toLowerCase()] = idGenerado;
            categoriasImportadas++;
          } catch (e) {
            errores++;
            mensajesError.add('Error al importar categoría: $e');
          }
        }
      }

      if (productosJson != null && productosJson.isNotEmpty) {
        for (final prodJson in productosJson) {
          try {
            final String nombre = prodJson['nombre']?.toString() ?? '';
            if (nombre.isEmpty) continue;

            final dynamic precio = prodJson['precio'];
            if (precio == null) {
              errores++;
              mensajesError.add('Producto "$nombre" sin precio, omitido');
              continue;
            }

            String categoriaId = prodJson['categoriaId']?.toString() ?? '';

            if (categoriaId.isNotEmpty && !categoriaId.startsWith('cat_')) {
              final idMapeado = mapeoCategorias[categoriaId.toLowerCase()];
              if (idMapeado != null) {
                categoriaId = idMapeado;
              }
            }

            final bool disponible = prodJson['disponible'] as bool? ?? true;
            final bool esAlergenico =
                prodJson['esAlergenico'] as bool? ?? false;

            final producto = Producto(
              id: 'prod_${_uuid.v4().substring(0, 12)}',
              nombre: nombre,
              precio: (precio as num).toDouble(),
              categoriaId: categoriaId,
              descripcion: prodJson['descripcion']?.toString(),
              disponible: disponible,
              esAlergenico: esAlergenico,
              imagenUrl: prodJson['imagenUrl']?.toString(),
              codigoBarras: prodJson['codigoBarras']?.toString(),
            );

            await db.productoRepositorio.add(producto);
            productosImportados++;
          } catch (e) {
            errores++;
            mensajesError.add('Error al importar producto: $e');
          }
        }
      }

      return ProductoImportResult(
        categoriasImportadas: categoriasImportadas,
        productosImportados: productosImportados,
        errores: errores,
        mensajesError: mensajesError,
      );
    } catch (e) {
      return ProductoImportResult(
        categoriasImportadas: 0,
        productosImportados: 0,
        errores: 1,
        mensajesError: ['Error al parsear JSON: $e'],
      );
    }
  }

  static Future<String?> exportarProductosJson(
    List<Producto> productos,
    List<CategoriaProducto> categorias,
  ) async {
    try {
      final Map<String, String> mapeoCategorias = {};
      for (final cat in categorias) {
        mapeoCategorias[cat.id] = cat.nombre;
      }

      final List<Map<String, dynamic>> catsJson = categorias.map((cat) {
        String colorHex = '#';
        colorHex += cat.color.value
            .toRadixString(16)
            .padLeft(8, '0')
            .substring(2);
        return {'nombre': cat.nombre, 'icono': cat.icono, 'color': colorHex};
      }).toList();

      final List<Map<String, dynamic>> prodsJson = productos.map((prod) {
        return {
          'nombre': prod.nombre,
          'precio': prod.precio,
          'categoriaId': mapeoCategorias[prod.categoriaId] ?? prod.categoriaId,
          'descripcion': prod.descripcion,
          'disponible': prod.disponible,
          'esAlergenico': prod.esAlergenico,
          'imagenUrl': prod.imagenUrl,
          'codigoBarras': prod.codigoBarras,
          'esVariable': prod.esVariable,
        };
      }).toList();

      final Map<String, dynamic> data = {
        'version': '1.0',
        'fechaExportacion': DateTime.now().toIso8601String(),
        'descripcion': 'Exportación de productos desde TPV',
        'categorias': catsJson,
        'productos': prodsJson,
      };

      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (e) {
      debugPrint('Error al exportar productos: $e');
      return null;
    }
  }

  static Color _parseColor(String colorHex) {
    try {
      String hex = colorHex.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return const Color(0xFF795548);
  }
}
