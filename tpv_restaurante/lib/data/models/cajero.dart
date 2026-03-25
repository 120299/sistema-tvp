enum RolCajero { administrador, cajero }

class Cajero {
  final String id;
  final String nombre;
  final String? pin;
  final DateTime fechaCreacion;
  final bool activo;
  final RolCajero rol;
  final String? telefono;
  final String? direccion;
  final String? ciudad;
  final String? codigoPostal;
  final String? provincia;

  const Cajero({
    required this.id,
    required this.nombre,
    this.pin,
    required this.fechaCreacion,
    this.activo = true,
    this.rol = RolCajero.cajero,
    this.telefono,
    this.direccion,
    this.ciudad,
    this.codigoPostal,
    this.provincia,
  });

  bool get isAdministrador => rol == RolCajero.administrador;

  Cajero copyWith({
    String? id,
    String? nombre,
    String? pin,
    DateTime? fechaCreacion,
    bool? activo,
    RolCajero? rol,
    String? telefono,
    String? direccion,
    String? ciudad,
    String? codigoPostal,
    String? provincia,
  }) {
    return Cajero(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      pin: pin ?? this.pin,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      activo: activo ?? this.activo,
      rol: rol ?? this.rol,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
      ciudad: ciudad ?? this.ciudad,
      codigoPostal: codigoPostal ?? this.codigoPostal,
      provincia: provincia ?? this.provincia,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'pin': pin,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'activo': activo,
      'rol': rol.index,
      'telefono': telefono,
      'direccion': direccion,
      'ciudad': ciudad,
      'codigoPostal': codigoPostal,
      'provincia': provincia,
    };
  }

  factory Cajero.fromJson(Map<String, dynamic> json) {
    return Cajero(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      pin: json['pin'] as String?,
      fechaCreacion: DateTime.parse(json['fechaCreacion'] as String),
      activo: json['activo'] as bool? ?? true,
      rol: RolCajero.values[json['rol'] as int? ?? 1],
      telefono: json['telefono'] as String?,
      direccion: json['direccion'] as String?,
      ciudad: json['ciudad'] as String?,
      codigoPostal: json['codigoPostal'] as String?,
      provincia: json['provincia'] as String?,
    );
  }
}
