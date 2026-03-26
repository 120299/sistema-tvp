import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/models.dart';

class TicketHelper {
  static Future<void> imprimirPedido(
    DatosNegocio negocio,
    Pedido pedido,
  ) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
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
  }

  static Future<void> imprimirCierreCaja(
    DatosNegocio negocio,
    Caja caja,
  ) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
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
  }
}
