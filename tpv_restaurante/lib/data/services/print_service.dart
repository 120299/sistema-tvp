import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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
    String? numeroTicket,
  }) async {
    final baseImponible = total / (1 + ivaPorcentaje / 100);
    final importeIva = total - baseImponible;

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(80, double.infinity),
        margin: const pw.EdgeInsets.all(4),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              _buildHeader(negocio),
              pw.SizedBox(height: 8),
              _buildTicketInfo(numeroTicket, mesaNumero),
              pw.Divider(),
              _buildItems(items),
              pw.Divider(),
              _buildTotals(
                baseImponible: baseImponible,
                ivaPorcentaje: ivaPorcentaje,
                importeIva: importeIva,
                total: total,
                porcentajePropina: porcentajePropina,
              ),
              pw.Divider(),
              _buildMetodoPago(metodoPago),
              pw.SizedBox(height: 8),
              _buildFooter(),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Ticket${mesaNumero != null ? '_Mesa$mesaNumero' : ''}',
    );
  }

  static Future<void> printCocinaTicket({
    required List<PedidoItem> items,
    required String mesaNumero,
    required DateTime hora,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(80, double.infinity),
        margin: const pw.EdgeInsets.all(4),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 2)),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'COCINA',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'MESA $mesaNumero',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}',
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
              ...items
                  .map(
                    (item) => pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 8),
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(width: 1),
                      ),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            width: 24,
                            alignment: pw.Alignment.center,
                            child: pw.Text(
                              '${item.cantidad}x',
                              style: pw.TextStyle(
                                fontSize: 14,
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
                                    fontSize: 14,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                if (item.notas != null &&
                                    item.notas!.isNotEmpty)
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
                  )
                  .toList(),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Cocina_Mesa$mesaNumero',
    );
  }

  static pw.Widget _buildHeader(DatosNegocio negocio) {
    return pw.Column(
      children: [
        pw.Text(
          negocio.nombre,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        if (negocio.razonSocial != null && negocio.razonSocial!.isNotEmpty)
          pw.Text(negocio.razonSocial!, style: const pw.TextStyle(fontSize: 8)),
        pw.Text(
          negocio.direccion,
          style: const pw.TextStyle(fontSize: 8),
          textAlign: pw.TextAlign.center,
        ),
        pw.Text(
          negocio.ciudad,
          style: const pw.TextStyle(fontSize: 8),
          textAlign: pw.TextAlign.center,
        ),
        pw.Text(
          'CIF/NIF: ${negocio.cifNif ?? 'N/A'}',
          style: const pw.TextStyle(fontSize: 8),
        ),
      ],
    );
  }

  static pw.Widget _buildTicketInfo(String? numeroTicket, String? mesaNumero) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(numeroTicket ?? '', style: const pw.TextStyle(fontSize: 8)),
        if (mesaNumero != null)
          pw.Text(
            'Mesa: $mesaNumero',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
      ],
    );
  }

  static pw.Widget _buildItems(List<PedidoItem> items) {
    return pw.Column(
      children: items.map((item) {
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 20,
                child: pw.Text(
                  '${item.cantidad}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      item.productoNombre,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    if (item.notas != null && item.notas!.isNotEmpty)
                      pw.Text(
                        item.notas!,
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey700,
                        ),
                      ),
                  ],
                ),
              ),
              pw.Text(
                '${item.subtotal.toStringAsFixed(2)}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _buildTotals({
    required double baseImponible,
    required double ivaPorcentaje,
    required double importeIva,
    required double total,
    required double porcentajePropina,
  }) {
    final lista = <pw.Widget>[
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text('Base: ', style: const pw.TextStyle(fontSize: 9)),
          pw.Text(
            '${baseImponible.toStringAsFixed(2)} €',
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
            '${importeIva.toStringAsFixed(2)} €',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    ];

    if (porcentajePropina > 0) {
      lista.add(
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Text('Propina: ', style: const pw.TextStyle(fontSize: 9)),
            pw.Text(
              '${(total * porcentajePropina / 100).toStringAsFixed(2)} €',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
      );
    }

    lista.addAll([
      pw.SizedBox(height: 4),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(
            'TOTAL: ',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            '${total.toStringAsFixed(2)} €',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    ]);

    return pw.Column(children: lista);
  }

  static pw.Widget _buildMetodoPago(String metodoPago) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
      child: pw.Text(
        'PAGO: $metodoPago',
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Text(
          'FACTURA SIMPLIFICADA',
          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          'Sin efectos fiscales segun RD 1496/2003',
          style: const pw.TextStyle(fontSize: 6),
        ),
        pw.Text(
          '!Gracias por su visita!',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  static String generarNumeroTicket(DateTime fecha, String pedidoId) {
    final year = fecha.year.toString().substring(2);
    final month = fecha.month.toString().padLeft(2, '0');
    final day = fecha.day.toString().padLeft(2, '0');
    final suffix = pedidoId.length > 6
        ? pedidoId.substring(pedidoId.length - 6)
        : pedidoId;
    return 'T-$year$month$day-$suffix';
  }
}

final printService = PrintService();
