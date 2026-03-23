enum EstadoMesa { libre, ocupada, reservada, necesitaAtencion }

class Mesa {
  final String id;
  final int numero;
  final int capacidad;
  EstadoMesa estado;
  String? pedidoActualId;
  DateTime? horaApertura;
  double get totalAcumulado => 0;

  Mesa({
    required this.id,
    required this.numero,
    required this.capacidad,
    this.estado = EstadoMesa.libre,
    this.pedidoActualId,
    this.horaApertura,
  });

  Duration? get tiempoTranscurrido {
    if (horaApertura == null) return null;
    return DateTime.now().difference(horaApertura!);
  }

  Mesa copyWith({
    String? id,
    int? numero,
    int? capacidad,
    EstadoMesa? estado,
    String? pedidoActualId,
    DateTime? horaApertura,
  }) {
    return Mesa(
      id: id ?? this.id,
      numero: numero ?? this.numero,
      capacidad: capacidad ?? this.capacidad,
      estado: estado ?? this.estado,
      pedidoActualId: pedidoActualId ?? this.pedidoActualId,
      horaApertura: horaApertura ?? this.horaApertura,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numero': numero,
      'capacidad': capacidad,
      'estado': estado.index,
      'pedidoActualId': pedidoActualId,
      'horaApertura': horaApertura?.toIso8601String(),
    };
  }

  factory Mesa.fromJson(Map<String, dynamic> json) {
    return Mesa(
      id: json['id'] as String,
      numero: json['numero'] as int,
      capacidad: json['capacidad'] as int,
      estado: EstadoMesa.values[json['estado'] as int],
      pedidoActualId: json['pedidoActualId'] as String?,
      horaApertura: json['horaApertura'] != null
          ? DateTime.parse(json['horaApertura'] as String)
          : null,
    );
  }
}
