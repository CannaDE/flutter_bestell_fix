import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' hide PdfDocument;
import 'package:printing/printing.dart'; // PdfPreview, share, printing



class ShowPdfPage extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const ShowPdfPage({super.key, required this.orderData});

  @override
  State<ShowPdfPage> createState() => _ShowPdfPageState();
}

class _ShowPdfPageState extends State<ShowPdfPage> {
  // No persistent controller: use PdfPreview from `printing` which works on web and mobile.

  Future<Uint8List> _generatePdfBytes() async {
    final pdf = pw.Document();

    final logoBytes = await rootBundle.load('assets/logo.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    
    final format = DateFormat('dd.MM.yyyy HH:mm');

    final orderData = widget.orderData;

    final String project = orderData['project'] ?? '';
    final String company = orderData['company'] ?? '';
    final String contactPerson = orderData['contactPerson'] ?? '';
    final String phoneNumber = orderData['phoneNumber'] ?? '';
    final String dateStr = orderData['selectedDate'] ?? '';
    final DateTime selectedDate =
        DateTime.tryParse(dateStr) ?? DateTime.now();

    // Sicherstellen, dass Produkte Map<String,String> sind
    final List<Map<String, String>> products = (orderData['products'] as List)
        .map((e) => Map<String, String>.from(
            e.map((key, value) => MapEntry(key.toString(), value.toString()))))
        .toList();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Text('Bestellung',
                  style: pw.TextStyle(
                      fontSize: 26, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(width: 400),
                  pw.Image(logoImage, width: 220),

                ]
              ),
              
              pw.SizedBox(height: 30),
              pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Bauvorhaben: $project',
                          style: pw.TextStyle(fontSize: 15)),
                      pw.SizedBox(height: 5),
                      pw.Text('Name & Telefonnummer: $contactPerson $phoneNumber',
                          style: pw.TextStyle(fontSize: 15)),
                    ],
                  ),
                  pw.SizedBox(width: 60),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Bestellung bei: $company', style: pw.TextStyle(fontSize: 15)),
                      pw.SizedBox(height: 5),
                      pw.Text(
                          'gewünschter Liefertermin: ${DateFormat('dd.MM.yyyy').format(selectedDate)}',
                          style: pw.TextStyle(fontSize: 15)),
                    ],
                  )
                ]

              ),
              
              pw.SizedBox(height: 15),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headers: ['Anzahl', 'Einheit', 'Bezeichnung', 'Bemerkung'],
                data: products
                    .map((p) => [
                          p['quantity'] ?? '',
                          p['unit'] ?? '',
                          p['name'] ?? '',
                          p['note'] ?? '',
                        ])
                    .toList(),
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 12),
                cellStyle: pw.TextStyle(fontSize: 11),
                cellAlignment: pw.Alignment.centerLeft,
              ),
              pw.Spacer(),
              pw.Center(
                child: pw.Container(
                  width: 50,
                  height: 1,
                  color: PdfColors.blue,
                )
              ),
              pw.SizedBox(height: 5),
              pw.Align(
                alignment: pw.Alignment.bottomCenter,
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Erstellt mit BestellFix',
                      style: pw.TextStyle(fontSize: 7)
                    ),
                    pw.Text(
                      '${format.format(DateTime.now())} Uhr',
                      style: pw.TextStyle(fontSize: 7)
                    ),
                  ]
                ) 
                
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bestellung ansehen'),
        backgroundColor: Colors.grey.shade200,
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded),
            tooltip: 'PDF teilen',
            onPressed: () async {
              final bytes = await _generatePdfBytes();
              await Printing.sharePdf(bytes: bytes, filename: 'bestellung.pdf');
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (PdfPageFormat format) => _generatePdfBytes(),
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: false,
        maxPageWidth: 1200,
        loadingWidget: const Center(child: CircularProgressIndicator()),
      ),
      bottomNavigationBar: Container(
        color: Colors.grey.shade200,
        padding: const EdgeInsets.all(12),
        child: const Text(
          '© 2024 BestellFix\r\n Made with ❤️ by WebExpanded.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ),
    );
  }

}
