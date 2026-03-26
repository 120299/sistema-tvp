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
  });

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
    );
  }

  static List<Producto> getEjemplos() {
    return [
      // Cafés
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
      const Producto(
        id: 'prod_4',
        nombre: 'Latte Macchiato',
        precio: 2.80,
        categoriaId: 'cafes',
        imagenUrl:
            'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=400',
      ),
      const Producto(
        id: 'prod_5',
        nombre: 'Cortado',
        precio: 1.70,
        categoriaId: 'cafes',
        imagenUrl:
            'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=400',
      ),
      const Producto(
        id: 'prod_6',
        nombre: 'Flat White',
        precio: 2.80,
        categoriaId: 'cafes',
        imagenUrl:
            'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=400',
      ),

      // Bebidas
      const Producto(
        id: 'prod_10',
        nombre: 'Agua Mineral',
        precio: 1.50,
        categoriaId: 'bebidas',
        imagenUrl:
            'https://images.unsplash.com/photo-1548839140-29a749e1cf4d?w=400',
      ),
      const Producto(
        id: 'prod_11',
        nombre: 'Cola',
        precio: 2.00,
        categoriaId: 'bebidas',
        imagenUrl:
            'https://images.unsplash.com/photo-1629203851122-3726ecdf080e?w=400',
      ),
      const Producto(
        id: 'prod_12',
        nombre: 'Naranja Natural',
        precio: 3.50,
        categoriaId: 'bebidas',
        imagenUrl:
            'https://images.unsplash.com/photo-1534353473418-4cfa6c56fd38?w=400',
      ),
      const Producto(
        id: 'prod_13',
        nombre: 'Limonada Casera',
        precio: 3.00,
        categoriaId: 'bebidas',
        imagenUrl:
            'https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=400',
      ),
      const Producto(
        id: 'prod_14',
        nombre: 'Tónica Premium',
        precio: 2.50,
        categoriaId: 'bebidas',
        imagenUrl:
            'https://images.unsplash.com/photo-1629203851122-3726ecdf080e?w=400',
      ),

      // Comidas
      const Producto(
        id: 'prod_20',
        nombre: 'Paella Valenciana',
        precio: 14.50,
        categoriaId: 'comidas',
        imagenUrl:
            'https://images.unsplash.com/photo-1534080564583-6be75777b70a?w=400',
        descripcion: 'Arroz con marisco, pollo y verdura',
      ),
      const Producto(
        id: 'prod_21',
        nombre: 'Bistec a la Plancha',
        precio: 16.00,
        categoriaId: 'comidas',
        imagenUrl:
            'https://images.unsplash.com/photo-1546833998-877b37c2e5c6?w=400',
        descripcion: '200g de solomillo de ternera',
      ),
      const Producto(
        id: 'prod_22',
        nombre: 'Ensalada César',
        precio: 9.50,
        categoriaId: 'comidas',
        imagenUrl:
            'https://images.unsplash.com/photo-1550304943-4f24f54ddde9?w=400',
        descripcion: 'Lechuga romana, pollo, parmesano',
      ),
      const Producto(
        id: 'prod_23',
        nombre: 'Pasta Carbonara',
        precio: 11.00,
        categoriaId: 'comidas',
        imagenUrl:
            'https://images.unsplash.com/photo-1612874742237-6526221588e3?w=400',
        descripcion: 'Espaguetis con bacon y huevo',
      ),
      const Producto(
        id: 'prod_24',
        nombre: 'Merluza al Horno',
        precio: 15.00,
        categoriaId: 'comidas',
        imagenUrl:
            'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=400',
        descripcion: 'Con patatas y pimientos',
      ),
      const Producto(
        id: 'prod_25',
        nombre: 'Tortilla Española',
        precio: 8.00,
        categoriaId: 'comidas',
        imagenUrl:
            'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400',
        descripcion: 'Patatas, cebolla y huevos',
      ),

      // Postres
      const Producto(
        id: 'prod_30',
        nombre: 'Tarta de Queso',
        precio: 5.50,
        categoriaId: 'postres',
        imagenUrl:
            'https://images.unsplash.com/photo-1565958011703-44f9829ba187?w=400',
      ),
      const Producto(
        id: 'prod_31',
        nombre: 'Flan Casero',
        precio: 4.00,
        categoriaId: 'postres',
        imagenUrl:
            'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=400',
      ),
      const Producto(
        id: 'prod_32',
        nombre: 'Helado Artesano',
        precio: 4.50,
        categoriaId: 'postres',
        imagenUrl:
            'https://images.unsplash.com/photo-1497034825429-c343d7c6a68f?w=400',
      ),
      const Producto(
        id: 'prod_33',
        nombre: 'Churros con Chocolate',
        precio: 5.00,
        categoriaId: 'postres',
        imagenUrl:
            'https://images.unsplash.com/photo-1595003593880-447d4d29c5c8?w=400',
      ),
      const Producto(
        id: 'prod_34',
        nombre: 'Tarta de Chocolate',
        precio: 6.00,
        categoriaId: 'postres',
        imagenUrl:
            'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=400',
      ),

      // Vinos
      const Producto(
        id: 'prod_40',
        nombre: 'Copa Vino Tinto',
        precio: 3.50,
        categoriaId: 'vinos',
        imagenUrl:
            'https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=400',
      ),
      const Producto(
        id: 'prod_41',
        nombre: 'Copa Vino Blanco',
        precio: 3.50,
        categoriaId: 'vinos',
        imagenUrl:
            'https://images.unsplash.com/photo-1474722883778-792e7990302f?w=400',
      ),
      const Producto(
        id: 'prod_42',
        nombre: 'Copa Rosado',
        precio: 3.50,
        categoriaId: 'vinos',
        imagenUrl:
            'https://images.unsplash.com/photo-1558001373-7b93ee48ffa0?w=400',
      ),
      const Producto(
        id: 'prod_43',
        nombre: 'Botella Rioja',
        precio: 18.00,
        categoriaId: 'vinos',
        imagenUrl:
            'https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=400',
      ),

      // Cervezas
      const Producto(
        id: 'prod_50',
        nombre: 'Caña',
        precio: 2.50,
        categoriaId: 'cervezas',
        imagenUrl:
            'https://images.unsplash.com/photo-1535958636474-b021ee887b13?w=400',
      ),
      const Producto(
        id: 'prod_51',
        nombre: 'Jarra 1L',
        precio: 5.00,
        categoriaId: 'cervezas',
        imagenUrl:
            'https://images.unsplash.com/photo-1535958636474-b021ee887b13?w=400',
      ),
      const Producto(
        id: 'prod_52',
        nombre: 'Copa Cerveza Artesana',
        precio: 4.00,
        categoriaId: 'cervezas',
        imagenUrl:
            'https://images.unsplash.com/photo-1535958636474-b021ee887b13?w=400',
      ),

      // Cócteles
      const Producto(
        id: 'prod_60',
        nombre: 'Mojito',
        precio: 7.50,
        categoriaId: 'cockteles',
        imagenUrl:
            'https://images.unsplash.com/photo-1551538827-9c037cb4f32a?w=400',
      ),
      const Producto(
        id: 'prod_61',
        nombre: 'Gin Tonic',
        precio: 7.00,
        categoriaId: 'cockteles',
        imagenUrl:
            'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?w=400',
      ),
      const Producto(
        id: 'prod_62',
        nombre: 'Piña Colada',
        precio: 8.00,
        categoriaId: 'cockteles',
        imagenUrl:
            'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?w=400',
      ),
      const Producto(
        id: 'prod_63',
        nombre: 'Cuba Libre',
        precio: 6.50,
        categoriaId: 'cockteles',
        imagenUrl:
            'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?w=400',
      ),

      // Snacks
      const Producto(
        id: 'prod_70',
        nombre: 'Croquetas Caseras',
        precio: 6.00,
        categoriaId: 'snacks',
        imagenUrl:
            'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=400',
      ),
      const Producto(
        id: 'prod_71',
        nombre: 'Patatas Bravas',
        precio: 5.00,
        categoriaId: 'snacks',
        imagenUrl:
            'https://images.unsplash.com/photo-1599490659213-e2b9527bd087?w=400',
      ),
      const Producto(
        id: 'prod_72',
        nombre: 'Jamón Ibérico',
        precio: 12.00,
        categoriaId: 'snacks',
        imagenUrl:
            'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400',
      ),
      const Producto(
        id: 'prod_73',
        nombre: 'Queso Curado',
        precio: 8.00,
        categoriaId: 'snacks',
        imagenUrl:
            'https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d?w=400',
      ),
      // Ejemplo de Producto Variable
      const Producto(
        id: 'prod_var_example',
        nombre: 'Producto Variable (Ejemplo)',
        precio: 6.50,
        categoriaId: 'variable',
        descripcion: 'Ejemplo de producto con variantes',
        esVariable: true,
        variantes: [
          VarianteProducto(id: 'var_s', nombre: 'Pequeño', precio: 6.50),
          VarianteProducto(id: 'var_m', nombre: 'Mediano', precio: 7.50),
          VarianteProducto(id: 'var_l', nombre: 'Grande', precio: 9.00),
        ],
      ),
    ];
  }
}
