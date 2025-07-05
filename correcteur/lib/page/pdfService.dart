import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class PdfService {
  static Future<File> generatePDF({
    required List<String> questions,
    required List<String> responses,
    required List<String> correctAnswers,
    required String studentName,
  }) async {
    final pdf = pw.Document();

    // Create a list of widgets for all content
    final contentWidgets = <pw.Widget>[
      pw.Header(
        level: 0,
        child: pw.Text(
          'Corrigé Proposé',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
      ),
      pw.SizedBox(height: 10),
      pw.Text('Élève: $studentName',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 20),
    ];

    // Add all questions and answers
    for (int i = 0; i < questions.length; i++) {
      contentWidgets.addAll([
        pw.Text('Question ${i + 1}:',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.Text(questions[i], style: const pw.TextStyle(fontSize: 12)),
        pw.SizedBox(height: 8),
        pw.Text('Réponse correcte:',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.green)),
        pw.Text(correctAnswers[i], style: const pw.TextStyle(fontSize: 12)),
        pw.SizedBox(height: 8),
        pw.Text('Correction:',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.blue)),
        pw.Text(responses[i], style: const pw.TextStyle(fontSize: 12)),
        pw.Divider(thickness: 1),
        pw.SizedBox(height: 20),
      ]);
    }

    // Add footer
    contentWidgets.add(
      pw.Text('Corrigé le: ${DateTime.now().toLocal()}',
          style: const pw.TextStyle(fontSize: 10)),
    );

    // Build pages with proper pagination
    pdf.addPage(
      pw.MultiPage(
        maxPages: 5, // Set a high limit
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) => contentWidgets,
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 20),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
        '${output.path}/corrigé_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}