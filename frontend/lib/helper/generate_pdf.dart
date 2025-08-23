import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';


Future<String?> generateAndSavePdf(List<Map<String, String>> data) async {
  try {
  final pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      build: (context) => [
        pw.Text('Detected Results', style: pw.TextStyle(fontSize: 20)),
        pw.SizedBox(height: 20),
        for (final item in data)
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey),
              borderRadius: pw.BorderRadius.circular(5),
            ),
            padding: const pw.EdgeInsets.all(8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: item.entries
                  .map((e) => pw.Text('${e.key}: ${e.value}'))
                  .toList(),
            ),
          ),
      ],
    ),
  );

  Directory directory;
  if (Platform.isAndroid) {
    directory = Directory('/storage/emulated/0/Download');
    if (!await directory.exists()) {
      directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    }
  } else {
    directory = await getApplicationDocumentsDirectory();
  }
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final filePath = '${directory!.path}/report_books_$timestamp.pdf';
  final file = File(filePath);

  await file.writeAsBytes(await pdf.save());
  return filePath;
} catch (e) {
print("Error: $e");
return null;
}
}


