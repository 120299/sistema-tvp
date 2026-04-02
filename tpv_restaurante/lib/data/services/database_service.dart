import 'dart:async';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';
import '../adapters/hive_adapters.dart';
import '../repositories/repositories.dart';
import 'image_storage_service.dart';
import 'ingredientes_extras_service.dart';
import 'migration_service.dart';

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
  late IngredientesExtrasService ingredientesExtrasService;

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
    Hive.registerAdapter(IngredienteProductoAdapter());
    Hive.registerAdapter(ExtraProductoAdapter());
    Hive.registerAdapter(ProductoAdapter());
    Hive.registerAdapter(MesaAdapter());
    Hive.registerAdapter(PedidoItemAdapter());
    Hive.registerAdapter(PedidoAdapter());
    Hive.registerAdapter(DatosNegocioAdapter());
    Hive.registerAdapter(CajaAdapter());
    Hive.registerAdapter(MovimientoCajaAdapter());
    Hive.registerAdapter(CajeroAdapter());
    Hive.registerAdapter(ClienteAdapter());

    try {
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
    } catch (e) {
      debugPrint('Error abriendo cajas Hive, intentando migración...');
      try {
        final targetDir = await _getDataDirectory();
        await MigrationService.migrateFromOldData(
          'assets/tpv_datos',
          targetDir.path,
        );
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
      } catch (e2) {
        debugPrint('Error en migración: $e2');
        rethrow;
      }
    }

    _setupListeners();

    await imageStorageService.init();

    productoRepositorio = ProductoRepositorio(productosBox);
    categoriaRepositorio = CategoriaRepositorio(categoriasBox);
    mesaRepositorio = MesaRepositorio(mesasBox);
    pedidoRepositorio = PedidoRepositorio(pedidosBox);
    cajaRepositorio = CajaRepositorio(cajaBox);
    movimientoRepositorio = MovimientoRepositorio(movimientosBox);

    final ingredientesExtrasSvc = IngredientesExtrasService();
    await ingredientesExtrasSvc.init();
    ingredientesExtrasService = ingredientesExtrasSvc;

    _initialized = true;
  }

  bool get isFirstRun => negocioBox.isEmpty;

  Future<Directory> _getDataDirectory() async {
    String basePath;

    if (kIsWeb) {
      basePath = (await getApplicationDocumentsDirectory()).path;
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      final exePath = Platform.resolvedExecutable;
      final exeDir = exePath.substring(
        0,
        exePath.lastIndexOf(Platform.pathSeparator),
      );
      final exeName = exePath.split(Platform.pathSeparator).last;

      if (exeName.contains('tpv_restaurante')) {
        basePath = exeDir;
      } else {
        basePath = Directory.current.path;
      }
    } else {
      basePath = (await getApplicationDocumentsDirectory()).path;
    }

    final tpvdDir = Directory('$basePath/tpv_datos');

    if (!await tpvdDir.exists()) {
      await tpvdDir.create(recursive: true);
      await _extractDefaultData(tpvdDir);
    }

    return tpvdDir;
  }

  Future<void> _extractDefaultData(Directory targetDir) async {
    try {
      final assetDir = Directory('assets/tpv_datos');
      if (await assetDir.exists()) {
        await for (final entity in assetDir.list()) {
          if (entity is File) {
            final fileName = entity.path.split('/').last;
            if (fileName.endsWith('.hive') && !fileName.endsWith('.lock')) {
              final targetFile = File('${targetDir.path}/$fileName');
              await entity.copy(targetFile.path);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error extracting default data: $e');
    }
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

    // Obtener datos del negocio antes de borrar para preservar configuración fiscal
    final negocioActual = negocioBox.getAt(0);
    final DatosNegocio negocioDefault =
        negocioActual?.copyWith(
          contadorTicketsDiario: 0,
          ultimaFechaContador: null,
        ) ??
        const DatosNegocio();

    // Actualizar negocio con configuración fiscal preservada
    if (negocioBox.isEmpty) {
      await negocioBox.add(negocioDefault);
    } else {
      await negocioBox.putAt(0, negocioDefault);
    }

    // Notify listeners about a global reset
    notifyChange('reset');
  }
}
