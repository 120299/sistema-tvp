import 'package:flutter_test/flutter_test.dart';
import 'package:tpv_restaurante/data/models/models.dart';
import 'package:tpv_restaurante/data/utils/pedido_utils.dart';

void main() {
  test('buildPedidoItemFromProducto sin variante', () {
    final p = Producto(
      id: 'p1',
      nombre: 'Torta',
      precio: 3.0,
      categoriaId: 'postres',
    );
    final item = buildPedidoItemFromProducto(producto: p, cantidad: 2);
    expect(item.productoNombre, 'Torta');
    expect(item.precioUnitario, 3.0);
    expect(item.cantidad, 2);
  });

  test('buildPedidoItemFromProducto con variante', () {
    final p = Producto(
      id: 'p1',
      nombre: 'Galleta',
      precio: 2.0,
      categoriaId: 'postres',
    );
    final v = VarianteProducto(id: 'v1', nombre: 'Grande', precio: 3.5);
    final item = buildPedidoItemFromProducto(
      producto: p,
      cantidad: 1,
      variante: v,
    );
    expect(item.productoNombre, 'Galleta - Grande');
    expect(item.precioUnitario, 3.5);
  });
}
