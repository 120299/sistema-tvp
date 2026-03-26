import 'package:flutter_test/flutter_test.dart';
import 'package:tpv_restaurante/data/models/models.dart'; // adjust package name if needed
import 'dart:convert';

void main() {
  test('Producto con variantes se serializa/deserializa correctamente', () {
    final variante = VarianteProducto(
      id: 'var1',
      nombre: 'Pequeño',
      precio: 5.0,
    );
    final producto = Producto(
      id: 'prod_var_example',
      nombre: 'Producto Variable',
      precio: 5.0,
      categoriaId: 'variable',
      esVariable: true,
      variantes: [variante],
    );

    final json = producto.toJson();
    final producto2 = Producto.fromJson(json);

    expect(producto2.id, equals(producto.id));
    expect(producto2.esVariable, isTrue);
    expect(producto2.variantes?.first.nombre, equals('Pequeño'));
  });

  test(
    'Crear variante y asignarla a producto en un pedido (estructura básica)',
    () {
      final v = VarianteProducto(id: 'v1', nombre: 'Mediano', precio: 6.0);
      expect(v.nombre, 'Mediano');
      expect(v.precio, 6.0);
    },
  );
}
