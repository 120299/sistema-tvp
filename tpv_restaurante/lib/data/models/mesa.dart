enum EstadoMesa { libre, ocupada, reservada, necesitaAtencion }

class Mesa {
  final String id;
  final int numero;
  final String? nombre;
  final int capacidad;
  EstadoMesa estado;
  String? pedidoActualId;
  DateTime? horaApertura;
  DateTime? fechaReserva;
  double get totalAcumulado => 0;

  Mesa({
    required this.id,
    required this.numero,
    this.nombre,
    required this.capacidad,
    this.estado = EstadoMesa.libre,
    this.pedidoActualId,
    this.horaApertura,
    this.fechaReserva,
  });

  String get nombreMostrar => nombre ?? 'Barra $numero';

  Duration? get tiempoTranscurrido {
    if (horaApertura == null) return null;
    return DateTime.now().difference(horaApertura!);
  }

  Mesa copyWith({
    String? id,
    int? numero,
    String? nombre,
    int? capacidad,
    EstadoMesa? estado,
    String? pedidoActualId,
    DateTime? horaApertura,
    DateTime? fechaReserva,
  }) {
    return Mesa(
      id: id ?? this.id,
      numero: numero ?? this.numero,
      nombre: nombre ?? this.nombre,
      capacidad: capacidad ?? this.capacidad,
      estado: estado ?? this.estado,
      pedidoActualId: pedidoActualId ?? this.pedidoActualId,
      horaApertura: horaApertura ?? this.horaApertura,
      fechaReserva: fechaReserva ?? this.fechaReserva,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numero': numero,
      'nombre': nombre,
      'capacidad': capacidad,
      'estado': estado.index,
      'pedidoActualId': pedidoActualId,
      'horaApertura': horaApertura?.toIso8601String(),
      'fechaReserva': fechaReserva?.toIso8601String(),
    };
  }

  factory Mesa.fromJson(Map<String, dynamic> json) {
    return Mesa(
      id: json['id'] as String,
      numero: json['numero'] as int,
      nombre: json['nombre'] as String?,
      capacidad: json['capacidad'] as int,
      estado: EstadoMesa.values[json['estado'] as int],
      pedidoActualId: json['pedidoActualId'] as String?,
      horaApertura: json['horaApertura'] != null
          ? DateTime.parse(json['horaApertura'] as String)
          : null,
      fechaReserva: json['fechaReserva'] != null
          ? DateTime.parse(json['fechaReserva'] as String)
          : null,
    );
  }
}
