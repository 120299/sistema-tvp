import 'package:hive/hive.dart';
import '../models/models.dart';

class Repositorio<T> {
  final Box<T> _box;

  Repositorio(this._box);

  List<T> getAll() => _box.values.toList();

  T? get(String id) {
    try {
      return _box.values.firstWhere((item) {
        if (item is Producto) return item.id == id;
        if (item is CategoriaProducto) return item.id == id;
        if (item is Mesa) return item.id == id;
        if (item is Pedido) return item.id == id;
        if (item is DatosNegocio) return true;
        return false;
      });
    } catch (_) {
      return null;
    }
  }

  Future<void> add(T item) async {
    await _box.add(item);
  }

  Future<void> update(T item) async {
    final index = _box.values.toList().indexOf(item);
    if (index >= 0) {
      await _box.putAt(index, item);
    }
  }

  Future<void> delete(dynamic id) async {
    final index = _box.values.toList().indexWhere((item) {
      if (item is Producto) return item.id == id;
      if (item is CategoriaProducto) return item.id == id;
      if (item is Mesa) return item.id == id;
      if (item is Pedido) return item.id == id;
      return false;
    });
    if (index >= 0) {
      await _box.deleteAt(index);
    }
  }

  Future<void> clear() async {
    await _box.clear();
  }
}

class ProductoRepositorio extends Repositorio<Producto> {
  ProductoRepositorio(super.box);

  List<Producto> getPorCategoria(String categoriaId) {
    return getAll().where((p) => p.categoriaId == categoriaId).toList();
  }

  List<Producto> buscar(String texto) {
    final lower = texto.toLowerCase();
    return getAll()
        .where(
          (p) =>
              p.nombre.toLowerCase().contains(lower) ||
              (p.descripcion?.toLowerCase().contains(lower) ?? false),
        )
        .toList();
  }

  List<Producto> getDisponibles() {
    return getAll().where((p) => p.disponible).toList();
  }
}

class CategoriaRepositorio extends Repositorio<CategoriaProducto> {
  CategoriaRepositorio(super.box);
}

class MesaRepositorio extends Repositorio<Mesa> {
  MesaRepositorio(super.box);

  Mesa? getPorNumero(int numero) {
    try {
      return getAll().firstWhere((m) => m.numero == numero);
    } catch (_) {
      return null;
    }
  }

  List<Mesa> getLibres() {
    return getAll().where((m) => m.estado == EstadoMesa.libre).toList();
  }

  List<Mesa> getOcupadas() {
    return getAll().where((m) => m.estado == EstadoMesa.ocupada).toList();
  }
}

class PedidoRepositorio extends Repositorio<Pedido> {
  PedidoRepositorio(super.box);

  List<Pedido> getActivos() {
    return getAll()
        .where(
          (p) =>
              p.estado != EstadoPedido.cerrado &&
              p.estado != EstadoPedido.cancelado,
        )
        .toList();
  }

  List<Pedido> getDeCocina() {
    return getAll()
        .where(
          (p) =>
              p.estado == EstadoPedido.enviadoCocina ||
              p.estado == EstadoPedido.enPreparacion ||
              p.estado == EstadoPedido.listo,
        )
        .toList();
  }

  List<Pedido> getCerrados() {
    return getAll().where((p) => p.estado == EstadoPedido.cerrado).toList();
  }

  List<Pedido> getPorFecha(DateTime fecha) {
    return getAll()
        .where(
          (p) =>
              p.horaApertura.year == fecha.year &&
              p.horaApertura.month == fecha.month &&
              p.horaApertura.day == fecha.day,
        )
        .toList();
  }

  Pedido? getPorMesa(String mesaId) {
    try {
      return getAll().firstWhere(
        (p) => p.mesaId == mesaId && p.estado == EstadoPedido.abierto,
      );
    } catch (_) {
      return null;
    }
  }
}

class CajaRepositorio extends Repositorio<Caja> {
  CajaRepositorio(super.box);

  Caja? getActual() {
    try {
      return getAll().firstWhere((c) => c.estado == EstadoCaja.abierta);
    } catch (_) {
      return null;
    }
  }
}

class MovimientoRepositorio extends Repositorio<MovimientoCaja> {
  MovimientoRepositorio(super.box);

  List<MovimientoCaja> getPorFecha(DateTime fecha) {
    return getAll().where((m) {
      return m.fecha.year == fecha.year &&
          m.fecha.month == fecha.month &&
          m.fecha.day == fecha.day;
    }).toList();
  }

  List<MovimientoCaja> getPorRangoFechas(DateTime inicio, DateTime fin) {
    return getAll().where((m) {
      return m.fecha.isAfter(inicio) && m.fecha.isBefore(fin);
    }).toList();
  }

  List<MovimientoCaja> getIngresos() {
    return getAll().where((m) => m.tipo == 'ingreso').toList();
  }

  List<MovimientoCaja> getRetiros() {
    return getAll().where((m) => m.tipo == 'retiro').toList();
  }

  List<MovimientoCaja> getVentas() {
    return getAll().where((m) => m.tipo == 'venta').toList();
  }
}
