import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/database_service.dart';

/// Script para inicializar el sistema con datos del restaurante Kebab
class SeedData {
  final DatabaseService db;

  SeedData(this.db);

  /// Limpia todos los datos e inicializa con productos del restaurante
  Future<void> inicializarSistema() async {
    await _limpiarDatos();
    await _crearCategorias();
    await _crearProductos();
    await _crearUsuarioAdmin();
    print('✅ Sistema inicializado correctamente');
  }

  Future<void> _limpiarDatos() async {
    await db.productosBox.clear();
    await db.categoriasBox.clear();
    await db.clientesBox.clear();
    await db.cajerosBox.clear();
    await db.pedidosBox.clear();
    await db.cajaBox.clear();
    print('🗑️ Datos limpiados');
  }

  Future<void> _crearCategorias() async {
    final categorias = [
      CategoriaProducto(
        id: 'cat_kebab',
        nombre: 'Doner Kebab',
        icono: '🥙',
        color: Color(0xFFFF5722),
        orden: 0,
      ),
      CategoriaProducto(
        id: 'cat_durum',
        nombre: 'Dürüm',
        icono: '🌯',
        color: Color(0xFF795548),
        orden: 1,
      ),
      CategoriaProducto(
        id: 'cat_lahmacun',
        nombre: 'Lahmacun',
        icono: '🥙',
        color: Color(0xFF8D6E63),
        orden: 2,
      ),
      CategoriaProducto(
        id: 'cat_pizzas',
        nombre: 'Pizzas',
        icono: '🍕',
        color: Color(0xFFE91E63),
        orden: 3,
      ),
      CategoriaProducto(
        id: 'cat_combinados',
        nombre: 'Platos Combinados',
        icono: '🍽️',
        color: Color(0xFFFF9800),
        orden: 4,
      ),
      CategoriaProducto(
        id: 'cat_hamburguesas',
        nombre: 'Hamburguesas',
        icono: '🍔',
        color: Color(0xFFF44336),
        orden: 5,
      ),
      CategoriaProducto(
        id: 'cat_tacos',
        nombre: 'Tacos Franceses',
        icono: '🌮',
        color: Color(0xFFFFC107),
        orden: 6,
      ),
      CategoriaProducto(
        id: 'cat_tapas',
        nombre: 'Tapas y Complementos',
        icono: '🍟',
        color: Color(0xFFFFEB3B),
        orden: 7,
      ),
      CategoriaProducto(
        id: 'cat_ensaladas',
        nombre: 'Ensaladas',
        icono: '🥗',
        color: Color(0xFF4CAF50),
        orden: 8,
      ),
      CategoriaProducto(
        id: 'cat_menus',
        nombre: 'Menús y Ofertas',
        icono: '🎁',
        color: Color(0xFF9C27B0),
        orden: 9,
      ),
    ];

    for (final cat in categorias) {
      await db.categoriasBox.add(cat);
    }
    print('📁 ${categorias.length} categorías creadas');
  }

  Future<void> _crearProductos() async {
    // Ingredientes comunes para kebabs
    final ingredientes = 'Lechuga, tomate, col, maíz, queso y salsa';

    // ===== DONER KEBAB =====
    await _agregarProductoVariable(
      nombre: 'Pita de Ternera',
      descripcion: ingredientes,
      categoriaId: 'cat_kebab',
      precioNormal: 5.50,
      precioGrande: 6.50,
    );

    await _agregarProductoVariable(
      nombre: 'Pita de Pollo',
      descripcion: ingredientes,
      categoriaId: 'cat_kebab',
      precioNormal: 5.50,
      precioGrande: 6.50,
    );

    await _agregarProductoVariable(
      nombre: 'Pita Mixto',
      descripcion: ingredientes,
      categoriaId: 'cat_kebab',
      precioNormal: 6.00,
      precioGrande: 7.00,
    );

    await _agregarProductoVariable(
      nombre: 'Pita Solo Carne',
      descripcion: ingredientes,
      categoriaId: 'cat_kebab',
      precioNormal: 6.50,
      precioGrande: 7.50,
    );

    await _agregarProductoVariable(
      nombre: 'Pita Falafel',
      descripcion: ingredientes,
      categoriaId: 'cat_kebab',
      precioNormal: 5.50,
      precioGrande: 6.50,
    );

    // ===== DÜRÜM =====
    await _agregarProductoVariable(
      nombre: 'Dürüm de Ternera',
      descripcion: ingredientes,
      categoriaId: 'cat_durum',
      precioNormal: 6.50,
      precioGrande: 7.50,
    );

    await _agregarProductoVariable(
      nombre: 'Dürüm de Pollo',
      descripcion: ingredientes,
      categoriaId: 'cat_durum',
      precioNormal: 6.50,
      precioGrande: 7.50,
    );

    await _agregarProductoVariable(
      nombre: 'Dürüm Solo Carne',
      descripcion: ingredientes,
      categoriaId: 'cat_durum',
      precioNormal: 7.00,
      precioGrande: 8.00,
    );

    await _agregarProductoVariable(
      nombre: 'Dürüm Mixto',
      descripcion: ingredientes,
      categoriaId: 'cat_durum',
      precioNormal: 6.00,
      precioGrande: 7.50,
    );

    await _agregarProductoVariable(
      nombre: 'Dürüm Falafel',
      descripcion: ingredientes,
      categoriaId: 'cat_durum',
      precioNormal: 5.00,
      precioGrande: 6.00,
    );

    await _agregarProductoVariable(
      nombre: 'Dürüm Vegetal',
      descripcion: ingredientes,
      categoriaId: 'cat_durum',
      precioNormal: 4.00,
      precioGrande: 5.00,
    );

    await _agregarProducto(
      nombre: 'Dürüm Gratinado',
      descripcion: 'Con queso gratinado',
      categoriaId: 'cat_durum',
      precio: 7.50,
    );

    // ===== LAHMACUN =====
    await _agregarProducto(
      nombre: 'Lahmacun Pollo o Ternera',
      descripcion: 'Pizza turca tradicional',
      categoriaId: 'cat_lahmacun',
      precio: 8.00,
    );

    await _agregarProducto(
      nombre: 'Lahmacun Mixto',
      descripcion: 'Pizza turca con pollo y ternera',
      categoriaId: 'cat_lahmacun',
      precio: 8.00,
    );

    await _agregarProducto(
      nombre: 'Lahmacun Solo Carne',
      descripcion: 'Pizza turca solo carne',
      categoriaId: 'cat_lahmacun',
      precio: 9.00,
    );

    // ===== PIZZAS =====
    final pizzas = [
      ['Margarita', 8.00, 10.00, 13.50],
      ['Cuatro Quesos', 9.00, 11.50, 16.50],
      ['Hawaiana', 9.00, 11.50, 16.50],
      ['Pizza Doner Kebab', 9.00, 11.50, 16.50],
      ['Pizza Barbacoa', 9.00, 11.50, 16.50],
      ['Marinera', 9.00, 11.50, 16.50],
      ['Carbonara', 9.00, 11.50, 16.50],
      ['Pizza al Gusto (3 ingr.)', 9.00, 11.50, 16.50],
      ['Especial Kebab House', 11.00, 13.50, 18.50],
      ['Pizza de Salmón', 9.00, 11.50, 16.50],
      ['Jamón y Champiñones', 9.00, 11.50, 16.50],
      ['Pizza Vegetal', 9.00, 11.50, 16.50],
      ['Pizza BACON', 9.00, 11.50, 16.50],
      ['Pizza Valenciana', 9.00, 11.50, 16.50],
      ['Pizza Italiana', 9.00, 11.50, 16.50],
      ['Pizza Calzone', 9.00, 11.50, 16.50],
      ['Pizza Barbacoa Pollo', 9.00, 11.50, 16.50],
      ['Pizza Parma', 9.00, 11.50, 16.50],
      ['Pizza Tartana', 9.00, 11.50, 16.50],
    ];

    for (final pizza in pizzas) {
      await _agregarProductoVariableTres(
        nombre: pizza[0] as String,
        descripcion: 'Pizza italiana',
        categoriaId: 'cat_pizzas',
        precioNormal: pizza[1] as double,
        precioGrande: pizza[2] as double,
        precioFamiliar: pizza[3] as double,
      );
    }

    // ===== PLATOS COMBINADOS =====
    await _agregarProductoVariable(
      nombre: 'Pollo Ternera Mixto',
      descripcion: 'Plato combinado',
      categoriaId: 'cat_combinados',
      precioNormal: 8.00,
      precioGrande: 9.00,
    );

    await _agregarProductoVariable(
      nombre: 'Plato Normal (Pollo)',
      descripcion: 'Plato combinado',
      categoriaId: 'cat_combinados',
      precioNormal: 7.50,
      precioGrande: 8.50,
    );

    await _agregarProductoVariable(
      nombre: 'Plato Ternera',
      descripcion: 'Plato combinado',
      categoriaId: 'cat_combinados',
      precioNormal: 7.50,
      precioGrande: 8.50,
    );

    await _agregarProductoVariable(
      nombre: 'Solo Carne',
      descripcion: 'Solo carne',
      categoriaId: 'cat_combinados',
      precioNormal: 8.00,
      precioGrande: 9.00,
    );

    await _agregarProductoVariable(
      nombre: 'Plato Falafel',
      descripcion: 'Plato vegetariano',
      categoriaId: 'cat_combinados',
      precioNormal: 6.50,
      precioGrande: 7.50,
    );

    await _agregarProductoVariable(
      nombre: 'Carne con Patatas y Queso Gratinado',
      descripcion: 'Especial de la casa',
      categoriaId: 'cat_combinados',
      precioNormal: 7.00,
      precioGrande: 8.00,
    );

    await _agregarProductoVariable(
      nombre: 'Plato Especial Kebab House',
      descripcion: 'Con arroz - Especial de la casa',
      categoriaId: 'cat_combinados',
      precioNormal: 9.00,
      precioGrande: 10.50,
    );

    // ===== HAMBURGUESAS =====
    await _agregarProductoVariable(
      nombre: 'Hamburguesa Pollo o Ternera',
      descripcion: 'Hamburguesa clásica',
      categoriaId: 'cat_hamburguesas',
      precioNormal: 5.00,
      precioGrande: 6.50,
    );

    await _agregarProductoVariable(
      nombre: 'Hamburguesa Gourmet de Ternera',
      descripcion: 'Hamburguesa premium',
      categoriaId: 'cat_hamburguesas',
      precioNormal: 7.00,
      precioGrande: 8.50,
    );

    await _agregarProductoVariable(
      nombre: 'Hamburguesa Completa',
      descripcion: 'Con huevo - Hamburguesa completa',
      categoriaId: 'cat_hamburguesas',
      precioNormal: 6.00,
      precioGrande: 7.50,
    );

    // ===== TACOS FRANCESES =====
    await _agregarProductoVariable(
      nombre: 'Tacos Franceses Pechuga de Pollo Empanada',
      descripcion: 'Tacos franceses',
      categoriaId: 'cat_tacos',
      precioNormal: 7.00,
      precioGrande: 9.00,
    );

    await _agregarProductoVariable(
      nombre: 'Tacos Franceses Pollo Tandoori',
      descripcion: 'Tacos franceses',
      categoriaId: 'cat_tacos',
      precioNormal: 7.00,
      precioGrande: 9.00,
    );

    await _agregarProductoVariable(
      nombre: 'Tacos Franceses Pollo Curri',
      descripcion: 'Tacos franceses',
      categoriaId: 'cat_tacos',
      precioNormal: 7.00,
      precioGrande: 9.00,
    );

    await _agregarProductoVariable(
      nombre: 'Tacos Franceses Pollo de Kebab',
      descripcion: 'Tacos franceses',
      categoriaId: 'cat_tacos',
      precioNormal: 7.00,
      precioGrande: 9.00,
    );

    await _agregarProductoVariable(
      nombre: 'Tacos Franceses Ternera de Kebab',
      descripcion: 'Tacos franceses',
      categoriaId: 'cat_tacos',
      precioNormal: 7.00,
      precioGrande: 9.00,
    );

    await _agregarProductoVariable(
      nombre: 'Tacos Franceses Mixto de Kebab',
      descripcion: 'Tacos franceses',
      categoriaId: 'cat_tacos',
      precioNormal: 7.00,
      precioGrande: 9.00,
    );

    await _agregarProductoVariable(
      nombre: 'Tacos Franceses Solo Carne',
      descripcion: 'Tacos franceses',
      categoriaId: 'cat_tacos',
      precioNormal: 9.00,
      precioGrande: 11.00,
    );

    // ===== TAPAS Y COMPLEMENTOS =====
    await _agregarProductoTresTamanos(
      nombre: 'Patatas Fritas',
      descripcion: 'Patatas fritas caseras',
      categoriaId: 'cat_tapas',
      precioPequeno: 3.50,
      precioNormal: 0,
      precioGrande: 5.50,
    );

    await _agregarProducto(
      nombre: 'Patatas Bravas',
      descripcion: 'Con salsa brava',
      categoriaId: 'cat_tapas',
      precio: 5.50,
    );

    await _agregarProducto(
      nombre: 'Patatas Deluxe',
      descripcion: 'Patatas especiales',
      categoriaId: 'cat_tapas',
      precio: 4.50,
    );

    await _agregarProducto(
      nombre: 'Patatas con Queso Gratinado',
      descripcion: 'Con queso gratinado',
      categoriaId: 'cat_tapas',
      precio: 5.00,
    );

    await _agregarProducto(
      nombre: 'Patatas con Carne',
      descripcion: 'Patatas con carne de kebab',
      categoriaId: 'cat_tapas',
      precio: 7.00,
    );

    await _agregarProducto(
      nombre: 'Alitas de Pollo (6u)',
      descripcion: 'Alitas de pollo',
      categoriaId: 'cat_tapas',
      precio: 6.00,
    );

    await _agregarProducto(
      nombre: 'Nuggets de Pollo (6u)',
      descripcion: 'Nuggets de pollo',
      categoriaId: 'cat_tapas',
      precio: 6.00,
    );

    await _agregarProductoVariable(
      nombre: 'Samosas',
      descripcion: 'Empanadillas indias',
      categoriaId: 'cat_tapas',
      precioNormal: 4.00,
      precioGrande: 6.00,
    );

    await _agregarProducto(
      nombre: 'Box Kebab',
      descripcion: 'Caja de kebab',
      categoriaId: 'cat_tapas',
      precio: 4.00,
    );

    await _agregarProducto(
      nombre: 'Arroz Blanco',
      descripcion: 'Arroz blanco',
      categoriaId: 'cat_tapas',
      precio: 4.00,
    );

    await _agregarProductoVariable(
      nombre: 'Plato Jamón',
      descripcion: 'Jamón serrano',
      categoriaId: 'cat_tapas',
      precioNormal: 7.00,
      precioGrande: 10.00,
    );

    await _agregarProducto(
      nombre: 'Puntilla',
      descripcion: 'Puntilla frita',
      categoriaId: 'cat_tapas',
      precio: 10.00,
    );

    // ===== ENSALADAS =====
    await _agregarProducto(
      nombre: 'Ensalada Mixta',
      descripcion: 'Ensalada mixta',
      categoriaId: 'cat_ensaladas',
      precio: 5.00,
    );

    await _agregarProducto(
      nombre: 'Ensalada Queso de Cabra',
      descripcion: 'Con queso de cabra',
      categoriaId: 'cat_ensaladas',
      precio: 7.00,
    );

    // ===== MENÚS Y OFERTAS =====
    await _agregarProducto(
      nombre: 'Menú Individual Kebab',
      descripcion: 'Kebab + patatas + refresco',
      categoriaId: 'cat_menus',
      precio: 8.00,
    );

    await _agregarProducto(
      nombre: 'Menú Individual Dürüm',
      descripcion: 'Dürüm + patatas + refresco',
      categoriaId: 'cat_menus',
      precio: 9.00,
    );

    await _agregarProducto(
      nombre: 'Menú Individual Pizza',
      descripcion: 'Pizza + patatas + refresco',
      categoriaId: 'cat_menus',
      precio: 10.00,
    );

    await _agregarProducto(
      nombre: 'Menú Individual Combinado',
      descripcion: 'Plato combinado + patatas + refresco',
      categoriaId: 'cat_menus',
      precio: 11.00,
    );

    await _agregarProducto(
      nombre: 'Oferta 1: 3 Dürüms + Bebida 1.5L',
      descripcion: '3 Dürüms + Bebida 1.5L',
      categoriaId: 'cat_menus',
      precio: 21.00,
    );

    await _agregarProducto(
      nombre: 'Oferta 4: 2 Pizzas Gdes + Patatas + Bebida 2L',
      descripcion: '2 Pizzas Grandes + Patatas + Bebida 2L',
      categoriaId: 'cat_menus',
      precio: 26.00,
    );

    await _agregarProducto(
      nombre: 'Oferta 5: 1 Pizza Fam + Patatas + Bebida 1.5L',
      descripcion: '1 Pizza Familiar + Patatas + Bebida 1.5L',
      categoriaId: 'cat_menus',
      precio: 19.00,
    );

    print('🛒 Productos creados');
  }

  /// Agrega producto con variantes Normal y Grande
  Future<void> _agregarProductoVariable({
    required String nombre,
    required String descripcion,
    required String categoriaId,
    required double precioNormal,
    required double precioGrande,
  }) async {
    final producto = Producto(
      id: 'prod_${DateTime.now().millisecondsSinceEpoch}_${nombre.hashCode}',
      nombre: nombre,
      precio: 0, // Precio base en 0 para mostrar variantes
      categoriaId: categoriaId,
      descripcion: descripcion,
      disponible: true,
      esVariable: true,
      variantes: [
        VarianteProducto(
          id: 'var_normal',
          nombre: 'Normal',
          precio: precioNormal,
        ),
        VarianteProducto(
          id: 'var_grande',
          nombre: 'Grande',
          precio: precioGrande,
        ),
      ],
    );
    await db.productosBox.add(producto);
  }

  /// Agrega producto con variantes Normal, Grande y Familiar
  Future<void> _agregarProductoVariableTres({
    required String nombre,
    required String descripcion,
    required String categoriaId,
    required double precioNormal,
    required double precioGrande,
    required double precioFamiliar,
  }) async {
    final producto = Producto(
      id: 'prod_${DateTime.now().millisecondsSinceEpoch}_${nombre.hashCode}',
      nombre: nombre,
      precio: 0,
      categoriaId: categoriaId,
      descripcion: descripcion,
      disponible: true,
      esVariable: true,
      variantes: [
        VarianteProducto(
          id: 'var_normal',
          nombre: 'Normal',
          precio: precioNormal,
        ),
        VarianteProducto(
          id: 'var_grande',
          nombre: 'Grande',
          precio: precioGrande,
        ),
        VarianteProducto(
          id: 'var_familiar',
          nombre: 'Familiar',
          precio: precioFamiliar,
        ),
      ],
    );
    await db.productosBox.add(producto);
  }

  /// Agrega producto con variantes Pequeño y Grande (para patatas fritas)
  Future<void> _agregarProductoTresTamanos({
    required String nombre,
    required String descripcion,
    required String categoriaId,
    required double precioPequeno,
    required double precioNormal,
    required double precioGrande,
  }) async {
    final variantes = <VarianteProducto>[];

    if (precioPequeno > 0) {
      variantes.add(
        VarianteProducto(
          id: 'var_pequeno',
          nombre: 'Pequeño',
          precio: precioPequeno,
        ),
      );
    }
    if (precioNormal > 0) {
      variantes.add(
        VarianteProducto(
          id: 'var_normal',
          nombre: 'Normal',
          precio: precioNormal,
        ),
      );
    }
    variantes.add(
      VarianteProducto(
        id: 'var_grande',
        nombre: 'Grande',
        precio: precioGrande,
      ),
    );

    final producto = Producto(
      id: 'prod_${DateTime.now().millisecondsSinceEpoch}_${nombre.hashCode}',
      nombre: nombre,
      precio: 0,
      categoriaId: categoriaId,
      descripcion: descripcion,
      disponible: true,
      esVariable: true,
      variantes: variantes,
    );
    await db.productosBox.add(producto);
  }

  /// Agrega producto simple (sin variantes)
  Future<void> _agregarProducto({
    required String nombre,
    required String descripcion,
    required String categoriaId,
    required double precio,
  }) async {
    final producto = Producto(
      id: 'prod_${DateTime.now().millisecondsSinceEpoch}_${nombre.hashCode}',
      nombre: nombre,
      precio: precio,
      categoriaId: categoriaId,
      descripcion: descripcion,
      disponible: true,
      esVariable: false,
    );
    await db.productosBox.add(producto);
  }

  Future<void> _crearUsuarioAdmin() async {
    final admin = Cajero(
      id: 'admin_001',
      nombre: 'Administrador',
      pin: '1234',
      fechaCreacion: DateTime.now(),
      activo: true,
      rol: RolCajero.administrador,
    );
    await db.cajerosBox.add(admin);
    print('👤 Usuario administrador creado (PIN: 1234)');
  }
}
