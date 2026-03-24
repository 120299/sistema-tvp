import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/database_service.dart';
import '../../data/services/image_storage_service.dart';
import '../../data/models/models.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  throw UnimplementedError('DatabaseService must be initialized before use');
});

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

enum UbicacionAlmacenamiento { local, usb, red }

final ubicacionAlmacenamientoProvider = StateProvider<UbicacionAlmacenamiento>(
  (ref) => UbicacionAlmacenamiento.local,
);

final negocioProvider = StateNotifierProvider<NegocioNotifier, DatosNegocio>((
  ref,
) {
  final db = ref.watch(databaseServiceProvider);
  return NegocioNotifier(db);
});

class NegocioNotifier extends StateNotifier<DatosNegocio> {
  final DatabaseService _db;

  NegocioNotifier(this._db)
    : super(_db.negocioBox.getAt(0) ?? DatosNegocio.ejemplo);

  Future<void> actualizar(DatosNegocio datos) async {
    await _db.negocioBox.putAt(0, datos);
    state = datos;
  }
}

final productosProvider =
    StateNotifierProvider<ProductosNotifier, List<Producto>>((ref) {
      final db = ref.watch(databaseServiceProvider);
      return ProductosNotifier(db);
    });

class ProductosNotifier extends StateNotifier<List<Producto>> {
  final DatabaseService _db;

  ProductosNotifier(this._db) : super(_db.productoRepositorio.getAll());

  void _refresh() {
    state = _db.productoRepositorio.getAll();
  }

  Future<void> agregar(Producto producto) async {
    await _db.productosBox.add(producto);
    _refresh();
  }

  Future<void> actualizar(Producto producto) async {
    final index = state.indexWhere((p) => p.id == producto.id);
    if (index >= 0) {
      await _db.productosBox.putAt(index, producto);
      _refresh();
    }
  }

  Future<void> eliminar(String id) async {
    final index = state.indexWhere((p) => p.id == id);
    if (index >= 0) {
      await _db.productosBox.deleteAt(index);
      _refresh();
    }
  }

  Future<void> toggleDisponibilidad(String id) async {
    final producto = state.firstWhere((p) => p.id == id);
    final actualizado = producto.copyWith(disponible: !producto.disponible);
    await actualizar(actualizado);
  }
}

final categoriasProvider =
    StateNotifierProvider<CategoriasNotifier, List<CategoriaProducto>>((ref) {
      final db = ref.watch(databaseServiceProvider);
      return CategoriasNotifier(db);
    });

class CategoriasNotifier extends StateNotifier<List<CategoriaProducto>> {
  final DatabaseService _db;

  CategoriasNotifier(this._db) : super(_db.categoriaRepositorio.getAll());

  void _refresh() {
    state = _db.categoriaRepositorio.getAll();
  }

  Future<void> agregar(CategoriaProducto categoria) async {
    await _db.categoriasBox.add(categoria);
    _refresh();
  }

  Future<void> actualizar(CategoriaProducto categoria) async {
    final index = state.indexWhere((c) => c.id == categoria.id);
    if (index >= 0) {
      await _db.categoriasBox.putAt(index, categoria);
      _refresh();
    }
  }

  Future<void> eliminar(String id) async {
    final index = state.indexWhere((c) => c.id == id);
    if (index >= 0) {
      await _db.categoriasBox.deleteAt(index);
      _refresh();
    }
  }
}

final categoriaSeleccionadaProvider = StateProvider<String?>((ref) => null);

final productosFiltradosProvider = Provider<List<Producto>>((ref) {
  final categoriaId = ref.watch(categoriaSeleccionadaProvider);
  final productos = ref.watch(productosProvider);

  if (categoriaId == null) return productos;
  return productos.where((p) => p.categoriaId == categoriaId).toList();
});

final mesasProvider = StateNotifierProvider<MesasNotifier, List<Mesa>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return MesasNotifier(db);
});

class MesasNotifier extends StateNotifier<List<Mesa>> {
  final DatabaseService _db;

  MesasNotifier(this._db) : super(_db.mesaRepositorio.getAll());

  void _refresh() {
    state = _db.mesaRepositorio.getAll();
  }

  Future<void> agregar(Mesa mesa) async {
    await _db.mesasBox.add(mesa);
    _refresh();
  }

  Future<void> actualizar(Mesa mesa) async {
    final index = state.indexWhere((m) => m.id == mesa.id);
    if (index >= 0) {
      await _db.mesasBox.putAt(index, mesa);
      _refresh();
    }
  }

  Future<void> eliminar(String id) async {
    final index = state.indexWhere((m) => m.id == id);
    if (index >= 0) {
      await _db.mesasBox.deleteAt(index);
      _refresh();
    }
  }

  Future<void> ocupar(String mesaId, String pedidoId) async {
    final mesa = state.firstWhere((m) => m.id == mesaId);
    await actualizar(
      mesa.copyWith(
        estado: EstadoMesa.ocupada,
        pedidoActualId: pedidoId,
        horaApertura: DateTime.now(),
      ),
    );
  }

  Future<void> liberar(String mesaId) async {
    final mesa = state.firstWhere((m) => m.id == mesaId);
    await actualizar(
      mesa.copyWith(
        estado: EstadoMesa.libre,
        pedidoActualId: null,
        horaApertura: null,
      ),
    );
  }

  Future<void> marcarReservada(String mesaId) async {
    final mesa = state.firstWhere((m) => m.id == mesaId);
    await actualizar(mesa.copyWith(estado: EstadoMesa.reservada));
  }

  Future<void> marcarAtencion(String mesaId) async {
    final mesa = state.firstWhere((m) => m.id == mesaId);
    await actualizar(mesa.copyWith(estado: EstadoMesa.necesitaAtencion));
  }

  Mesa? getPorId(String id) {
    try {
      return state.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }
}

final pedidosProvider = StateNotifierProvider<PedidosNotifier, List<Pedido>>((
  ref,
) {
  final db = ref.watch(databaseServiceProvider);
  return PedidosNotifier(db);
});

class PedidosNotifier extends StateNotifier<List<Pedido>> {
  final DatabaseService _db;

  PedidosNotifier(this._db) : super(_db.pedidoRepositorio.getAll());

  void _refresh() {
    state = _db.pedidoRepositorio.getAll();
  }

  Future<String> crear(String mesaId, {double porcentajePropina = 0}) async {
    final id = 'pedido_${DateTime.now().millisecondsSinceEpoch}';
    final pedido = Pedido(
      id: id,
      mesaId: mesaId,
      mesero: 'Camarero',
      porcentajePropina: porcentajePropina,
    );
    await _db.pedidosBox.add(pedido);
    _refresh();
    return id;
  }

  Future<void> agregarItem(
    String pedidoId,
    Producto producto, {
    int cantidad = 1,
    String? notas,
  }) async {
    final pedidoIndex = state.indexWhere((p) => p.id == pedidoId);
    if (pedidoIndex < 0) return;

    final pedido = state[pedidoIndex];
    final item = PedidoItem(
      id: 'item_${DateTime.now().millisecondsSinceEpoch}',
      productoId: producto.id,
      productoNombre: producto.nombre,
      cantidad: cantidad,
      precioUnitario: producto.precio,
      notas: notas,
    );

    final actualizado = pedido.copyWith(items: [...pedido.items, item]);
    await _db.pedidosBox.putAt(pedidoIndex, actualizado);
    _refresh();
  }

  Future<void> actualizarCantidad(
    String pedidoId,
    String itemId,
    int cantidad,
  ) async {
    final pedidoIndex = state.indexWhere((p) => p.id == pedidoId);
    if (pedidoIndex < 0) return;

    final pedido = state[pedidoIndex];
    List<PedidoItem> nuevosItems;

    if (cantidad <= 0) {
      nuevosItems = pedido.items.where((i) => i.id != itemId).toList();
    } else {
      nuevosItems = pedido.items.map((i) {
        if (i.id == itemId) return i.copyWith(cantidad: cantidad);
        return i;
      }).toList();
    }

    final actualizado = pedido.copyWith(items: nuevosItems);
    await _db.pedidosBox.putAt(pedidoIndex, actualizado);
    _refresh();
  }

  Future<void> enviarACocina(String pedidoId) async {
    await _cambiarEstado(pedidoId, EstadoPedido.enviadoCocina);
  }

  Future<void> marcarEnPreparacion(String pedidoId) async {
    await _cambiarEstado(pedidoId, EstadoPedido.enPreparacion);
  }

  Future<void> marcarListo(String pedidoId) async {
    await _cambiarEstado(pedidoId, EstadoPedido.listo);
  }

  Future<void> actualizar(Pedido pedido) async {
    final pedidoIndex = state.indexWhere((p) => p.id == pedido.id);
    if (pedidoIndex < 0) return;
    await _db.pedidosBox.putAt(pedidoIndex, pedido);
    _refresh();
  }

  Future<void> cerrar(
    String pedidoId,
    String metodoPago, {
    double descuento = 0,
  }) async {
    final pedidoIndex = state.indexWhere((p) => p.id == pedidoId);
    if (pedidoIndex < 0) return;

    final pedido = state[pedidoIndex];
    final actualizado = pedido.copyWith(
      estado: EstadoPedido.cerrado,
      horaCierre: DateTime.now(),
      metodoPago: metodoPago,
      descuento: descuento,
    );
    await _db.pedidosBox.putAt(pedidoIndex, actualizado);
    _refresh();
  }

  Future<void> _cambiarEstado(String pedidoId, EstadoPedido nuevoEstado) async {
    final pedidoIndex = state.indexWhere((p) => p.id == pedidoId);
    if (pedidoIndex < 0) return;

    final pedido = state[pedidoIndex];
    final actualizado = pedido.copyWith(estado: nuevoEstado);
    await _db.pedidosBox.putAt(pedidoIndex, actualizado);
    _refresh();
  }

  Pedido? getPorId(String id) {
    try {
      return state.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Pedido> getActivos() {
    return state
        .where(
          (p) =>
              p.estado != EstadoPedido.cerrado &&
              p.estado != EstadoPedido.cancelado,
        )
        .toList();
  }

  List<Pedido> getCocina() {
    return state
        .where(
          (p) =>
              p.estado == EstadoPedido.enviadoCocina ||
              p.estado == EstadoPedido.enPreparacion ||
              p.estado == EstadoPedido.listo,
        )
        .toList();
  }

  List<Pedido> getCerrados() {
    return state.where((p) => p.estado == EstadoPedido.cerrado).toList();
  }

  List<Pedido> getPorFecha(DateTime fecha) {
    return state
        .where(
          (p) =>
              p.horaApertura.year == fecha.year &&
              p.horaApertura.month == fecha.month &&
              p.horaApertura.day == fecha.day,
        )
        .toList();
  }

  List<Pedido> getPorMesa(String mesaId) {
    return state.where((p) => p.mesaId == mesaId).toList()
      ..sort((a, b) => b.horaApertura.compareTo(a.horaApertura));
  }

  List<Pedido> getPorRangoFechas(DateTime inicio, DateTime fin) {
    return state.where((p) {
      return p.horaApertura.isAfter(inicio) && p.horaApertura.isBefore(fin);
    }).toList();
  }

  List<Pedido> getPorMetodoPago(String metodoPago) {
    return state.where((p) => p.metodoPago == metodoPago).toList();
  }

  List<Pedido> getFiltrados({
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? metodoPago,
    String? mesaId,
  }) {
    var result = state.where((p) => p.estado == EstadoPedido.cerrado).toList();

    if (fechaInicio != null) {
      result = result
          .where((p) => p.horaApertura.isAfter(fechaInicio))
          .toList();
    }
    if (fechaFin != null) {
      result = result.where((p) => p.horaApertura.isBefore(fechaFin)).toList();
    }
    if (metodoPago != null && metodoPago.isNotEmpty) {
      result = result.where((p) => p.metodoPago == metodoPago).toList();
    }
    if (mesaId != null && mesaId.isNotEmpty) {
      result = result.where((p) => p.mesaId == mesaId).toList();
    }

    return result..sort((a, b) => b.horaApertura.compareTo(a.horaApertura));
  }
}

final indiceNavegacionProvider = StateProvider<int>((ref) => 0);

final imageRefreshProvider = StreamProvider<void>((ref) {
  return imageStorageService.onImageChanged;
});

final imageRefreshTriggerProvider = StateProvider<int>((ref) => 0);

void triggerImageRefresh(WidgetRef ref) {
  ref.read(imageRefreshTriggerProvider.notifier).state++;
}

final cajaProvider = StateNotifierProvider<CajaNotifier, Caja?>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return CajaNotifier(db);
});

class CajaNotifier extends StateNotifier<Caja?> {
  final DatabaseService _db;
  StreamSubscription<String>? _subscription;

  CajaNotifier(this._db) : super(_db.cajaRepositorio.getActual()) {
    _setupListener();
  }

  void _setupListener() {
    _subscription = _db.onBoxChanged.listen((boxName) {
      if (boxName == 'caja') {
        state = _db.cajaRepositorio.getActual();
      }
    });
  }

  Future<void> abrirCaja({double fondoInicial = 0}) async {
    final caja = Caja(
      id: 'caja_${DateTime.now().millisecondsSinceEpoch}',
      fechaApertura: DateTime.now(),
      fondoInicial: fondoInicial,
      estado: EstadoCaja.abierta,
    );
    await _db.cajaBox.add(caja);
    state = caja;
  }

  Future<void> cerrarCaja({double? saldoFinal}) async {
    if (state == null) return;

    final cerrada = state!.copyWith(
      estado: EstadoCaja.cerrada,
      fechaCierre: DateTime.now(),
      saldoFinal: saldoFinal,
    );

    final index = _db.cajaBox.values.toList().indexOf(state!);
    if (index >= 0) {
      await _db.cajaBox.putAt(index, cerrada);
    }

    state = null;
  }

  Future<void> agregarIngreso(double cantidad, String descripcion) async {
    if (state == null || state!.estado != EstadoCaja.abierta) return;

    final movimiento = MovimientoCaja(
      id: 'mov_${DateTime.now().millisecondsSinceEpoch}',
      tipo: 'ingreso',
      cantidad: cantidad,
      descripcion: descripcion,
      fecha: DateTime.now(),
    );

    final actualizada = state!.copyWith(
      movimientos: [...state!.movimientos, movimiento],
    );

    final index = _db.cajaBox.values.toList().indexOf(state!);
    if (index >= 0) {
      await _db.cajaBox.putAt(index, actualizada);
      state = actualizada;
    }
  }

  Future<void> agregarRetiro(double cantidad, String descripcion) async {
    if (state == null || state!.estado != EstadoCaja.abierta) return;

    final movimiento = MovimientoCaja(
      id: 'mov_${DateTime.now().millisecondsSinceEpoch}',
      tipo: 'retiro',
      cantidad: cantidad,
      descripcion: descripcion,
      fecha: DateTime.now(),
    );

    final actualizada = state!.copyWith(
      movimientos: [...state!.movimientos, movimiento],
    );

    final index = _db.cajaBox.values.toList().indexOf(state!);
    if (index >= 0) {
      await _db.cajaBox.putAt(index, actualizada);
      state = actualizada;
    }
  }

  Future<void> registrarVenta(
    double cantidad,
    String metodoPago, {
    String? pedidoId,
  }) async {
    if (state == null || state!.estado != EstadoCaja.abierta) return;

    final movimiento = MovimientoCaja(
      id: 'mov_${DateTime.now().millisecondsSinceEpoch}',
      tipo: 'venta',
      cantidad: cantidad,
      metodoPago: metodoPago,
      fecha: DateTime.now(),
      pedidoId: pedidoId,
    );

    final actualizada = state!.copyWith(
      totalVentas: state!.totalVentas + cantidad,
      totalEfectivo: metodoPago == 'Efectivo'
          ? state!.totalEfectivo + cantidad
          : state!.totalEfectivo,
      totalTarjeta: metodoPago == 'Tarjeta'
          ? state!.totalTarjeta + cantidad
          : state!.totalTarjeta,
      movimientos: [...state!.movimientos, movimiento],
    );

    final index = _db.cajaBox.values.toList().indexOf(state!);
    if (index >= 0) {
      await _db.cajaBox.putAt(index, actualizada);
      state = actualizada;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final cajaStreamProvider = StreamProvider<void>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return db.onBoxChanged.where((boxName) => boxName == 'caja').map((_) {});
});
