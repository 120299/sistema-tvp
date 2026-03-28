import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/database_service.dart';
import '../../data/services/image_storage_service.dart';
import '../../data/models/models.dart';
import '../../data/examples/ejemplos_usuarios.dart';

final isLoggedInProvider = StateProvider<bool>((ref) => false);

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  throw UnimplementedError('DatabaseService must be initialized before use');
});

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

enum UbicacionAlmacenamiento { local, usb, personalizado }

final ubicacionAlmacenamientoProvider = StateProvider<UbicacionAlmacenamiento>(
  (ref) => UbicacionAlmacenamiento.local,
);

final rutaPersonalizadaProvider = StateProvider<String?>((ref) => null);

final cajerosProvider = StateNotifierProvider<CajerosNotifier, List<Cajero>>((
  ref,
) {
  final db = ref.watch(databaseServiceProvider);
  return CajerosNotifier(db);
});

class CajerosNotifier extends StateNotifier<List<Cajero>> {
  final DatabaseService _db;

  CajerosNotifier(this._db) : super(_loadCajeros(_db));

  static List<Cajero> _loadCajeros(DatabaseService db) {
    final box = db.cajerosBox;
    if (box.isEmpty) {
      final defaultCajero = Cajero(
        id: 'cajero_1',
        nombre: 'Administrador',
        fechaCreacion: DateTime.now(),
        activo: true,
        rol: RolCajero.administrador,
      );
      box.add(defaultCajero);
      return [defaultCajero];
    }
    return box.values.toList();
  }

  Future<void> agregar(Cajero cajero) async {
    await _db.cajerosBox.add(cajero);
    state = [...state, cajero];
  }

  Future<void> actualizar(Cajero cajero) async {
    final index = state.indexWhere((c) => c.id == cajero.id);
    if (index >= 0) {
      await _db.cajerosBox.putAt(index, cajero);
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == index) cajero else state[i],
      ];
    }
  }

  Future<void> eliminar(String id) async {
    final index = state.indexWhere((c) => c.id == id);
    if (index >= 0) {
      await _db.cajerosBox.deleteAt(index);
      state = state.where((c) => c.id != id).toList();
    }
  }

  void actualizarLista() {
    state = _db.cajerosBox.values.toList();
  }

  Future<void> cargarEjemplos() async {
    final ejemplos = EjemplosUsuarios.crearEjemplos();
    for (final cajero in ejemplos) {
      // Verificar si ya existe
      final existe = state.any((c) => c.id == cajero.id);
      if (!existe) {
        await _db.cajerosBox.add(cajero);
      }
    }
    actualizarLista();
  }
}

final cajeroActualProvider = StateProvider<Cajero?>((ref) => null);

final clientesProvider = StateNotifierProvider<ClientesNotifier, List<Cliente>>(
  (ref) {
    final db = ref.watch(databaseServiceProvider);
    return ClientesNotifier(db);
  },
);

class ClientesNotifier extends StateNotifier<List<Cliente>> {
  final DatabaseService _db;

  ClientesNotifier(this._db) : super([]);

  Future<void> agregar(Cliente cliente) async {
    await _db.clientesBox.add(cliente);
    state = [...state, cliente];
  }

  Future<void> actualizar(Cliente cliente) async {
    final index = state.indexWhere((c) => c.id == cliente.id);
    if (index >= 0) {
      await _db.clientesBox.putAt(index, cliente);
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == index) cliente else state[i],
      ];
    }
  }

  Future<void> eliminar(String id) async {
    final index = state.indexWhere((c) => c.id == id);
    if (index >= 0) {
      await _db.clientesBox.deleteAt(index);
      state = state.where((c) => c.id != id).toList();
    }
  }

  Cliente? buscarPorTelefono(String telefono) {
    try {
      return state.firstWhere((c) => c.telefono == telefono);
    } catch (_) {
      return null;
    }
  }

  Future<void> registrarVenta(String clienteId, double importe) async {
    final index = state.indexWhere((c) => c.id == clienteId);
    if (index < 0) return;

    final cliente = state[index];
    final actualizado = cliente.copyWith(
      totalPedidos: cliente.totalPedidos + 1,
      totalGastado: cliente.totalGastado + importe,
    );

    await _db.clientesBox.putAt(index, actualizado);
    state = [
      for (int i = 0; i < state.length; i++)
        if (i == index) actualizado else state[i],
    ];
  }

  Cliente? getPorId(String id) {
    try {
      return state.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  void actualizarLista() {
    state = _db.clientesBox.values.toList();
  }
}

final negocioProvider = StateNotifierProvider<NegocioNotifier, DatosNegocio>((
  ref,
) {
  final db = ref.watch(databaseServiceProvider);
  return NegocioNotifier(db);
});

class NegocioNotifier extends StateNotifier<DatosNegocio> {
  final DatabaseService _db;

  NegocioNotifier(this._db)
    : super(_db.negocioBox.get('negocio_1') ?? const DatosNegocio());

  bool get estaConfigurado => state.estaConfigurado;

  Future<void> actualizar(DatosNegocio datos) async {
    await _db.negocioBox.put('negocio_1', datos);
    state = datos;
  }

  Future<int> obtenerSiguienteNumeroTicket() async {
    final hoy = DateTime.now();
    final fechaUltima = state.ultimaFechaContador;

    int nuevoContadorDiario;
    int nuevoContadorGlobal = state.contadorTicketsGlobal + 1;

    if (fechaUltima == null ||
        fechaUltima.day != hoy.day ||
        fechaUltima.month != hoy.month ||
        fechaUltima.year != hoy.year) {
      nuevoContadorDiario = 1;
    } else {
      nuevoContadorDiario = state.contadorTicketsDiario + 1;
    }

    final actualizado = state.copyWith(
      contadorTicketsDiario: nuevoContadorDiario,
      contadorTicketsGlobal: nuevoContadorGlobal,
      ultimaFechaContador: hoy,
    );

    await actualizar(actualizado);
    return nuevoContadorGlobal;
  }

  Future<void> reiniciarContadorDiario() async {
    final actualizado = state.copyWith(
      contadorTicketsDiario: 0,
      ultimaFechaContador: null,
    );
    await actualizar(actualizado);
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
    try {
      // Buscar el producto existente por ID
      final box = _db.productosBox;
      dynamic keyEncontrada;
      Producto? productoExistente;

      for (int i = 0; i < box.length; i++) {
        final p = box.getAt(i);
        if (p != null && p.id == producto.id) {
          keyEncontrada = box.keyAt(i);
          productoExistente = p;
          break;
        }
      }

      if (keyEncontrada != null) {
        // Actualizar usando la clave encontrada
        await box.put(keyEncontrada, producto);
        debugPrint(
          'DEBUG: Producto actualizado correctamente con key: $keyEncontrada',
        );
      } else {
        // Si no se encuentra, agregar como nuevo
        debugPrint('DEBUG: Producto no encontrado, agregando como nuevo');
        await box.add(producto);
      }

      // Forzar refresh
      _refresh();

      // Verificar que se guardó
      final actualizado = _db.productosBox.values
          .where((p) => p.id == producto.id)
          .firstOrNull;
      if (actualizado != null) {
        debugPrint(
          'DEBUG: Verificación exitosa - producto guardado: ${actualizado.nombre}',
        );
      } else {
        debugPrint(
          'ERROR: Verificación falló - producto no encontrado después de guardar',
        );
      }
    } catch (e, st) {
      debugPrint('ERROR en actualizar(): $e');
      debugPrint('Stack trace: $st');
      rethrow;
    }
  }

  Future<void> eliminar(String id) async {
    final box = _db.productosBox;
    dynamic productoKey;

    for (int i = 0; i < box.length; i++) {
      final p = box.getAt(i);
      if (p != null && p.id == id) {
        productoKey = box.keyAt(i);
        break;
      }
    }

    if (productoKey != null) {
      await box.delete(productoKey);
      _refresh();
    }
  }

  Future<void> toggleDisponibilidad(String id) async {
    final producto = state.firstWhere((p) => p.id == id);
    final actualizado = producto.copyWith(disponible: !producto.disponible);
    await actualizar(actualizado);
  }

  void actualizarLista() {
    _refresh();
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

  Future<void> reorder(int oldIndex, int newIndex) async {
    final categorias = List<CategoriaProducto>.from(state);
    if (newIndex > oldIndex) newIndex--;
    final item = categorias.removeAt(oldIndex);
    categorias.insert(newIndex, item);

    final updatedCategorias = <CategoriaProducto>[];
    for (int i = 0; i < categorias.length; i++) {
      updatedCategorias.add(categorias[i].copyWith(orden: i));
    }

    state = updatedCategorias;

    for (final updated in updatedCategorias) {
      final box = _db.categoriasBox;
      dynamic keyEncontrado;

      for (int j = 0; j < box.length; j++) {
        final cat = box.getAt(j);
        if (cat != null && cat.id == updated.id) {
          keyEncontrado = box.keyAt(j);
          break;
        }
      }

      if (keyEncontrado != null) {
        await box.put(keyEncontrado, updated);
      }
    }
  }

  Future<void> reorderFromList(
    List<CategoriaProducto> sortedList,
    int oldIndex,
    int newIndex,
  ) async {
    final categorias = List<CategoriaProducto>.from(sortedList);
    if (newIndex > oldIndex) newIndex--;
    final item = categorias.removeAt(oldIndex);
    categorias.insert(newIndex, item);

    final updatedCategorias = <CategoriaProducto>[];
    for (int i = 0; i < categorias.length; i++) {
      updatedCategorias.add(categorias[i].copyWith(orden: i));
    }

    state = updatedCategorias;

    for (final updated in updatedCategorias) {
      final box = _db.categoriasBox;
      dynamic keyEncontrado;

      for (int j = 0; j < box.length; j++) {
        final cat = box.getAt(j);
        if (cat != null && cat.id == updated.id) {
          keyEncontrado = box.keyAt(j);
          break;
        }
      }

      if (keyEncontrado != null) {
        await box.put(keyEncontrado, updated);
      }
    }
  }

  void actualizarLista() {
    _refresh();
  }
}

final categoriaSeleccionadaProvider = StateProvider<String?>((ref) => null);

// Filtros compartidos entre Productos y Ventas
enum FiltroDisponibilidad { todos, disponibles, noDisponibles }

enum FiltroTipo { todos, normales, variables }

final filtroDisponibilidadProvider = StateProvider<FiltroDisponibilidad>(
  (ref) => FiltroDisponibilidad.todos,
);
final filtroTipoProvider = StateProvider<FiltroTipo>((ref) => FiltroTipo.todos);
final busquedaCompartidaProvider = StateProvider<String>((ref) => '');

// Tipos de orden para productos
enum TipoOrdenProducto { nombre, precio, disponible }

enum DireccionOrden { ascendente, descendente }

class OrdenProducto {
  final TipoOrdenProducto campo;
  final DireccionOrden direccion;

  const OrdenProducto({
    this.campo = TipoOrdenProducto.nombre,
    this.direccion = DireccionOrden.ascendente,
  });

  OrdenProducto copyWith({
    TipoOrdenProducto? campo,
    DireccionOrden? direccion,
  }) {
    return OrdenProducto(
      campo: campo ?? this.campo,
      direccion: direccion ?? this.direccion,
    );
  }
}

class OrdenProductoNotifier extends StateNotifier<OrdenProducto> {
  OrdenProductoNotifier() : super(_cargarOrdenProductoInicial());

  Future<void> setOrden(OrdenProducto orden) async {
    state = orden;
    await _guardarOrden(orden);
  }

  Future<void> _guardarOrden(OrdenProducto orden) async {
    try {
      final db = DatabaseService();
      String campo;
      switch (orden.campo) {
        case TipoOrdenProducto.precio:
          campo = 'precio';
          break;
        case TipoOrdenProducto.disponible:
          campo = 'disponible';
          break;
        default:
          campo = 'nombre';
      }
      await db.guardarOrdenProducto(campo, orden.direccion.name);
    } catch (e) {
      debugPrint('Error guardando orden: $e');
    }
  }
}

OrdenProducto _cargarOrdenProductoInicial() {
  try {
    final db = DatabaseService();
    final prefs = db.obtenerOrdenProducto();

    TipoOrdenProducto campo;
    switch (prefs['campo']) {
      case 'precio':
        campo = TipoOrdenProducto.precio;
        break;
      case 'disponible':
        campo = TipoOrdenProducto.disponible;
        break;
      default:
        campo = TipoOrdenProducto.nombre;
    }

    DireccionOrden direccion;
    switch (prefs['direccion']) {
      case 'descendente':
        direccion = DireccionOrden.descendente;
        break;
      default:
        direccion = DireccionOrden.ascendente;
    }

    return OrdenProducto(campo: campo, direccion: direccion);
  } catch (e) {
    return const OrdenProducto();
  }
}

final ordenProductoProvider =
    StateNotifierProvider<OrdenProductoNotifier, OrdenProducto>((ref) {
      return OrdenProductoNotifier();
    });

final productosFiltradosProvider = Provider<List<Producto>>((ref) {
  final categoriaId = ref.watch(categoriaSeleccionadaProvider);
  final productos = ref.watch(productosProvider);
  final filtroDisp = ref.watch(filtroDisponibilidadProvider);
  final filtroTipo = ref.watch(filtroTipoProvider);
  final busqueda = ref.watch(busquedaCompartidaProvider).toLowerCase();

  var resultado = productos;

  // Filtro por categoría
  if (categoriaId != null) {
    resultado = resultado.where((p) => p.categoriaId == categoriaId).toList();
  }

  // Filtro por disponibilidad
  switch (filtroDisp) {
    case FiltroDisponibilidad.disponibles:
      resultado = resultado.where((p) => p.disponible).toList();
      break;
    case FiltroDisponibilidad.noDisponibles:
      resultado = resultado.where((p) => !p.disponible).toList();
      break;
    case FiltroDisponibilidad.todos:
      break;
  }

  // Filtro por tipo
  switch (filtroTipo) {
    case FiltroTipo.variables:
      resultado = resultado.where((p) => p.esVariable).toList();
      break;
    case FiltroTipo.normales:
      resultado = resultado.where((p) => !p.esVariable).toList();
      break;
    case FiltroTipo.todos:
      break;
  }

  // Filtro por búsqueda
  if (busqueda.isNotEmpty) {
    resultado = resultado
        .where(
          (p) =>
              p.nombre.toLowerCase().contains(busqueda) ||
              (p.descripcion?.toLowerCase().contains(busqueda) ?? false),
        )
        .toList();
  }

  return resultado;
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

  Future<void> actualizarMesa(
    String mesaId, {
    int? numero,
    String? nombre,
    int? capacidad,
    DateTime? fechaReserva,
  }) async {
    final mesa = state.firstWhere((m) => m.id == mesaId);
    await actualizar(
      mesa.copyWith(
        numero: numero ?? mesa.numero,
        nombre: nombre,
        capacidad: capacidad ?? mesa.capacidad,
        fechaReserva: fechaReserva,
      ),
    );
  }

  Mesa? getPorId(String id) {
    try {
      return state.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  void actualizarLista() {
    _refresh();
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

  Future<String> crear(
    String mesaId, {
    double porcentajePropina = 0,
    String? clienteId,
    String? clienteNombre,
    String? cajeroId,
    String? cajeroNombre,
  }) async {
    final id = 'pedido_${DateTime.now().millisecondsSinceEpoch}';
    final pedido = Pedido(
      id: id,
      mesaId: mesaId,
      mesero: 'Camarero',
      porcentajePropina: porcentajePropina,
      clienteId: clienteId,
      clienteNombre: clienteNombre,
      cajeroId: cajeroId,
      cajeroNombre: cajeroNombre,
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
    VarianteProducto? variante,
  }) async {
    final pedidoIndex = state.indexWhere((p) => p.id == pedidoId);
    if (pedidoIndex < 0) return;

    final pedido = state[pedidoIndex];
    final precio = variante?.precio ?? producto.precio;
    final nombre = variante != null
        ? '${producto.nombre} - ${variante.nombre}'
        : producto.nombre;
    final item = PedidoItem(
      id: 'item_${DateTime.now().millisecondsSinceEpoch}',
      productoId: producto.id,
      productoNombre: nombre,
      cantidad: cantidad,
      precioUnitario: precio,
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

  Future<void> eliminarItem(String pedidoId, String itemId) async {
    final pedidoIndex = state.indexWhere((p) => p.id == pedidoId);
    if (pedidoIndex < 0) return;

    final pedido = state[pedidoIndex];
    final nuevosItems = pedido.items.where((i) => i.id != itemId).toList();
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

  Future<void> cancelar(String pedidoId) async {
    await _cambiarEstado(pedidoId, EstadoPedido.cancelado);
  }

  Future<void> eliminar(String pedidoId) async {
    final box = _db.pedidosBox;
    for (int i = 0; i < box.length; i++) {
      final pedido = box.getAt(i);
      if (pedido != null && pedido.id == pedidoId) {
        await box.deleteAt(i);
        _refresh();
        return;
      }
    }
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
    int? numeroTicket,
  }) async {
    final pedidoIndex = state.indexWhere((p) => p.id == pedidoId);
    if (pedidoIndex < 0) return;

    final pedido = state[pedidoIndex];
    final actualizado = pedido.copyWith(
      estado: EstadoPedido.cerrado,
      horaCierre: DateTime.now(),
      metodoPago: metodoPago,
      descuento: descuento,
      numeroTicket: numeroTicket,
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
    String? cajeroId,
  }) {
    var result = state.where((p) => p.estado == EstadoPedido.cerrado).toList();

    if (fechaInicio != null) {
      final inicio = DateTime(
        fechaInicio.year,
        fechaInicio.month,
        fechaInicio.day,
        0,
        0,
        0,
      );
      result = result.where((p) => !p.horaApertura.isBefore(inicio)).toList();
    }
    if (fechaFin != null) {
      final fin = DateTime(
        fechaFin.year,
        fechaFin.month,
        fechaFin.day,
        23,
        59,
        59,
      );
      result = result.where((p) => !p.horaApertura.isAfter(fin)).toList();
    }
    if (metodoPago != null && metodoPago.isNotEmpty) {
      result = result.where((p) => p.metodoPago == metodoPago).toList();
    }
    if (mesaId != null && mesaId.isNotEmpty) {
      result = result.where((p) => p.mesaId == mesaId).toList();
    }
    if (cajeroId != null && cajeroId.isNotEmpty) {
      result = result.where((p) => p.cajeroId == cajeroId).toList();
    }

    return result..sort((a, b) => b.horaApertura.compareTo(a.horaApertura));
  }

  void actualizarLista() {
    _refresh();
  }
}

final indiceNavegacionProvider = StateProvider<int>((ref) => 0);

final mesaVentaSeleccionadaProvider = StateProvider<String?>((ref) => null);

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

  Future<void> abrirCaja({
    double fondoInicial = 0,
    String? cajeroId,
    String? cajeroNombre,
  }) async {
    final caja = Caja(
      id: 'caja_${DateTime.now().millisecondsSinceEpoch}',
      fechaApertura: DateTime.now(),
      fondoInicial: fondoInicial,
      estado: EstadoCaja.abierta,
      cajeroId: cajeroId,
      cajeroNombre: cajeroNombre,
    );
    await _db.cajaBox.add(caja);
    state = caja;
  }

  Future<void> cerrarCaja({double? saldoFinal}) async {
    if (state == null) return;

    final cerrada = state!.copyWith(
      estado: EstadoCaja.cerrada,
      fechaCierre: DateTime.now(),
      saldoFinal: saldoFinal ?? state!.saldoCaja,
    );

    final values = _db.cajaBox.values.toList();
    final index = values.indexWhere((c) => c.id == state!.id);
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

    final values = _db.cajaBox.values.toList();
    final index = values.indexWhere((c) => c.id == state!.id);
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

    final values = _db.cajaBox.values.toList();
    final index = values.indexWhere((c) => c.id == state!.id);
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

    final values = _db.cajaBox.values.toList();
    final index = values.indexWhere((c) => c.id == state!.id);
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

final cajasHistorialProvider =
    StateNotifierProvider<CajasHistorialNotifier, List<Caja>>((ref) {
      final db = ref.watch(databaseServiceProvider);
      return CajasHistorialNotifier(db);
    });

class CajasHistorialNotifier extends StateNotifier<List<Caja>> {
  final DatabaseService _db;
  StreamSubscription<String>? _subscription;

  CajasHistorialNotifier(this._db) : super(_db.cajaRepositorio.getHistorial()) {
    _setupListener();
  }

  void _setupListener() {
    _subscription = _db.onBoxChanged.listen((boxName) {
      if (boxName == 'caja') {
        refresh();
      }
    });
  }

  void refresh() {
    state = _db.cajaRepositorio.getHistorial();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
