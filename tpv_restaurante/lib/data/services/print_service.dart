import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../data/models/models.dart';

class PrintService {
  static Future<void> abrirCajon() async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: const PdfPageFormat(
            72 * PdfPageFormat.mm,
            30 * PdfPageFormat.mm,
          ),
          build: (pw.Context context) {
            return pw.Container();
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Abrir Cajón',
      );

      debugPrint('Comando abrir cajón enviado');
    } catch (e) {
      debugPrint('Error al abrir cajón: $e');
      rethrow;
    }
  }

  /// Opens a PDF preview dialog and allows the user to print from there.
  static Future<void> previewTicket({
    required BuildContext context,
    required List<PedidoItem> items,
    required double subtotal,
    required double ivaPorcentaje,
    required String metodoPago,
    required DatosNegocio negocio,
    String? mesaNumero,
    String? cajeroNombre,
    double porcentajePropina = 0,
    String? clienteNombre,
    String? clienteNif,
  }) async {
    final pdf = await _buildTicketPdf(
      items: items,
      subtotal: subtotal,
      ivaPorcentaje: ivaPorcentaje,
      metodoPago: metodoPago,
      negocio: negocio,
      mesaNumero: mesaNumero,
      cajeroNombre: cajeroNombre,
      porcentajePropina: porcentajePropina,
      clienteNombre: clienteNombre,
      clienteNif: clienteNif,
    );

    if (!context.mounted) return;
    await _showPdfPreview(context, pdf, 'Vista Previa del Ticket');
  }

  static Future<void> printTicket({
    required List<PedidoItem> items,
    required double subtotal,
    required double ivaPorcentaje,
    required String metodoPago,
    required DatosNegocio negocio,
    String? mesaNumero,
    String? cajeroNombre,
    double porcentajePropina = 0,
    String? clienteNombre,
    String? clienteNif,
  }) async {
    try {
      final pdf = await _buildTicketPdf(
        items: items,
        subtotal: subtotal,
        ivaPorcentaje: ivaPorcentaje,
        metodoPago: metodoPago,
        negocio: negocio,
        mesaNumero: mesaNumero,
        cajeroNombre: cajeroNombre,
        porcentajePropina: porcentajePropina,
        clienteNombre: clienteNombre,
        clienteNif: clienteNif,
      );
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      debugPrint('Error al imprimir ticket: $e');
    }
  }

  static Future<void> imprimirTicketAutomatico({
    required List<PedidoItem> items,
    required double subtotal,
    required double ivaPorcentaje,
    required String metodoPago,
    required DatosNegocio negocio,
    String? mesaNumero,
    String? cajeroNombre,
    double porcentajePropina = 0,
    String? clienteNombre,
    String? clienteNif,
  }) async {
    try {
      final pdf = await _buildTicketPdf(
        items: items,
        subtotal: subtotal,
        ivaPorcentaje: ivaPorcentaje,
        metodoPago: metodoPago,
        negocio: negocio,
        mesaNumero: mesaNumero,
        cajeroNombre: cajeroNombre,
        porcentajePropina: porcentajePropina,
        clienteNombre: clienteNombre,
        clienteNif: clienteNif,
      );
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      debugPrint('Error al imprimir ticket automáticamente: $e');
    }
  }

  static Future<pw.Document> _buildTicketPdf({
    required List<PedidoItem> items,
    required double subtotal,
    required double ivaPorcentaje,
    required String metodoPago,
    required DatosNegocio negocio,
    String? mesaNumero,
    String? cajeroNombre,
    double porcentajePropina = 0,
    String? clienteNombre,
    String? clienteNif,
  }) async {
    final pdf = pw.Document();
    final baseImponible = subtotal / (1 + ivaPorcentaje / 100);
    final importeIva = subtotal - baseImponible;
    final totalConIva = subtotal;
    final montoPropina = totalConIva * (porcentajePropina / 100);
    final totalFinal = totalConIva + montoPropina;

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          72 * PdfPageFormat.mm,
          double.infinity,
          marginAll: 5 * PdfPageFormat.mm,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              _buildHeader(negocio),
              pw.SizedBox(height: 5),
              _buildFechaHora(),
              if (mesaNumero != null)
                pw.Text(
                  'MESA: $mesaNumero',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              if (cajeroNombre != null)
                pw.Text(
                  'Cajero: $cajeroNombre',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5),
              _buildItems(items),
              pw.Divider(thickness: 0.5),
              _buildTotalsImproved(
                baseImponible: baseImponible,
                ivaPorcentaje: ivaPorcentaje,
                importeIva: importeIva,
                totalConIva: totalConIva,
                montoPropina: montoPropina,
                totalFinal: totalFinal,
              ),
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                child: pw.Text(
                  'METODO DE PAGO: ${metodoPago.toUpperCase()}',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 0.5),
              _buildFooter(
                clienteNombre: clienteNombre,
                clienteNif: clienteNif,
              ),
            ],
          );
        },
      ),
    );
    return pdf;
  }

  static Future<void> _showPdfPreview(
    BuildContext context,
    pw.Document pdf,
    String title,
  ) async {
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;
    final isCompact = screenH < 600 || screenW < 400;

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: EdgeInsets.all(isCompact ? 8 : 16),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isCompact ? screenW - 32 : 400,
            maxHeight: isCompact ? screenH * 0.7 : 600,
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 12 : 16,
                  vertical: isCompact ? 8 : 12,
                ),
                color: Colors.blueGrey.shade800,
                child: Row(
                  children: [
                    Icon(
                      Icons.print,
                      color: Colors.white,
                      size: isCompact ? 16 : 20,
                    ),
                    SizedBox(width: isCompact ? 8 : 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: isCompact ? 14 : 16,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: isCompact ? 18 : 20,
                      ),
                      tooltip: 'Cerrar',
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PdfPreview(
                  build: (format) => pdf.save(),
                  allowPrinting: true,
                  allowSharing: false,
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  canDebug: false,
                  pdfFileName: 'ticket.pdf',
                  actions: [],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> previewCierreCaja({
    required BuildContext context,
    required pw.Document pdf,
  }) async {
    await _showPdfPreview(context, pdf, 'Vista Previa - Cierre de Caja');
  }

  static Future<void> imprimirCierreCajaAutomatico({
    required DatosNegocio negocio,
    required dynamic caja,
  }) async {
    final pdf = await buildCierreCajaPdf(negocio, caja);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static Future<pw.Document> buildCierreCajaPdf(
    DatosNegocio negocio,
    dynamic caja,
  ) async {
    final pdf = pw.Document();
    final fechaApertura = caja.fechaApertura as DateTime;
    final fechaCierre = caja.fechaCierre as DateTime?;

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          72 * PdfPageFormat.mm,
          double.infinity,
          marginAll: 5 * PdfPageFormat.mm,
        ),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Center(
                child: pw.Text(
                  'CIERRE DE CAJA',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  negocio.nombre,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1),
              pw.Text(
                'APERTURA: ${_fmtDate(fechaApertura)}',
                style: const pw.TextStyle(fontSize: 9),
              ),
              if (fechaCierre != null)
                pw.Text(
                  'CIERRE: ${_fmtDate(fechaCierre)}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              pw.Text(
                'CAJERO: ${caja.cajeroNombre ?? "Sistema"}',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'FONDO INICIAL:',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.Text(
                    '€${caja.fondoInicial.toStringAsFixed(2)}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL VENTAS:',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.Text(
                    '€${caja.totalVentas.toStringAsFixed(2)}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
              pw.Divider(thickness: 1),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'SALDO FINAL:',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  pw.Text(
                    '€${caja.saldoCaja.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
            ],
          );
        },
      ),
    );
    return pdf;
  }

  static Future<pw.Document> buildMovimientosCajaPdf(
    DatosNegocio negocio,
    List<MovimientoCaja> movimientos,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          72 * PdfPageFormat.mm,
          double.infinity,
          marginAll: 5 * PdfPageFormat.mm,
        ),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Center(
                child: pw.Text(
                  'MOVIMIENTOS DE CAJA',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  negocio.nombre,
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1),
              pw.Text(
                _fmtDate(DateTime.now()),
                style: const pw.TextStyle(fontSize: 8),
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5),
              ...movimientos.map(
                (mov) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              mov.descripcion ?? mov.tipo.toUpperCase(),
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                            pw.Text(
                              '${_fmtDate(mov.fecha)} ${mov.metodoPago ?? ""}',
                              style: const pw.TextStyle(
                                fontSize: 6,
                                color: PdfColors.grey600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Text(
                        '${mov.tipo == "venta" || mov.tipo == "ingreso" ? "+" : "-"}€${mov.cantidad.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: mov.tipo == "venta" || mov.tipo == "ingreso"
                              ? PdfColors.green
                              : PdfColors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              pw.Divider(thickness: 1),
            ],
          );
        },
      ),
    );
    return pdf;
  }

  static Future<void> previewMovimientosCaja({
    required BuildContext context,
    required DatosNegocio negocio,
    required List<MovimientoCaja> movimientos,
  }) async {
    final pdf = await buildMovimientosCajaPdf(negocio, movimientos);
    await _showPdfPreview(context, pdf, 'Vista Previa - Movimientos');
  }

  static Future<void> imprimirMovimientosAutomatico({
    required DatosNegocio negocio,
    required List<MovimientoCaja> movimientos,
  }) async {
    for (final mov in movimientos) {
      final pdf = await _buildMovimientoTicketPdf(negocio, mov);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    }
  }

  static Future<pw.Document> _buildMovimientoTicketPdf(
    DatosNegocio negocio,
    MovimientoCaja movimiento,
  ) async {
    final pdf = pw.Document();
    final esIngreso =
        movimiento.tipo == 'venta' || movimiento.tipo == 'ingreso';

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          72 * PdfPageFormat.mm,
          100 * PdfPageFormat.mm,
          marginAll: 5 * PdfPageFormat.mm,
        ),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                negocio.nombre.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                _fmtDate(DateTime.now()),
                style: const pw.TextStyle(fontSize: 8),
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1),
              pw.Text(
                esIngreso ? 'INGRESO' : 'RETIRO',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: esIngreso ? PdfColors.green : PdfColors.red,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                movimiento.descripcion ?? movimiento.tipo.toUpperCase(),
                style: const pw.TextStyle(fontSize: 10),
              ),
              if (movimiento.metodoPago != null)
                pw.Text(
                  'Metodo: ${movimiento.metodoPago}',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 12,
                ),
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                child: pw.Text(
                  '${esIngreso ? "+" : "-"}€${movimiento.cantidad.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: esIngreso ? PdfColors.green : PdfColors.red,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1),
              pw.Text(
                'N: ${movimiento.id.substring(0, 8).toUpperCase()}',
                style: const pw.TextStyle(fontSize: 7),
              ),
            ],
          );
        },
      ),
    );
    return pdf;
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  static Future<void> printCocinaTicket({
    required List<PedidoItem> items,
    required String mesaNumero,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          72 * PdfPageFormat.mm,
          double.infinity,
          marginAll: 5 * PdfPageFormat.mm,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 2)),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'COCINA',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'MESA $mesaNumero',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              ...items.map(
                (item) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 6),
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(border: pw.Border.all()),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 20,
                        child: pw.Text(
                          '${item.cantidad}x',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              item.productoNombre,
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            if (item.notas != null && item.notas!.isNotEmpty)
                              pw.Text(
                                item.notas!,
                                style: const pw.TextStyle(
                                  fontSize: 10,
                                  color: PdfColors.orange,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static pw.Widget _buildHeader(DatosNegocio negocio) {
    return pw.Column(
      children: [
        pw.Text(
          negocio.nombre.toUpperCase(),
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        if (negocio.razonSocial != null && negocio.razonSocial!.isNotEmpty)
          pw.Text(negocio.razonSocial!, style: const pw.TextStyle(fontSize: 9)),
        pw.Text(negocio.direccion, style: const pw.TextStyle(fontSize: 9)),
        pw.Text(negocio.ciudad, style: const pw.TextStyle(fontSize: 9)),
        if (negocio.telefono != null && negocio.telefono!.isNotEmpty)
          pw.Text(
            'Tel: ${negocio.telefono}',
            style: const pw.TextStyle(fontSize: 9),
          ),
        pw.Text(
          'CIF/NIF: ${negocio.cifNif ?? 'N/A'}',
          style: const pw.TextStyle(fontSize: 9),
        ),
      ],
    );
  }

  static pw.Widget _buildFechaHora() {
    final now = DateTime.now();
    final numero =
        'T-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(7)}';
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('N: $numero', style: const pw.TextStyle(fontSize: 9)),
        pw.Text(
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
          style: const pw.TextStyle(fontSize: 9),
        ),
      ],
    );
  }

  static pw.Widget _buildItems(List<PedidoItem> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.SizedBox(
              width: 20,
              child: pw.Text(
                'C',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                'CONCEPTO',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(
              width: 45,
              child: pw.Text(
                'P.UNIT',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.SizedBox(
              width: 45,
              child: pw.Text(
                'IMP.',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
        pw.Divider(thickness: 0.5),
        ...items.map(
          (item) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 1),
            child: pw.Row(
              children: [
                pw.SizedBox(
                  width: 20,
                  child: pw.Text(
                    '${item.cantidad}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    item.productoNombre,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.SizedBox(
                  width: 45,
                  child: pw.Text(
                    item.precioUnitario.toStringAsFixed(2),
                    style: const pw.TextStyle(fontSize: 9),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.SizedBox(
                  width: 45,
                  child: pw.Text(
                    item.subtotal.toStringAsFixed(2),
                    style: const pw.TextStyle(fontSize: 9),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTotalsImproved({
    required double baseImponible,
    required double ivaPorcentaje,
    required double importeIva,
    required double totalConIva,
    required double montoPropina,
    required double totalFinal,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Text('Base imponible: ', style: const pw.TextStyle(fontSize: 9)),
            pw.Text(
              '${baseImponible.toStringAsFixed(2)} EUR',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Text(
              'IVA ${ivaPorcentaje.toStringAsFixed(0)}% (incl.): ',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.Text(
              '${importeIva.toStringAsFixed(2)} EUR',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
        if (montoPropina > 0)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text('Propina: ', style: const pw.TextStyle(fontSize: 9)),
              pw.Text(
                '${montoPropina.toStringAsFixed(2)} EUR',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
        pw.SizedBox(height: 4),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: pw.BoxDecoration(color: PdfColors.grey200),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text(
                'TOTAL: ',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                '${totalFinal.toStringAsFixed(2)} EUR',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildFooter({String? clienteNombre, String? clienteNif}) {
    return pw.Column(
      children: [
        if (clienteNombre != null && clienteNif != null) ...[
          pw.Container(
            padding: const pw.EdgeInsets.all(4),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'DATOS CLIENTE',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(clienteNombre, style: const pw.TextStyle(fontSize: 8)),
                pw.Text(
                  'NIF/CIF: $clienteNif',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'FACTURA SIMPLIFICADA',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
        ] else ...[
          pw.Text(
            'RECIBO',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            'Factura simplificada',
            style: const pw.TextStyle(fontSize: 7),
          ),
        ],
        pw.SizedBox(height: 4),
        pw.Text(
          '!Gracias por su visita!',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }
}

final printService = PrintService();
