import 'package:tpv_restaurante/data/models/models.dart';

// Builds a PedidoItem from a Producto and an optional VarianteProducto
PedidoItem buildPedidoItemFromProducto({
  required Producto producto,
  required int cantidad,
  VarianteProducto? variante,
}) {
  final nombre = variante != null
      ? '${producto.nombre} - ${variante.nombre}'
      : producto.nombre;
  final precio = variante?.precio ?? producto.precio;
  return PedidoItem(
    id: 'item_${DateTime.now().millisecondsSinceEpoch}',
    productoId: producto.id,
    productoNombre: nombre,
    cantidad: cantidad,
    precioUnitario: precio,
  );
}
