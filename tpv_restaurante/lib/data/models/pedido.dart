import 'extra_producto.dart';

enum EstadoPedido { abierto, cerrado, cancelado }

extension EstadoPedidoExtension on EstadoPedido {
  String get nombre {
    switch (this) {
      case EstadoPedido.abierto:
        return 'Abierto';
      case EstadoPedido.cerrado:
        return 'Cerrado';
      case EstadoPedido.cancelado:
        return 'Cancelado';
    }
  }
}

class PedidoItem {
  final String id;
  final String productoId;
  final String? varianteId;
  final String productoNombre;
  final int cantidad;
  final double precioUnitario;
  final String? notas;
  final List<String>? ingredientesQuitados;
  final List<ExtraProducto>? extrasSeleccionados;

  const PedidoItem({
    required this.id,
    required this.productoId,
    this.varianteId,
    required this.productoNombre,
    required this.cantidad,
    required this.precioUnitario,
    this.notas,
    this.ingredientesQuitados,
    this.extrasSeleccionados,
  });

  double get precioExtras {
    if (extrasSeleccionados == null) return 0;
    return extrasSeleccionados!.fold(0, (sum, extra) => sum + extra.precio);
  }

  double get subtotal => cantidad * (precioUnitario + precioExtras);

  String get descripcionModificaciones {
    final parts = <String>[];

    if (ingredientesQuitados != null && ingredientesQuitados!.isNotEmpty) {
      parts.add('Sin ${ingredientesQuitados!.join(", ")}');
    }

    if (extrasSeleccionados != null && extrasSeleccionados!.isNotEmpty) {
      for (final extra in extrasSeleccionados!) {
        parts.add('+${extra.nombre}');
      }
    }

    return parts.join(' | ');
  }

  PedidoItem copyWith({
    String? id,
    String? productoId,
    String? varianteId,
    String? productoNombre,
    int? cantidad,
    double? precioUnitario,
    String? notas,
    List<String>? ingredientesQuitados,
    List<ExtraProducto>? extrasSeleccionados,
  }) {
    return PedidoItem(
      id: id ?? this.id,
      productoId: productoId ?? this.productoId,
      varianteId: varianteId ?? this.varianteId,
      productoNombre: productoNombre ?? this.productoNombre,
      cantidad: cantidad ?? this.cantidad,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      notas: notas ?? this.notas,
      ingredientesQuitados: ingredientesQuitados ?? this.ingredientesQuitados,
      extrasSeleccionados: extrasSeleccionados ?? this.extrasSeleccionados,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productoId': productoId,
      'varianteId': varianteId,
      'productoNombre': productoNombre,
      'cantidad': cantidad,
      'precioUnitario': precioUnitario,
      'notas': notas,
      'ingredientesQuitados': ingredientesQuitados,
      'extrasSeleccionados': extrasSeleccionados
          ?.map((e) => e.toJson())
          .toList(),
    };
  }

  factory PedidoItem.fromJson(Map<String, dynamic> json) {
    return PedidoItem(
      id: json['id'] as String,
      productoId: json['productoId'] as String,
      varianteId: json['varianteId'] as String?,
      productoNombre: json['productoNombre'] as String,
      cantidad: json['cantidad'] as int,
      precioUnitario: (json['precioUnitario'] as num).toDouble(),
      notas: json['notas'] as String?,
      ingredientesQuitados: (json['ingredientesQuitados'] as List?)
          ?.map((e) => e as String)
          .toList(),
      extrasSeleccionados: (json['extrasSeleccionados'] as List?)
          ?.map((e) => ExtraProducto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Pedido {
  final String id;
  final String mesaId;
  final List<PedidoItem> items;
  EstadoPedido estado;
  final String? mesero;
  final DateTime horaApertura;
  DateTime? horaCierre;
  String? metodoPago;
  double porcentajePropina;
  double descuento;
  int? numeroPersonas;
  final String? cajeroId;
  final String? cajeroNombre;
  final String? clienteId;
  final String? clienteNombre;
  final String? cajaId;
  int? numeroTicket;

  Pedido({
    required this.id,
    required this.mesaId,
    List<PedidoItem>? items,
    this.estado = EstadoPedido.abierto,
    this.mesero,
    DateTime? horaApertura,
    this.horaCierre,
    this.metodoPago,
    this.porcentajePropina = 0,
    this.descuento = 0,
    this.numeroPersonas,
    this.cajeroId,
    this.cajeroNombre,
    this.clienteId,
    this.clienteNombre,
    this.cajaId,
    this.numeroTicket,
  }) : items = items ?? [],
       horaApertura = horaApertura ?? DateTime.now();

  double get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);
  double get montoPropina => subtotal * (porcentajePropina / 100);
  double get montoDescuento => descuento;
  double get subtotalConDescuento => subtotal - montoDescuento;
  double get impuesto => 0;
  double get total => subtotalConDescuento + montoPropina;
  double get totalPorPersona => numeroPersonas != null && numeroPersonas! > 0
      ? total / numeroPersonas!
      : total;

  Duration get tiempoTranscurrido => DateTime.now().difference(horaApertura);

  Pedido copyWith({
    String? id,
    String? mesaId,
    List<PedidoItem>? items,
    EstadoPedido? estado,
    String? mesero,
    DateTime? horaApertura,
    DateTime? horaCierre,
    String? metodoPago,
    double? porcentajePropina,
    double? descuento,
    int? numeroPersonas,
    String? cajeroId,
    String? cajeroNombre,
    String? clienteId,
    String? clienteNombre,
    String? cajaId,
    int? numeroTicket,
  }) {
    return Pedido(
      id: id ?? this.id,
      mesaId: mesaId ?? this.mesaId,
      items: items ?? this.items,
      estado: estado ?? this.estado,
      mesero: mesero ?? this.mesero,
      horaApertura: horaApertura ?? this.horaApertura,
      horaCierre: horaCierre ?? this.horaCierre,
      metodoPago: metodoPago ?? this.metodoPago,
      porcentajePropina: porcentajePropina ?? this.porcentajePropina,
      descuento: descuento ?? this.descuento,
      numeroPersonas: numeroPersonas ?? this.numeroPersonas,
      cajeroId: cajeroId ?? this.cajeroId,
      cajeroNombre: cajeroNombre ?? this.cajeroNombre,
      clienteId: clienteId ?? this.clienteId,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      cajaId: cajaId ?? this.cajaId,
      numeroTicket: numeroTicket ?? this.numeroTicket,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mesaId': mesaId,
      'items': items.map((e) => e.toJson()).toList(),
      'estado': estado.index,
      'mesero': mesero,
      'horaApertura': horaApertura.toIso8601String(),
      'horaCierre': horaCierre?.toIso8601String(),
      'metodoPago': metodoPago,
      'porcentajePropina': porcentajePropina,
      'descuento': descuento,
      'numeroPersonas': numeroPersonas,
      'cajeroId': cajeroId,
      'cajeroNombre': cajeroNombre,
      'clienteId': clienteId,
      'clienteNombre': clienteNombre,
      'cajaId': cajaId,
      'numeroTicket': numeroTicket,
    };
  }

  factory Pedido.fromJson(Map<String, dynamic> json) {
    return Pedido(
      id: json['id'] as String,
      mesaId: json['mesaId'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => PedidoItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      estado: EstadoPedido.values[json['estado'] as int],
      mesero: json['mesero'] as String?,
      horaApertura: DateTime.parse(json['horaApertura'] as String),
      horaCierre: json['horaCierre'] != null
          ? DateTime.parse(json['horaCierre'] as String)
          : null,
      metodoPago: json['metodoPago'] as String?,
      porcentajePropina: (json['porcentajePropina'] as num?)?.toDouble() ?? 0,
      descuento: (json['descuento'] as num?)?.toDouble() ?? 0,
      numeroPersonas: json['numeroPersonas'] as int?,
      cajeroId: json['cajeroId'] as String?,
      cajeroNombre: json['cajeroNombre'] as String?,
      clienteId: json['clienteId'] as String?,
      cajaId: json['cajaId'] as String?,
      numeroTicket: json['numeroTicket'] as int?,
    );
  }
}
