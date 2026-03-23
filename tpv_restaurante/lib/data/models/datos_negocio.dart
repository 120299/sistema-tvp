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

  const DatosNegocio({
    required this.nombre,
    this.slogan,
    required this.direccion,
    required this.ciudad,
    required this.telefono,
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
  });

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
    };
  }

  factory DatosNegocio.fromJson(Map<String, dynamic> json) {
    return DatosNegocio(
      nombre: json['nombre'] as String? ?? 'Mi Restaurante',
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
    );
  }

  static const DatosNegocio ejemplo = DatosNegocio(
    nombre: 'Casa Paco',
    slogan: 'Sabores de siempre',
    direccion: 'Calle Mayor, 42',
    ciudad: '28001 Madrid',
    telefono: '+34 912 345 678',
    email: 'info@casapaco.es',
    cifNif: 'B-12345678',
    website: 'www.casapaco.es',
    ivaPorcentaje: 10.0,
    razonSocial: 'Casa Paco, S.L.',
    actividad: 'Restauración',
  );
}
