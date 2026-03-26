import '../models/cajero.dart';

/// Ejemplos de usuarios para el sistema TPV Restaurante
class EjemplosUsuarios {
  /// Crear un administrador rápido
  static Cajero crearAdministrador({
    required String nombre,
    String pin = '1234',
    String? telefono,
    String? ciudad,
    String? direccion,
    String? codigoPostal,
    String? provincia,
  }) {
    return Cajero(
      id: 'admin_${DateTime.now().millisecondsSinceEpoch}',
      nombre: nombre,
      pin: pin,
      fechaCreacion: DateTime.now(),
      activo: true,
      rol: RolCajero.administrador,
      telefono: telefono,
      ciudad: ciudad,
      direccion: direccion,
      codigoPostal: codigoPostal,
      provincia: provincia,
    );
  }

  /// Crear un cajero rápido
  static Cajero crearCajero({
    required String nombre,
    String pin = '0000',
    String? telefono,
    String? ciudad,
    String? direccion,
    String? codigoPostal,
    String? provincia,
  }) {
    return Cajero(
      id: 'cajero_${DateTime.now().millisecondsSinceEpoch}',
      nombre: nombre,
      pin: pin,
      fechaCreacion: DateTime.now(),
      activo: true,
      rol: RolCajero.cajero,
      telefono: telefono,
      ciudad: ciudad,
      direccion: direccion,
      codigoPostal: codigoPostal,
      provincia: provincia,
    );
  }

  /// Lista de usuarios de ejemplo predefinidos
  static List<Cajero> crearEjemplos() {
    final ahora = DateTime.now();

    return [
      Cajero(
        id: 'admin_001',
        nombre: 'Administrador Principal',
        pin: '1234',
        fechaCreacion: ahora,
        activo: true,
        rol: RolCajero.administrador,
        telefono: '+34 600 000 001',
        direccion: 'Calle Principal, 1',
        ciudad: 'Madrid',
        codigoPostal: '28001',
        provincia: 'Madrid',
      ),
      Cajero(
        id: 'gerente_001',
        nombre: 'Gerente Restaurante',
        pin: '5678',
        fechaCreacion: ahora,
        activo: true,
        rol: RolCajero.administrador,
        telefono: '+34 600 000 003',
        direccion: 'Plaza Mayor, 5',
        ciudad: 'Valencia',
        codigoPostal: '46001',
        provincia: 'Valencia',
      ),
      Cajero(
        id: 'cajero_001',
        nombre: 'Cajero Ejemplo',
        pin: '0000',
        fechaCreacion: ahora,
        activo: true,
        rol: RolCajero.cajero,
        telefono: '+34 600 000 002',
        direccion: 'Avenida Secundaria, 25',
        ciudad: 'Barcelona',
        codigoPostal: '08001',
        provincia: 'Barcelona',
      ),
      Cajero(
        id: 'cajero_002',
        nombre: 'Juan Pérez',
        pin: '4321',
        fechaCreacion: ahora,
        activo: true,
        rol: RolCajero.cajero,
        telefono: '+34 600 000 004',
        direccion: 'Calle Nueva, 10',
        ciudad: 'Sevilla',
        codigoPostal: '41001',
        provincia: 'Sevilla',
      ),
    ];
  }

  /// Filtrar solo administradores
  static List<Cajero> filtrarAdministradores(List<Cajero> usuarios) =>
      usuarios.where((c) => c.rol == RolCajero.administrador).toList();

  /// Filtrar solo cajeros
  static List<Cajero> filtrarCajeros(List<Cajero> usuarios) =>
      usuarios.where((c) => c.rol == RolCajero.cajero).toList();
}
