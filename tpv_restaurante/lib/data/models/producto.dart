import 'ingrediente_producto.dart';
import 'extra_producto.dart';

class VarianteProducto {
  final String id;
  final String nombre;
  final double precio;
  final double? precioExtra;

  const VarianteProducto({
    required this.id,
    required this.nombre,
    required this.precio,
    this.precioExtra,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'precio': precio,
    'precioExtra': precioExtra,
  };

  factory VarianteProducto.fromJson(Map<String, dynamic> json) {
    return VarianteProducto(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      precio: (json['precio'] as num).toDouble(),
      precioExtra: (json['precioExtra'] as num?)?.toDouble(),
    );
  }
}

class Producto {
  final String id;
  final String nombre;
  final double precio;
  final String categoriaId;
  final String? imagenUrl;
  final bool disponible;
  final String? descripcion;
  final double? precioCompra;
  final bool esAlergenico;
  final String? codigoBarras;
  final bool esVariable;
  final List<VarianteProducto>? variantes;
  final List<IngredienteProducto>? ingredientes;
  final List<ExtraProducto>? extras;
  final int? stockActual;
  final int? stockMinimo;
  final bool controlStock;

  const Producto({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.categoriaId,
    this.imagenUrl,
    this.disponible = true,
    this.descripcion,
    this.precioCompra,
    this.esAlergenico = false,
    this.codigoBarras,
    this.esVariable = false,
    this.variantes,
    this.ingredientes,
    this.extras,
    this.stockActual,
    this.stockMinimo,
    this.controlStock = false,
  });

  bool get estaAgotado => controlStock && (stockActual ?? 0) <= 0;

  bool get stockBajo =>
      controlStock &&
      (stockActual ?? 0) > 0 &&
      (stockActual ?? 0) <= (stockMinimo ?? 5);

  double get precioExtras {
    if (extras == null) return 0;
    return extras!.fold(0, (sum, extra) => sum + extra.precio);
  }

  double get precioTotal {
    double base = precio;
    if (esVariable && variantes != null && variantes!.isNotEmpty) {
      base = variantes!.map((v) => v.precio).reduce((a, b) => a < b ? a : b);
    }
    return base + precioExtras;
  }

  Producto copyWith({
    String? id,
    String? nombre,
    double? precio,
    String? categoriaId,
    String? imagenUrl,
    bool? disponible,
    String? descripcion,
    double? precioCompra,
    bool? esAlergenico,
    String? codigoBarras,
    bool? esVariable,
    List<VarianteProducto>? variantes,
    List<IngredienteProducto>? ingredientes,
    List<ExtraProducto>? extras,
    int? stockActual,
    int? stockMinimo,
    bool? controlStock,
  }) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      precio: precio ?? this.precio,
      categoriaId: categoriaId ?? this.categoriaId,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      disponible: disponible ?? this.disponible,
      descripcion: descripcion ?? this.descripcion,
      precioCompra: precioCompra ?? this.precioCompra,
      esAlergenico: esAlergenico ?? this.esAlergenico,
      codigoBarras: codigoBarras ?? this.codigoBarras,
      esVariable: esVariable ?? this.esVariable,
      variantes: variantes ?? this.variantes,
      ingredientes: ingredientes ?? this.ingredientes,
      extras: extras ?? this.extras,
      stockActual: stockActual ?? this.stockActual,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      controlStock: controlStock ?? this.controlStock,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'precio': precio,
      'categoriaId': categoriaId,
      'imagenUrl': imagenUrl,
      'disponible': disponible,
      'descripcion': descripcion,
      'precioCompra': precioCompra,
      'esAlergenico': esAlergenico,
      'codigoBarras': codigoBarras,
      'esVariable': esVariable,
      'variantes': variantes?.map((v) => v.toJson()).toList(),
      'ingredientes': ingredientes?.map((i) => i.toJson()).toList(),
      'extras': extras?.map((e) => e.toJson()).toList(),
      'stockActual': stockActual,
      'stockMinimo': stockMinimo,
      'controlStock': controlStock,
    };
  }

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      precio: (json['precio'] as num).toDouble(),
      categoriaId: json['categoriaId'] as String,
      imagenUrl: json['imagenUrl'] as String?,
      disponible: json['disponible'] as bool? ?? true,
      descripcion: json['descripcion'] as String?,
      precioCompra: (json['precioCompra'] as num?)?.toDouble(),
      esAlergenico: json['esAlergenico'] as bool? ?? false,
      codigoBarras: json['codigoBarras'] as String?,
      esVariable: json['esVariable'] as bool? ?? false,
      variantes: (json['variantes'] as List?)
          ?.map((v) => VarianteProducto.fromJson(v as Map<String, dynamic>))
          .toList(),
      ingredientes: (json['ingredientes'] as List?)
          ?.map((i) => IngredienteProducto.fromJson(i as Map<String, dynamic>))
          .toList(),
      extras: (json['extras'] as List?)
          ?.map((e) => ExtraProducto.fromJson(e as Map<String, dynamic>))
          .toList(),
      stockActual: json['stockActual'] as int?,
      stockMinimo: json['stockMinimo'] as int?,
      controlStock: json['controlStock'] as bool? ?? false,
    );
  }

  static List<Producto> getEjemplos() {
    return [
      const Producto(
        id: 'prod_1',
        nombre: 'Espresso',
        precio: 1.50,
        categoriaId: 'cafes',
        imagenUrl:
            'https://images.unsplash.com/photo-1510707577719-ae7c14805e3a?w=400',
      ),
      const Producto(
        id: 'prod_2',
        nombre: 'Americano',
        precio: 1.80,
        categoriaId: 'cafes',
        imagenUrl:
            'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=400',
      ),
      const Producto(
        id: 'prod_3',
        nombre: 'Cappuccino',
        precio: 2.50,
        categoriaId: 'cafes',
        imagenUrl:
            'https://images.unsplash.com/photo-1572442388796-11668a67e53d?w=400',
      ),
    ];
  }
}
