class ExtraProducto {
  final String id;
  final String nombre;
  final double precio;

  const ExtraProducto({
    required this.id,
    required this.nombre,
    required this.precio,
  });

  ExtraProducto copyWith({String? id, String? nombre, double? precio}) {
    return ExtraProducto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      precio: precio ?? this.precio,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'precio': precio,
  };

  factory ExtraProducto.fromJson(Map<String, dynamic> json) {
    return ExtraProducto(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      precio: (json['precio'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExtraProducto &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
