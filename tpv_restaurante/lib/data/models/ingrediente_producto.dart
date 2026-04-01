class IngredienteProducto {
  final String id;
  final String nombre;

  const IngredienteProducto({required this.id, required this.nombre});

  IngredienteProducto copyWith({String? id, String? nombre}) {
    return IngredienteProducto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'nombre': nombre};

  factory IngredienteProducto.fromJson(Map<String, dynamic> json) {
    return IngredienteProducto(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IngredienteProducto &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
