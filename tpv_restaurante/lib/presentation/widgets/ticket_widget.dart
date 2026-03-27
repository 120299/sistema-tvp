import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/services/print_service.dart';

class TicketWidget extends StatelessWidget {
  final List<PedidoItem> items;
  final double total;
  final double porcentajePropina;
  final double ivaPorcentaje;
  final String metodoPago;
  final DatosNegocio negocio;
  final String? mesaNumero;
  final DateTime? fechaVenta;

  const TicketWidget({
    super.key,
    required this.items,
    required this.total,
    required this.porcentajePropina,
    required this.ivaPorcentaje,
    required this.metodoPago,
    required this.negocio,
    this.mesaNumero,
    this.fechaVenta,
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
    final screenH = MediaQuery.of(context).size.height;
    final isCompact = screenH < 600;
    final ticketWidth = isCompact ? 260.0 : 280.0;
    final padding = isCompact ? 12.0 : 16.0;
    final fontSizeHeader = isCompact ? 14.0 : 16.0;
    final fontSizeSmall = isCompact ? 8.0 : 9.0;
    final fontSizeBody = isCompact ? 8.0 : 9.0;

    return Container(
      width: ticketWidth,
      padding: EdgeInsets.all(padding),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            negocio.nombre.toUpperCase(),
            style: TextStyle(
              fontSize: fontSizeHeader,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (negocio.razonSocial != null &&
              negocio.razonSocial!.isNotEmpty) ...[
            SizedBox(height: isCompact ? 1 : 2),
            Text(
              negocio.razonSocial!,
              style: TextStyle(fontSize: fontSizeSmall),
              textAlign: TextAlign.center,
            ),
          ],
          SizedBox(height: isCompact ? 2 : 4),
          Text(negocio.direccion, style: TextStyle(fontSize: fontSizeSmall)),
          Text(negocio.ciudad, style: TextStyle(fontSize: fontSizeSmall)),
          Text(
            'CIF/NIF: ${negocio.cifNif ?? "N/A"}',
            style: TextStyle(
              fontSize: fontSizeSmall,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isCompact ? 4 : 8),
          Divider(thickness: 1, height: 1),
          _buildRow(
            'Nº Ticket',
            _generateNumeroTicket(DateTime.now()),
            bold: true,
            fontSize: fontSizeBody,
            isCompact: isCompact,
          ),
          Divider(thickness: 1, height: 1),
          if (mesaNumero != null) ...[
            Text(
              'Mesa: $mesaNumero',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: fontSizeSmall,
              ),
            ),
            Divider(thickness: 1, height: 1),
          ],
          _buildItemsList(fontSize: fontSizeBody, isCompact: isCompact),
          Divider(thickness: 1, height: 1),
          _buildTotals(),
          Divider(thickness: 2, height: 2),
          _buildTotal(),
          SizedBox(height: isCompact ? 8 : 12),
          _buildFooter(),
          SizedBox(height: isCompact ? 4 : 8),
          Text(
            '------------------------------------',
            style: TextStyle(fontSize: 7, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _generateNumeroTicket(DateTime now) {
    return 'T-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(7)}';
  }

  Widget _buildRow(
    String label,
    String value, {
    bool bold = false,
    double fontSize = 9,
    bool isCompact = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isCompact ? 1 : 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList({double fontSize = 9, bool isCompact = false}) {
    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: isCompact ? 25 : 30,
              child: Text(
                'Qty',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Text(
                'Descripcion',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(
              width: isCompact ? 45 : 50,
              child: Text(
                'Importe',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        Divider(thickness: 1, height: 1),
        ...items.map(
          (item) => Padding(
            padding: EdgeInsets.symmetric(vertical: isCompact ? 1 : 2),
            child: Row(
              children: [
                SizedBox(
                  width: isCompact ? 25 : 30,
                  child: Text(
                    '${item.cantidad}',
                    style: TextStyle(fontSize: fontSize),
                  ),
                ),
                Expanded(
                  child: Text(
                    item.productoNombre,
                    style: TextStyle(fontSize: fontSize),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: isCompact ? 45 : 50,
                  child: Text(
                    '${item.subtotal.toStringAsFixed(2)} €',
                    style: TextStyle(fontSize: fontSize),
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
    return Column(
      children: [
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
        borderRadius: BorderRadius.zero,
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
    required double subtotal,
    required double porcentajePropina,
    required double ivaPorcentaje,
    required String metodoPago,
    required DatosNegocio negocio,
    String? mesaNumero,
    DateTime? fechaVenta,
    VoidCallback? onImprimir,
    VoidCallback? onCerrar,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final total = subtotal * (1 + ivaPorcentaje / 100);
        final ticketWidget = TicketWidget(
          items: items,
          total: total,
          porcentajePropina: porcentajePropina,
          ivaPorcentaje: ivaPorcentaje,
          metodoPago: metodoPago,
          negocio: negocio,
          mesaNumero: mesaNumero,
          fechaVenta: fechaVenta,
        );

        return _TicketPrintDialog(
          ticketWidget: ticketWidget,
          items: items,
          subtotal: subtotal,
          ivaPorcentaje: ivaPorcentaje,
          metodoPago: metodoPago,
          negocio: negocio,
          mesaNumero: mesaNumero,
          porcentajePropina: porcentajePropina,
          fechaVenta: fechaVenta,
          onImprimir: onImprimir,
          onCerrar: onCerrar,
        );
      },
    );
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

class _TicketPrintDialog extends StatefulWidget {
  final Widget ticketWidget;
  final List<PedidoItem> items;
  final double subtotal;
  final double ivaPorcentaje;
  final String metodoPago;
  final DatosNegocio negocio;
  final String? mesaNumero;
  final double porcentajePropina;
  final DateTime? fechaVenta;
  final VoidCallback? onImprimir;
  final VoidCallback? onCerrar;

  const _TicketPrintDialog({
    required this.ticketWidget,
    required this.items,
    required this.subtotal,
    required this.ivaPorcentaje,
    required this.metodoPago,
    required this.negocio,
    this.mesaNumero,
    required this.porcentajePropina,
    this.fechaVenta,
    this.onImprimir,
    this.onCerrar,
  });

  @override
  State<_TicketPrintDialog> createState() => _TicketPrintDialogState();
}

class _TicketPrintDialogState extends State<_TicketPrintDialog> {
  void _abrirPrevisualizacionPdf() async {
    try {
      await PrintService.previewTicket(
        context: context,
        items: widget.items,
        subtotal: widget.subtotal,
        ivaPorcentaje: widget.ivaPorcentaje,
        metodoPago: widget.metodoPago,
        negocio: widget.negocio,
        mesaNumero: widget.mesaNumero,
        porcentajePropina: widget.porcentajePropina,
        numeroTicket: widget.fechaVenta != null
            ? DateTime.now().millisecondsSinceEpoch % 10000
            : null,
        fechaVenta: widget.fechaVenta,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo previsualizar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;
    final isCompactH = screenH < 700;
    final isCompactW = screenW < 400;

    return Dialog(
      insetPadding: EdgeInsets.all(isCompactH ? 8 : 16),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isCompactW ? screenW - 16 : 360,
          maxHeight: screenH * (isCompactH ? 0.85 : 0.8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: isCompactH ? 10 : 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(0),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 22),
                  SizedBox(width: isCompactH ? 8 : 12),
                  Expanded(
                    child: Text(
                      'Venta Completada',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isCompactH ? 14 : 16,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onCerrar?.call();
                    },
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Vista Previa del Ticket',
                      style: TextStyle(
                        fontSize: isCompactH ? 12 : 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isCompactH ? 8 : 12),
                    Flexible(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SingleChildScrollView(
                            child: widget.ticketWidget,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(isCompactH ? 8 : 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onCerrar?.call();
                      },
                      icon: Icons.close,
                      label: 'Cerrar',
                      color: Colors.grey.shade600,
                      isCompact: isCompactH,
                    ),
                  ),
                  SizedBox(width: isCompactH ? 6 : 8),
                  Expanded(
                    child: _buildButton(
                      onPressed: _abrirPrevisualizacionPdf,
                      icon: Icons.visibility,
                      label: 'Ver PDF',
                      color: Colors.blue,
                      isCompact: isCompactH,
                    ),
                  ),
                  SizedBox(width: isCompactH ? 6 : 8),
                  Expanded(
                    child: _buildButton(
                      onPressed: () async {
                        try {
                          await PrintService.previewTicket(
                            context: context,
                            items: widget.items,
                            subtotal: widget.subtotal,
                            ivaPorcentaje: widget.ivaPorcentaje,
                            metodoPago: widget.metodoPago,
                            negocio: widget.negocio,
                            mesaNumero: widget.mesaNumero,
                            porcentajePropina: widget.porcentajePropina,
                            numeroTicket: widget.fechaVenta != null
                                ? DateTime.now().millisecondsSinceEpoch % 10000
                                : null,
                            fechaVenta: widget.fechaVenta,
                          );
                        } catch (e) {
                          debugPrint('Error al previsualizar ticket: $e');
                        }
                        if (context.mounted) Navigator.pop(context);
                        widget.onImprimir?.call();
                      },
                      icon: Icons.print,
                      label: 'Imprimir',
                      color: AppColors.success,
                      isCompact: isCompactH,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    required bool isCompact,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: isCompact ? 8 : 10,
            horizontal: 4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: isCompact ? 14 : 16),
              SizedBox(width: isCompact ? 4 : 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isCompact ? 10 : 12,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
