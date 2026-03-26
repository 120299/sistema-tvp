import 'dart:async';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';
import '../adapters/hive_adapters.dart';
import '../repositories/repositories.dart';
import 'image_storage_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const String _productosBox = 'productos';
  static const String _categoriasBox = 'categorias';
  static const String _mesasBox = 'mesas';
  static const String _pedidosBox = 'pedidos';
  static const String _negocioBox = 'negocio';
  static const String _configBox = 'config';
  static const String _cajaBox = 'caja';
  static const String _movimientosBox = 'movimientos';
  static const String _cajerosBox = 'cajeros';
  static const String _clientesBox = 'clientes';

  late Box<Producto> productosBox;
  late Box<CategoriaProducto> categoriasBox;
  late Box<Mesa> mesasBox;
  late Box<Pedido> pedidosBox;
  late Box<DatosNegocio> negocioBox;
  late Box<Caja> cajaBox;
  late Box<MovimientoCaja> movimientosBox;
  late Box<Cajero> cajerosBox;
  late Box<Cliente> clientesBox;
  late Box configBox;

  late ProductoRepositorio productoRepositorio;
  late CategoriaRepositorio categoriaRepositorio;
  late MesaRepositorio mesaRepositorio;
  late PedidoRepositorio pedidoRepositorio;
  late CajaRepositorio cajaRepositorio;
  late MovimientoRepositorio movimientoRepositorio;

  final _changeController = StreamController<String>.broadcast();

  Stream<String> get changeStream => _changeController.stream;

  Stream<String> get onBoxChanged => _changeController.stream;

  void notifyChange(String collection) {
    _changeController.add(collection);
  }

  Future<void> initialize() async {
    if (!kIsWeb) {
      final directory = await _getDataDirectory();
      await Hive.initFlutter(directory.path);
    } else {
      await Hive.initFlutter();
    }

    Hive.registerAdapter(CategoriaProductoAdapter());
    Hive.registerAdapter(ProductoAdapter());
    Hive.registerAdapter(MesaAdapter());
    Hive.registerAdapter(PedidoItemAdapter());
    Hive.registerAdapter(PedidoAdapter());
    Hive.registerAdapter(DatosNegocioAdapter());
    Hive.registerAdapter(CajaAdapter());
    Hive.registerAdapter(MovimientoCajaAdapter());
    Hive.registerAdapter(CajeroAdapter());
    Hive.registerAdapter(ClienteAdapter());

    productosBox = await Hive.openBox<Producto>(_productosBox);
    categoriasBox = await Hive.openBox<CategoriaProducto>(_categoriasBox);
    mesasBox = await Hive.openBox<Mesa>(_mesasBox);
    pedidosBox = await Hive.openBox<Pedido>(_pedidosBox);
    negocioBox = await Hive.openBox<DatosNegocio>(_negocioBox);
    configBox = await Hive.openBox(_configBox);
    cajaBox = await Hive.openBox<Caja>(_cajaBox);
    movimientosBox = await Hive.openBox<MovimientoCaja>(_movimientosBox);
    cajerosBox = await Hive.openBox<Cajero>(_cajerosBox);
    clientesBox = await Hive.openBox<Cliente>(_clientesBox);

    _setupListeners();

    await imageStorageService.init();

    productoRepositorio = ProductoRepositorio(productosBox);
    categoriaRepositorio = CategoriaRepositorio(categoriasBox);
    mesaRepositorio = MesaRepositorio(mesasBox);
    pedidoRepositorio = PedidoRepositorio(pedidosBox);
    cajaRepositorio = CajaRepositorio(cajaBox);
    movimientoRepositorio = MovimientoRepositorio(movimientosBox);

    _initialized = true;

    await _seedData();
  }

  Future<Directory> _getDataDirectory() async {
    String basePath;

    if (kIsWeb) {
      basePath = (await getApplicationDocumentsDirectory()).path;
    } else if (Platform.isWindows ||
        Platform.isMacOS ||
        Platform.isLinux ||
        Platform.isIOS ||
        Platform.isAndroid) {
      basePath = Directory.current.path;
    } else {
      basePath = (await getApplicationDocumentsDirectory()).path;
    }

    final tpvdDir = Directory('$basePath/tpv_datos');

    if (!await tpvdDir.exists()) {
      await tpvdDir.create(recursive: true);
    }

    return tpvdDir;
  }

  void _setupListeners() {
    productosBox.listenable().addListener(() => notifyChange('productos'));
    categoriasBox.listenable().addListener(() => notifyChange('categorias'));
    mesasBox.listenable().addListener(() => notifyChange('mesas'));
    pedidosBox.listenable().addListener(() => notifyChange('pedidos'));
    negocioBox.listenable().addListener(() => notifyChange('negocio'));
    cajaBox.listenable().addListener(() => notifyChange('caja'));
    movimientosBox.listenable().addListener(() => notifyChange('movimientos'));
  }

  Future<void> _seedData() async {
    if (categoriasBox.isEmpty) {
      for (final cat in CategoriaProducto.defaultCategories) {
        await categoriasBox.add(cat);
      }
    }

    if (productosBox.isEmpty) {
      for (final prod in Producto.getEjemplos()) {
        await productosBox.add(prod);
      }
    }

    if (mesasBox.isEmpty) {
      for (final mesa in _getMesasIniciales()) {
        await mesasBox.add(mesa);
      }
    }

    if (negocioBox.isEmpty) {
      await negocioBox.add(DatosNegocio.ejemplo);
    }
  }

  List<Mesa> _getMesasIniciales() {
    return [
      Mesa(id: 'mesa_1', numero: 1, capacidad: 4),
      Mesa(id: 'mesa_2', numero: 2, capacidad: 4),
      Mesa(id: 'mesa_3', numero: 3, capacidad: 6),
      Mesa(id: 'mesa_4', numero: 4, capacidad: 2),
      Mesa(id: 'mesa_5', numero: 5, capacidad: 4),
      Mesa(id: 'mesa_6', numero: 6, capacidad: 8),
      Mesa(id: 'mesa_7', numero: 7, capacidad: 2),
      Mesa(id: 'mesa_8', numero: 8, capacidad: 4),
      Mesa(id: 'mesa_9', numero: 9, capacidad: 6),
      Mesa(id: 'mesa_10', numero: 10, capacidad: 4),
    ];
  }

  Future<void> close() async {
    await Hive.close();
    _changeController.close();
  }

  // Guardar preferencia de orden de productos
  Future<void> guardarOrdenProducto(String campo, String direccion) async {
    if (!this.isInitialized || !this.configBox.isOpen) return;
    await configBox.put('orden_producto_campo', campo);
    await configBox.put('orden_producto_direccion', direccion);
  }

  // Recuperar preferencia de orden de productos
  Map<String, String> obtenerOrdenProducto() {
    if (!this.isInitialized || !this.configBox.isOpen) {
      return {'campo': 'nombre', 'direccion': 'ascendente'};
    }
    final campo = configBox.get('orden_producto_campo') as String? ?? 'nombre';
    final direccion =
        configBox.get('orden_producto_direccion') as String? ?? 'ascendente';
    return {'campo': campo, 'direccion': direccion};
  }

  bool get isInitialized => _initialized;
  bool _initialized = false;

  // Reset all data and seed initial data again
  Future<void> resetAll() async {
    await productosBox.clear();
    await categoriasBox.clear();
    await mesasBox.clear();
    await pedidosBox.clear();
    await negocioBox.clear();
    await cajaBox.clear();
    await movimientosBox.clear();
    await cajerosBox.clear();
    await clientesBox.clear();
    await configBox.clear();
    // Seed initial data again
    await _seedData();
    // Notify listeners about a global reset
    notifyChange('reset');
  }
}
