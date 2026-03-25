class Cliente {
  final String id;
  final String nombre;
  final String? telefono;
  final String? email;
  final String? nif;
  final String? cid;
  final String? nie;
  final String? ciudad;
  final String? direccion;
  final String? codigoPostal;
  final String? poblacion;
  final String? observaciones;
  final DateTime fechaCreacion;
  final int totalPedidos;
  final double totalGastado;

  const Cliente({
    required this.id,
    required this.nombre,
    this.telefono,
    this.email,
    this.nif,
    this.cid,
    this.nie,
    this.ciudad,
    this.direccion,
    this.codigoPostal,
    this.poblacion,
    this.observaciones,
    required this.fechaCreacion,
    this.totalPedidos = 0,
    this.totalGastado = 0,
  });

  Cliente copyWith({
    String? id,
    String? nombre,
    String? telefono,
    String? email,
    String? nif,
    String? cid,
    String? nie,
    String? ciudad,
    String? direccion,
    String? codigoPostal,
    String? poblacion,
    String? observaciones,
    DateTime? fechaCreacion,
    int? totalPedidos,
    double? totalGastado,
  }) {
    return Cliente(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      nif: nif ?? this.nif,
      cid: cid ?? this.cid,
      nie: nie ?? this.nie,
      ciudad: ciudad ?? this.ciudad,
      direccion: direccion ?? this.direccion,
      codigoPostal: codigoPostal ?? this.codigoPostal,
      poblacion: poblacion ?? this.poblacion,
      observaciones: observaciones ?? this.observaciones,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      totalPedidos: totalPedidos ?? this.totalPedidos,
      totalGastado: totalGastado ?? this.totalGastado,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'telefono': telefono,
      'email': email,
      'nif': nif,
      'cid': cid,
      'nie': nie,
      'ciudad': ciudad,
      'direccion': direccion,
      'codigoPostal': codigoPostal,
      'poblacion': poblacion,
      'observaciones': observaciones,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'totalPedidos': totalPedidos,
      'totalGastado': totalGastado,
    };
  }

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      telefono: json['telefono'] as String?,
      email: json['email'] as String?,
      nif: json['nif'] as String?,
      cid: json['cid'] as String?,
      nie: json['nie'] as String?,
      ciudad: json['ciudad'] as String?,
      direccion: json['direccion'] as String?,
      codigoPostal: json['codigoPostal'] as String?,
      poblacion: json['poblacion'] as String?,
      observaciones: json['observaciones'] as String?,
      fechaCreacion: DateTime.parse(json['fechaCreacion'] as String),
      totalPedidos: json['totalPedidos'] as int? ?? 0,
      totalGastado: (json['totalGastado'] as num?)?.toDouble() ?? 0,
    );
  }
}
