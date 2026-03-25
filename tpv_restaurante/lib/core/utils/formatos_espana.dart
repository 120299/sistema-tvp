import 'package:intl/intl.dart';

class FormatosEspana {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'es_ES',
    symbol: '€',
    decimalDigits: 2,
  );

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy', 'es_ES');
  static final DateFormat _timeFormat = DateFormat('HH:mm', 'es_ES');
  static final DateFormat _dateTimeFormat = DateFormat(
    'dd/MM/yyyy HH:mm',
    'es_ES',
  );
  static final DateFormat _dateTimeSecondsFormat = DateFormat(
    'dd/MM/yyyy HH:mm:ss',
    'es_ES',
  );

  static String formatoMoneda(double cantidad) {
    return _currencyFormat.format(cantidad);
  }

  static String formatoFecha(DateTime fecha) {
    return _dateFormat.format(fecha);
  }

  static String formatoHora(DateTime hora) {
    return _timeFormat.format(hora);
  }

  static String formatoFechaHora(DateTime fechaHora) {
    return _dateTimeFormat.format(fechaHora);
  }

  static String formatoFechaHoraCompleta(DateTime fechaHora) {
    return _dateTimeSecondsFormat.format(fechaHora);
  }

  static String formatoNumero(double numero, {int decimales = 2}) {
    final format = NumberFormat.decimalPatternDigits(
      locale: 'es_ES',
      decimalDigits: decimales,
    );
    return format.format(numero);
  }

  static bool validarNif(String nif) {
    if (nif.isEmpty) return true;

    final nifRegex = RegExp(r'^[0-9]{8}[A-Z]$');
    if (nifRegex.hasMatch(nif)) return true;

    final nieRegex = RegExp(r'^[XYZ][0-9]{7}[A-Z]$');
    if (nieRegex.hasMatch(nif)) return true;

    return false;
  }

  static bool validarCif(String cif) {
    if (cif.isEmpty) return true;

    final cifRegex = RegExp(r'^[ABCDEFGHJKLMNPQRSUVW][0-9]{8}$');
    return cifRegex.hasMatch(cif);
  }

  static bool validarNifCif(String documento) {
    return validarNif(documento) || validarCif(documento);
  }

  static String limpiarDocumento(String documento) {
    return documento.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  static double calcularBaseImponible(
    double totalConIva,
    double ivaPorcentaje,
  ) {
    return totalConIva / (1 + ivaPorcentaje / 100);
  }

  static double calcularIva(double totalConIva, double ivaPorcentaje) {
    return totalConIva - calcularBaseImponible(totalConIva, ivaPorcentaje);
  }

  static String formatoIva(double ivaPorcentaje) {
    return '${ivaPorcentaje.toStringAsFixed(0)}%';
  }

  static List<double> getTiposIvaDisponibles() {
    return [21.0, 10.0, 4.0];
  }

  static String getNombreTipoIva(double ivaPorcentaje) {
    switch (ivaPorcentaje.toInt()) {
      case 21:
        return 'IVA General (21%)';
      case 10:
        return 'IVA Reducido (10%)';
      case 4:
        return 'IVA Superreducido (4%)';
      default:
        return 'IVA ${ivaPorcentaje.toStringAsFixed(0)}%';
    }
  }
}
