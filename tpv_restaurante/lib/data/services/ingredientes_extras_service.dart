import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class IngredientesExtrasService {
  static const String _ingredientesBox = 'ingredientes_globales';
  static const String _extrasBox = 'extras_globales';

  late Box<IngredienteProducto> _ingredientesBoxInstance;
  late Box<ExtraProducto> _extrasBoxInstance;

  Future<void> init() async {
    _ingredientesBoxInstance = await Hive.openBox<IngredienteProducto>(
      _ingredientesBox,
    );
    _extrasBoxInstance = await Hive.openBox<ExtraProducto>(_extrasBox);
  }

  List<IngredienteProducto> getIngredientes() {
    return _ingredientesBoxInstance.values.toList();
  }

  List<ExtraProducto> getExtras() {
    return _extrasBoxInstance.values.toList();
  }

  IngredienteProducto? getIngrediente(String id) {
    return _ingredientesBoxInstance.get(id);
  }

  ExtraProducto? getExtra(String id) {
    return _extrasBoxInstance.get(id);
  }

  Future<void> agregarIngrediente(IngredienteProducto ingrediente) async {
    await _ingredientesBoxInstance.put(ingrediente.id, ingrediente);
  }

  Future<void> agregarExtra(ExtraProducto extra) async {
    await _extrasBoxInstance.put(extra.id, extra);
  }

  Future<void> actualizarIngrediente(IngredienteProducto ingrediente) async {
    await _ingredientesBoxInstance.put(ingrediente.id, ingrediente);
  }

  Future<void> actualizarExtra(ExtraProducto extra) async {
    await _extrasBoxInstance.put(extra.id, extra);
  }

  Future<void> eliminarIngrediente(String id) async {
    await _ingredientesBoxInstance.delete(id);
  }

  Future<void> eliminarExtra(String id) async {
    await _extrasBoxInstance.delete(id);
  }

  bool existeIngredienteNombre(String nombre) {
    return _ingredientesBoxInstance.values.any(
      (i) => i.nombre.toLowerCase() == nombre.toLowerCase(),
    );
  }

  bool existeExtraNombre(String nombre) {
    return _extrasBoxInstance.values.any(
      (e) => e.nombre.toLowerCase() == nombre.toLowerCase(),
    );
  }

  String generarId() => const Uuid().v4();
}

final ingredientesExtrasServiceProvider = Provider<IngredientesExtrasService>((
  ref,
) {
  return IngredientesExtrasService();
});
