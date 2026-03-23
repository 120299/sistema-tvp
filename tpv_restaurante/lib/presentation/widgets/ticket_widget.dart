import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';

class TicketWidget extends StatelessWidget {
  final List<PedidoItem> items;
  final double total;
  final double porcentajePropina;
  final double ivaPorcentaje;
  final String metodoPago;
  final DatosNegocio negocio;
  final String? mesaNumero;

  const TicketWidget({
    super.key,
    required this.items,
    required this.total,
    required this.porcentajePropina,
    required this.ivaPorcentaje,
    required this.metodoPago,
    required this.negocio,
    this.mesaNumero,
  });

  String generateTicketHtml() {
    final baseImponible = total / (1 + ivaPorcentaje / 100);
    final importeIva = total - baseImponible;
    final now = DateTime.now();
    final numeroTicket = _generateNumeroTicket(now);
    final totalConPropina = total * (1 + porcentajePropina / 100);

    final itemsHtml = items
        .map(
          (item) =>
              '''
      <div class="row">
        <span>${item.cantidad}x ${item.productoNombre}</span>
        <span>${item.subtotal.toStringAsFixed(2)} €</span>
      </div>
    ''',
        )
        .join('');

    return '''
      <div class="header">
        <h1>${negocio.nombre.toUpperCase()}</h1>
        ${negocio.razonSocial != null && negocio.razonSocial!.isNotEmpty ? '<div>${negocio.razonSocial}</div>' : ''}
        <div>${negocio.direccion}</div>
        <div>${negocio.ciudad}</div>
        <div><strong>CIF/NIF: ${negocio.cifNif ?? 'N/A'}</strong></div>
      </div>
      <div class="divider"></div>
      <div class="row">
        <span>Nº: $numeroTicket</span>
        <span>${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}</span>
      </div>
      ${mesaNumero != null ? '<div class="center bold">Mesa: $mesaNumero</div>' : ''}
      <div class="divider"></div>
      $itemsHtml
      <div class="divider"></div>
      <div class="row">
        <span>Base imponible:</span>
        <span>${baseImponible.toStringAsFixed(2)} €</span>
      </div>
      <div class="row">
        <span>IVA (${ivaPorcentaje.toStringAsFixed(0)}%):</span>
        <span>${importeIva.toStringAsFixed(2)} €</span>
      </div>
      ${porcentajePropina > 0 ? '''
      <div class="row">
        <span>Propina (${porcentajePropina.toStringAsFixed(0)}%):</span>
        <span>+${(total * porcentajePropina / 100).toStringAsFixed(2)} €</span>
      </div>
      ''' : ''}
      <div class="divider"></div>
      <div class="row total">
        <span>TOTAL:</span>
        <span>${totalConPropina.toStringAsFixed(2)} €</span>
      </div>
      <div class="center">Pago: ${metodoPago.toUpperCase()}</div>
      <div class="divider"></div>
      <div class="footer">
        <div><strong>FACTURA SIMPLIFICADA</strong></div>
        <div>Sin efectos fiscales</div>
        <div>RD 1496/2003</div>
        <div>!Gracias por su visita!</div>
      </div>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            negocio.nombre.toUpperCase(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (negocio.razonSocial != null &&
              negocio.razonSocial!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              negocio.razonSocial!,
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 4),
          Text(negocio.direccion, style: const TextStyle(fontSize: 9)),
          Text(negocio.ciudad, style: const TextStyle(fontSize: 9)),
          Text(
            'CIF/NIF: ${negocio.cifNif ?? "N/A"}',
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Divider(thickness: 1),
          _buildRow(
            'Nº Ticket',
            _generateNumeroTicket(DateTime.now()),
            bold: true,
          ),
          const Divider(thickness: 1),
          if (mesaNumero != null) ...[
            Text(
              'Mesa: $mesaNumero',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
            ),
            const Divider(thickness: 1),
          ],
          _buildItemsList(),
          const Divider(thickness: 1),
          _buildTotals(),
          const Divider(thickness: 2),
          _buildTotal(),
          const SizedBox(height: 4),
          Text(
            'Pago: ${metodoPago.toUpperCase()}',
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildFooter(),
          const SizedBox(height: 8),
          const Text(
            '------------------------------------',
            style: TextStyle(fontSize: 8, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _generateNumeroTicket(DateTime now) {
    return 'T-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(7)}';
  }

  Widget _buildRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 9,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return Column(
      children: [
        Row(
          children: const [
            SizedBox(
              width: 30,
              child: Text(
                'Qty',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Text(
                'Descripcion',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              width: 50,
              child: Text(
                'Importe',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        const Divider(thickness: 1),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    '${item.cantidad}',
                    style: const TextStyle(fontSize: 9),
                  ),
                ),
                Expanded(
                  child: Text(
                    item.productoNombre,
                    style: const TextStyle(fontSize: 9),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: Text(
                    '${item.subtotal.toStringAsFixed(2)} €',
                    style: const TextStyle(fontSize: 9),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotals() {
    final baseImponible = total / (1 + ivaPorcentaje / 100);
    final importeIva = total - baseImponible;

    return Column(
      children: [
        _buildRow('Base imponible:', '${baseImponible.toStringAsFixed(2)} €'),
        _buildRow(
          'IVA ${ivaPorcentaje.toStringAsFixed(0)}%:',
          '${importeIva.toStringAsFixed(2)} €',
        ),
        if (porcentajePropina > 0)
          _buildRow(
            'Propina (${porcentajePropina.toStringAsFixed(0)}%):',
            '+${(total * porcentajePropina / 100).toStringAsFixed(2)} €',
          ),
      ],
    );
  }

  Widget _buildTotal() {
    final totalConPropina = total * (1 + porcentajePropina / 100);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'TOTAL:',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        Text(
          '${totalConPropina.toStringAsFixed(2)} €',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Column(
        children: [
          Text(
            'FACTURA SIMPLIFICADA',
            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2),
          Text('Sin efectos fiscales', style: TextStyle(fontSize: 7)),
          Text('RD 1496/2003', style: TextStyle(fontSize: 7)),
        ],
      ),
    );
  }
}

class TicketPrintHelper {
  static void showPrintDialog(
    BuildContext context, {
    required List<PedidoItem> items,
    required double total,
    required double porcentajePropina,
    required double ivaPorcentaje,
    required String metodoPago,
    required DatosNegocio negocio,
    String? mesaNumero,
    VoidCallback? onImprimir,
    VoidCallback? onCerrar,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final ticketWidget = TicketWidget(
          items: items,
          total: total,
          porcentajePropina: porcentajePropina,
          ivaPorcentaje: ivaPorcentaje,
          metodoPago: metodoPago,
          negocio: negocio,
          mesaNumero: mesaNumero,
        );

        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success),
              SizedBox(width: 12),
              Text('Venta Completada'),
            ],
          ),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Desea imprimir el ticket?'),
                const SizedBox(height: 16),
                Container(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: SingleChildScrollView(child: ticketWidget),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onCerrar?.call();
              },
              child: const Text('Cerrar sin imprimir'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _printTicket(
                  items,
                  total,
                  ivaPorcentaje,
                  metodoPago,
                  negocio,
                  mesaNumero,
                  porcentajePropina,
                );
                onImprimir?.call();
              },
              icon: const Icon(Icons.print),
              label: const Text('Imprimir Ticket'),
            ),
          ],
        );
      },
    );
  }

  static void _printTicket(
    List<PedidoItem> items,
    double total,
    double ivaPorcentaje,
    String metodoPago,
    DatosNegocio negocio,
    String? mesaNumero,
    double porcentajePropina,
  ) {
    final ticket = TicketWidget(
      items: items,
      total: total,
      ivaPorcentaje: ivaPorcentaje,
      metodoPago: metodoPago,
      negocio: negocio,
      mesaNumero: mesaNumero,
      porcentajePropina: porcentajePropina,
    );

    final html =
        '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Ticket</title>
  <style>
    @page { margin: 0; size: 80mm auto; }
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { 
      font-family: 'Courier New', monospace; 
      font-size: 12px; 
      width: 80mm; 
      padding: 5mm;
      margin: 0 auto;
    }
    .header { text-align: center; margin-bottom: 10px; }
    .header h1 { font-size: 16px; margin-bottom: 5px; }
    .divider { border-top: 1px dashed #000; margin: 8px 0; }
    .row { display: flex; justify-content: space-between; margin: 3px 0; font-size: 11px; }
    .total { font-weight: bold; font-size: 14px; }
    .footer { text-align: center; margin-top: 10px; font-size: 10px; }
    .center { text-align: center; }
    .bold { font-weight: bold; }
  </style>
</head>
<body>
${ticket.generateTicketHtml()}
</body>
</html>
''';

    _openPrintWindow(html);
  }

  static void _openPrintWindow(String htmlContent) {
    // En mobile, mostrar el ticket en pantalla para imprimir
    // En desktop/web, usar window.print()
  }

  static String generateNumeroTicket(DateTime fecha, String pedidoId) {
    final year = fecha.year.toString().substring(2);
    final month = fecha.month.toString().padLeft(2, '0');
    final day = fecha.day.toString().padLeft(2, '0');
    final suffix = pedidoId.length > 6
        ? pedidoId.substring(pedidoId.length - 6)
        : pedidoId;
    return 'T-$year$month$day-$suffix';
  }
}
