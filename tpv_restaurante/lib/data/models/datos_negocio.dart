class DatosNegocio {
  final String nombre;
  final String? slogan;
  final String direccion;
  final String ciudad;
  final String telefono;
  final String? email;
  final String? cifNif;
  final String? website;
  final double ivaPorcentaje;
  final bool imprimeLogo;
  final String? logoBase64;
  final String? razonSocial;
  final String? numeroSerie;
  final String? numeroLicencia;
  final String? actividad;
  final int contadorTicketsDiario;
  final DateTime? ultimaFechaContador;
  final bool configuracionCompletada;

  const DatosNegocio({
    this.nombre = '',
    this.slogan,
    this.direccion = '',
    this.ciudad = '',
    this.telefono = '',
    this.email,
    this.cifNif,
    this.website,
    this.ivaPorcentaje = 10.0,
    this.imprimeLogo = true,
    this.logoBase64,
    this.razonSocial,
    this.numeroSerie,
    this.numeroLicencia,
    this.actividad,
    this.contadorTicketsDiario = 0,
    this.ultimaFechaContador,
    this.configuracionCompletada = false,
  });

  bool get estaConfigurado => configuracionCompletada;

  DatosNegocio copyWith({
    String? nombre,
    String? slogan,
    String? direccion,
    String? ciudad,
    String? telefono,
    String? email,
    String? cifNif,
    String? website,
    double? ivaPorcentaje,
    bool? imprimeLogo,
    String? logoBase64,
    String? razonSocial,
    String? numeroSerie,
    String? numeroLicencia,
    String? actividad,
    int? contadorTicketsDiario,
    DateTime? ultimaFechaContador,
    bool? configuracionCompletada,
  }) {
    return DatosNegocio(
      nombre: nombre ?? this.nombre,
      slogan: slogan ?? this.slogan,
      direccion: direccion ?? this.direccion,
      ciudad: ciudad ?? this.ciudad,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      cifNif: cifNif ?? this.cifNif,
      website: website ?? this.website,
      ivaPorcentaje: ivaPorcentaje ?? this.ivaPorcentaje,
      imprimeLogo: imprimeLogo ?? this.imprimeLogo,
      logoBase64: logoBase64 ?? this.logoBase64,
      razonSocial: razonSocial ?? this.razonSocial,
      numeroSerie: numeroSerie ?? this.numeroSerie,
      numeroLicencia: numeroLicencia ?? this.numeroLicencia,
      actividad: actividad ?? this.actividad,
      contadorTicketsDiario:
          contadorTicketsDiario ?? this.contadorTicketsDiario,
      ultimaFechaContador: ultimaFechaContador ?? this.ultimaFechaContador,
      configuracionCompletada:
          configuracionCompletada ?? this.configuracionCompletada,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'slogan': slogan,
      'direccion': direccion,
      'ciudad': ciudad,
      'telefono': telefono,
      'email': email,
      'cifNif': cifNif,
      'website': website,
      'ivaPorcentaje': ivaPorcentaje,
      'imprimeLogo': imprimeLogo,
      'logoBase64': logoBase64,
      'razonSocial': razonSocial,
      'numeroSerie': numeroSerie,
      'numeroLicencia': numeroLicencia,
      'actividad': actividad,
      'contadorTicketsDiario': contadorTicketsDiario,
      'ultimaFechaContador': ultimaFechaContador?.toIso8601String(),
      'configuracionCompletada': configuracionCompletada,
    };
  }

  factory DatosNegocio.fromJson(Map<String, dynamic> json) {
    return DatosNegocio(
      nombre: json['nombre'] as String? ?? '',
      slogan: json['slogan'] as String?,
      direccion: json['direccion'] as String? ?? '',
      ciudad: json['ciudad'] as String? ?? '',
      telefono: json['telefono'] as String? ?? '',
      email: json['email'] as String?,
      cifNif: json['cifNif'] as String?,
      website: json['website'] as String?,
      ivaPorcentaje: (json['ivaPorcentaje'] as num?)?.toDouble() ?? 10.0,
      imprimeLogo: json['imprimeLogo'] as bool? ?? true,
      logoBase64: json['logoBase64'] as String?,
      razonSocial: json['razonSocial'] as String?,
      numeroSerie: json['numeroSerie'] as String?,
      numeroLicencia: json['numeroLicencia'] as String?,
      actividad: json['actividad'] as String?,
      contadorTicketsDiario: json['contadorTicketsDiario'] as int? ?? 0,
      ultimaFechaContador: json['ultimaFechaContador'] != null
          ? DateTime.parse(json['ultimaFechaContador'] as String)
          : null,
      configuracionCompletada:
          json['configuracionCompletada'] as bool? ?? false,
    );
  }
}
