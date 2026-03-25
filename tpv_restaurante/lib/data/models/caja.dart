enum EstadoCaja { abierta, cerrada }

class MovimientoCaja {
  final String id;
  final String tipo;
  final double cantidad;
  final String? descripcion;
  final String? metodoPago;
  final DateTime fecha;
  final String? pedidoId;

  const MovimientoCaja({
    required this.id,
    required this.tipo,
    required this.cantidad,
    this.descripcion,
    this.metodoPago,
    required this.fecha,
    this.pedidoId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': tipo,
      'cantidad': cantidad,
      'descripcion': descripcion,
      'metodoPago': metodoPago,
      'fecha': fecha.toIso8601String(),
      'pedidoId': pedidoId,
    };
  }

  factory MovimientoCaja.fromJson(Map<String, dynamic> json) {
    return MovimientoCaja(
      id: json['id'] as String,
      tipo: json['tipo'] as String,
      cantidad: (json['cantidad'] as num).toDouble(),
      descripcion: json['descripcion'] as String?,
      metodoPago: json['metodoPago'] as String?,
      fecha: DateTime.parse(json['fecha'] as String),
      pedidoId: json['pedidoId'] as String?,
    );
  }
}

class Caja {
  final String id;
  final DateTime fechaApertura;
  final DateTime? fechaCierre;
  final double fondoInicial;
  final double totalVentas;
  final double totalEfectivo;
  final double totalTarjeta;
  final List<MovimientoCaja> movimientos;
  final EstadoCaja estado;
  final double? saldoFinal;
  final String? cajeroId;
  final String? cajeroNombre;

  const Caja({
    required this.id,
    required this.fechaApertura,
    this.fechaCierre,
    this.fondoInicial = 0,
    this.totalVentas = 0,
    this.totalEfectivo = 0,
    this.totalTarjeta = 0,
    this.movimientos = const [],
    this.estado = EstadoCaja.abierta,
    this.saldoFinal,
    this.cajeroId,
    this.cajeroNombre,
  });

  double get saldoCaja {
    final ventasEnEfectivo = totalEfectivo;
    final otrosIngresos = movimientos
        .where((m) => m.tipo == 'ingreso')
        .fold<double>(0, (sum, m) => sum + m.cantidad);
    final retiros = movimientos
        .where((m) => m.tipo == 'retiro')
        .fold<double>(0, (sum, m) => sum + m.cantidad);
    return fondoInicial + ventasEnEfectivo + otrosIngresos - retiros;
  }

  Caja copyWith({
    String? id,
    DateTime? fechaApertura,
    DateTime? fechaCierre,
    double? fondoInicial,
    double? totalVentas,
    double? totalEfectivo,
    double? totalTarjeta,
    List<MovimientoCaja>? movimientos,
    EstadoCaja? estado,
    double? saldoFinal,
    String? cajeroId,
    String? cajeroNombre,
  }) {
    return Caja(
      id: id ?? this.id,
      fechaApertura: fechaApertura ?? this.fechaApertura,
      fechaCierre: fechaCierre ?? this.fechaCierre,
      fondoInicial: fondoInicial ?? this.fondoInicial,
      totalVentas: totalVentas ?? this.totalVentas,
      totalEfectivo: totalEfectivo ?? this.totalEfectivo,
      totalTarjeta: totalTarjeta ?? this.totalTarjeta,
      movimientos: movimientos ?? this.movimientos,
      estado: estado ?? this.estado,
      saldoFinal: saldoFinal ?? this.saldoFinal,
      cajeroId: cajeroId ?? this.cajeroId,
      cajeroNombre: cajeroNombre ?? this.cajeroNombre,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fechaApertura': fechaApertura.toIso8601String(),
      'fechaCierre': fechaCierre?.toIso8601String(),
      'fondoInicial': fondoInicial,
      'totalVentas': totalVentas,
      'totalEfectivo': totalEfectivo,
      'totalTarjeta': totalTarjeta,
      'movimientos': movimientos.map((m) => m.toJson()).toList(),
      'estado': estado.name,
      'saldoFinal': saldoFinal,
      'cajeroId': cajeroId,
      'cajeroNombre': cajeroNombre,
    };
  }

  factory Caja.fromJson(Map<String, dynamic> json) {
    return Caja(
      id: json['id'] as String,
      fechaApertura: DateTime.parse(json['fechaApertura'] as String),
      fechaCierre: json['fechaCierre'] != null
          ? DateTime.parse(json['fechaCierre'] as String)
          : null,
      fondoInicial: (json['fondoInicial'] as num?)?.toDouble() ?? 0,
      totalVentas: (json['totalVentas'] as num?)?.toDouble() ?? 0,
      totalEfectivo: (json['totalEfectivo'] as num?)?.toDouble() ?? 0,
      totalTarjeta: (json['totalTarjeta'] as num?)?.toDouble() ?? 0,
      movimientos:
          (json['movimientos'] as List?)
              ?.map((m) => MovimientoCaja.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      estado: EstadoCaja.values.firstWhere(
        (e) => e.name == json['estado'],
        orElse: () => EstadoCaja.abierta,
      ),
      saldoFinal: (json['saldoFinal'] as num?)?.toDouble(),
      cajeroId: json['cajeroId'] as String?,
      cajeroNombre: json['cajeroNombre'] as String?,
    );
  }
}
