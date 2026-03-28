import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/models.dart';
import '../../data/services/print_service.dart';

class TicketHelper {
  static Future<void> imprimirPedido(
    DatosNegocio negocio,
    Pedido pedido, [
    int? numeroTicket,
  ]) async {
    try {
      final numero = numeroTicket ?? pedido.numeroTicket;
      final doc = pw.Document();

      doc.addPage(
        pw.Page(
          pageFormat: const PdfPageFormat(
            72 * PdfPageFormat.mm,
            double.infinity,
            marginAll: 5 * PdfPageFormat.mm,
          ),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    negocio.nombre.toUpperCase(),
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (negocio.slogan != null)
                  pw.Center(
                    child: pw.Text(
                      negocio.slogan!,
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ),
                pw.Center(
                  child: pw.Text(
                    negocio.direccion,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    negocio.ciudad,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    'Tel: ${negocio.telefono}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
                if (negocio.cifNif != null)
                  pw.Center(
                    child: pw.Text(
                      'CIF: ${negocio.cifNif!}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ),
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 5),
                if (numero != null)
                  pw.Text(
                    'TICKET: T-${_formatFechaShort(pedido.horaApertura)}-${numero.toString().padLeft(4, '0')}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                pw.Text(
                  'PEDIDO: ${pedido.id.substring(0, 8).toUpperCase()}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
                pw.Text(
                  'FECHA: ${DateFormat('dd/MM/yyyy HH:mm').format(pedido.horaApertura)}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
                if (pedido.clienteNombre != null)
                  pw.Text(
                    'CLIENTE: ${pedido.clienteNombre}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                if (pedido.cajeroNombre != null)
                  pw.Text(
                    'CAJERO: ${pedido.cajeroNombre}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 0.5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'CONCEPTO',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                    pw.Text(
                      'TOTAL',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
                pw.Divider(thickness: 0.5),
                ...pedido.items.map(
                  (item) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            '${item.cantidad}x ${item.productoNombre}',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Text(
                          '${(item.cantidad * item.precioUnitario).toStringAsFixed(2)} EUR',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 1),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOTAL',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    pw.Text(
                      '${pedido.total.toStringAsFixed(2)} EUR',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.Text(
                    'GRACIAS POR SU VISITA',
                    style: pw.TextStyle(
                      fontStyle: pw.FontStyle.italic,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
      );
    } catch (e) {
      debugPrint('Error al imprimir pedido: $e');
    }
  }

  static Future<void> previewPedido(
    BuildContext context,
    DatosNegocio negocio,
    Pedido pedido, [
    int? numeroTicket,
  ]) async {
    try {
      final numero = numeroTicket ?? pedido.numeroTicket;
      final doc = pw.Document();

      doc.addPage(
        pw.Page(
          pageFormat: const PdfPageFormat(
            72 * PdfPageFormat.mm,
            double.infinity,
            marginAll: 5 * PdfPageFormat.mm,
          ),
          build: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    negocio.nombre.toUpperCase(),
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (negocio.slogan != null)
                  pw.Center(
                    child: pw.Text(
                      negocio.slogan!,
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ),
                pw.Center(
                  child: pw.Text(
                    negocio.direccion,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    negocio.ciudad,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    'Tel: ${negocio.telefono}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
                if (negocio.cifNif != null)
                  pw.Center(
                    child: pw.Text(
                      'CIF: ${negocio.cifNif!}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ),
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 5),
                if (numero != null)
                  pw.Text(
                    'TICKET: T-${_formatFechaShort(pedido.horaApertura)}-${numero.toString().padLeft(4, '0')}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                pw.Text(
                  'PEDIDO: ${pedido.id.substring(0, 8).toUpperCase()}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
                pw.Text(
                  'FECHA: ${DateFormat('dd/MM/yyyy HH:mm').format(pedido.horaApertura)}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
                if (pedido.clienteNombre != null)
                  pw.Text(
                    'CLIENTE: ${pedido.clienteNombre}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                if (pedido.cajeroNombre != null)
                  pw.Text(
                    'CAJERO: ${pedido.cajeroNombre}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 0.5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'CONCEPTO',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                    pw.Text(
                      'TOTAL',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
                pw.Divider(thickness: 0.5),
                ...pedido.items.map(
                  (item) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            '${item.cantidad}x ${item.productoNombre}',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Text(
                          '${(item.cantidad * item.precioUnitario).toStringAsFixed(2)} EUR',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 1),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOTAL',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    pw.Text(
                      '${pedido.total.toStringAsFixed(2)} EUR',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.Text(
                    'GRACIAS POR SU VISITA',
                    style: pw.TextStyle(
                      fontStyle: pw.FontStyle.italic,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      await PrintService.mostrarPdfPreview(
        context: context,
        pdf: doc,
        titulo: 'Ticket Pedido',
      );
    } catch (e) {
      debugPrint('Error al mostrar pedido: $e');
    }
  }

  static Future<void> imprimirCierreCaja(
    DatosNegocio negocio,
    Caja caja,
  ) async {
    try {
      final doc = pw.Document();

      doc.addPage(
        pw.Page(
          pageFormat: const PdfPageFormat(
            72 * PdfPageFormat.mm,
            double.infinity,
            marginAll: 5 * PdfPageFormat.mm,
          ),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
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
                  'APERTURA: ${DateFormat('dd/MM/yyyy HH:mm').format(caja.fechaApertura)}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
                if (caja.fechaCierre != null)
                  pw.Text(
                    'CIERRE: ${DateFormat('dd/MM/yyyy HH:mm').format(caja.fechaCierre!)}',
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
                      '${caja.fondoInicial.toStringAsFixed(2)} EUR',
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
                      '${caja.totalVentas.toStringAsFixed(2)} EUR',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 10),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            ' - EFECTIVO:',
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.Text(
                            '${caja.totalEfectivo.toStringAsFixed(2)} EUR',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            ' - TARJETA:',
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.Text(
                            '${caja.totalTarjeta.toStringAsFixed(2)} EUR',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ],
                      ),
                    ],
                  ),
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
                      '${caja.saldoCaja.toStringAsFixed(2)} EUR',
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

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
      );
    } catch (e) {
      debugPrint('Error al imprimir cierre de caja: $e');
    }
  }

  static String _formatFechaShort(DateTime d) {
    return '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
  }
}
