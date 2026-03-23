import 'dart:js_interop';
import 'package:web/web.dart' as web;

class PrintService {
  void printTicket(String ticketHtml) {
    final printWindow = web.window.open('', 'ticket');
    if (printWindow == null) return;

    final doc = printWindow.document;
    final htmlContent =
        '''
<!DOCTYPE html>
<html>
<head>
  <title>Ticket</title>
  <style>
    @page { margin: 5mm; size: 80mm auto; }
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { 
      font-family: 'Courier New', monospace; 
      font-size: 12px; 
      width: 80mm; 
      padding: 5mm;
      margin: 0 auto;
    }
    .header { text-align: center; margin-bottom: 10px; }
    .header h1 { font-size: 16px; }
    .divider { border-top: 1px dashed #000; margin: 8px 0; }
    .row { display: flex; justify-content: space-between; margin: 3px 0; }
    .total { font-weight: bold; font-size: 14px; }
    .footer { text-align: center; margin-top: 10px; font-size: 10px; }
    .center { text-align: center; }
    .bold { font-weight: bold; }
  </style>
</head>
<body>
$ticketHtml
</body>
</html>
''';
    doc.write(htmlContent.toJS);
    doc.close();
    printWindow.print();
  }

  void printFromWidget(String widgetHtml) {
    final printWindow = web.window.open('', 'ticket');
    if (printWindow == null) return;

    final doc = printWindow.document;
    final htmlContent =
        '''
<!DOCTYPE html>
<html>
<head>
  <title>Ticket</title>
  <style>
    @page { margin: 0; size: auto; }
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { 
      font-family: 'Courier New', monospace; 
      width: 80mm; 
      margin: 0 auto;
    }
    @media print {
      body { width: 80mm; }
    }
  </style>
</head>
<body>
$widgetHtml
</body>
</html>
''';
    doc.write(htmlContent.toJS);
    doc.close();
    printWindow.print();
  }
}

final printService = PrintService();
