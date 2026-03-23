import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../data/models/models.dart';

class PrintService {
  static Future<void> printTicket({
    required List<PedidoItem> items,
    required double total,
    required double ivaPorcentaje,
    required String metodoPago,
    required DatosNegocio negocio,
    String? mesaNumero,
    double porcentajePropina = 0,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          80 * PdfPageFormat.mm,
          double.infinity,
          marginAll: 5 * PdfPageFormat.mm,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              _buildHeader(negocio),
              pw.SizedBox(height: 6),
              _buildFechaHora(),
              if (mesaNumero != null)
                pw.Text(
                  'MESA: $mesaNumero',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 0.5),
              _buildItems(items),
              pw.Divider(thickness: 0.5),
              _buildTotals(total, ivaPorcentaje, porcentajePropina),
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                child: pw.Text(
                  'PAGO: ${metodoPago.toUpperCase()}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5),
              _buildFooter(),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static Future<void> printCocinaTicket({
    required List<PedidoItem> items,
    required String mesaNumero,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          80 * PdfPageFormat.mm,
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
      children: items
          .map(
            (item) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      '${item.cantidad}x ${item.productoNombre}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                  pw.Text(
                    '${item.subtotal.toStringAsFixed(2)}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  static pw.Widget _buildTotals(
    double total,
    double ivaPorcentaje,
    double porcentajePropina,
  ) {
    final baseImponible = total / (1 + ivaPorcentaje / 100);
    final importeIva = total - baseImponible;
    final totalFinal = total * (1 + porcentajePropina / 100);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Text('Base: ', style: const pw.TextStyle(fontSize: 9)),
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
              'IVA ${ivaPorcentaje.toStringAsFixed(0)}%: ',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.Text(
              '${importeIva.toStringAsFixed(2)} EUR',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
        if (porcentajePropina > 0)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text('Propina: ', style: const pw.TextStyle(fontSize: 9)),
              pw.Text(
                '${(total * porcentajePropina / 100).toStringAsFixed(2)} EUR',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Text(
              'TOTAL: ',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              '${totalFinal.toStringAsFixed(2)} EUR',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Text(
          'FACTURA SIMPLIFICADA',
          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text('Sin efectos fiscales', style: const pw.TextStyle(fontSize: 7)),
        pw.Text('RD 1496/2003', style: const pw.TextStyle(fontSize: 7)),
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
