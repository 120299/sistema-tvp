import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import '../adapters/hive_adapters.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import 'image_storage_service.dart';

class DatabaseService {
  static const String _productosBox = 'productos';
  static const String _categoriasBox = 'categorias';
  static const String _mesasBox = 'mesas';
  static const String _pedidosBox = 'pedidos';
  static const String _negocioBox = 'negocio';
  static const String _configBox = 'config';
  static const String _cajaBox = 'caja';

  late Box<Producto> productosBox;
  late Box<CategoriaProducto> categoriasBox;
  late Box<Mesa> mesasBox;
  late Box<Pedido> pedidosBox;
  late Box<DatosNegocio> negocioBox;
  late Box<dynamic> configBox;
  late Box<Caja> cajaBox;

  late ProductoRepositorio productoRepositorio;
  late CategoriaRepositorio categoriaRepositorio;
  late MesaRepositorio mesaRepositorio;
  late PedidoRepositorio pedidoRepositorio;
  late CajaRepositorio cajaRepositorio;

  final StreamController<String> _changeController =
      StreamController<String>.broadcast();

  Stream<String> get onBoxChanged => _changeController.stream;

  void notifyChange(String boxName) {
    _changeController.add(boxName);
  }

  Future<void> initialize() async {
    await Hive.initFlutter();

    Hive.registerAdapter(CategoriaProductoAdapter());
    Hive.registerAdapter(ProductoAdapter());
    Hive.registerAdapter(MesaAdapter());
    Hive.registerAdapter(PedidoItemAdapter());
    Hive.registerAdapter(PedidoAdapter());
    Hive.registerAdapter(DatosNegocioAdapter());
    Hive.registerAdapter(CajaAdapter());

    productosBox = await Hive.openBox<Producto>(_productosBox);
    categoriasBox = await Hive.openBox<CategoriaProducto>(_categoriasBox);
    mesasBox = await Hive.openBox<Mesa>(_mesasBox);
    pedidosBox = await Hive.openBox<Pedido>(_pedidosBox);
    negocioBox = await Hive.openBox<DatosNegocio>(_negocioBox);
    configBox = await Hive.openBox(_configBox);
    cajaBox = await Hive.openBox<Caja>(_cajaBox);

    _setupListeners();

    await imageStorageService.init();

    productoRepositorio = ProductoRepositorio(productosBox);
    categoriaRepositorio = CategoriaRepositorio(categoriasBox);
    mesaRepositorio = MesaRepositorio(mesasBox);
    pedidoRepositorio = PedidoRepositorio(pedidosBox);
    cajaRepositorio = CajaRepositorio(cajaBox);

    await _seedData();
  }

  void _setupListeners() {
    productosBox.listenable().addListener(() => notifyChange('productos'));
    categoriasBox.listenable().addListener(() => notifyChange('categorias'));
    mesasBox.listenable().addListener(() => notifyChange('mesas'));
    pedidosBox.listenable().addListener(() => notifyChange('pedidos'));
    negocioBox.listenable().addListener(() => notifyChange('negocio'));
    cajaBox.listenable().addListener(() => notifyChange('caja'));
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

    if (cajaBox.isEmpty) {
      await cajaBox.add(
        Caja(
          id: 'caja_1',
          fechaApertura: DateTime.now(),
          estado: EstadoCaja.abierta,
        ),
      );
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
      Mesa(id: 'mesa_11', numero: 11, capacidad: 2),
      Mesa(id: 'mesa_12', numero: 12, capacidad: 4),
    ];
  }

  Future<void> close() async {
    await Hive.close();
    _changeController.close();
  }
}
