import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';

Future<String?> generateAndSaveExcel(List<Map<String, String>> data) async {
  try {
    // 1. Validate input data
    if (data.isEmpty) {
      print("No data provided for Excel generation");
      return null;
    }

    // 2. Create Excel document
    final excel = Excel.createExcel();
    final sheet = excel[excel.getDefaultSheet()!];

    // 3. Add title row (merged cells)
    final headers = data.first.keys.toList();
    final lastColumn = String.fromCharCode(65 + headers.length - 1);
    sheet.merge(
      CellIndex.indexByString("A1"),
      CellIndex.indexByString("${lastColumn}1"),
    );
    final titleCell = sheet.cell(CellIndex.indexByString("A1"));
    titleCell.value = "Detected Results"; // Direct string assignment
    titleCell.cellStyle = CellStyle(bold: true, fontSize: 20);

    // 4. Add header row (row 3)
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByString("${String.fromCharCode(65 + i)}3"),
      );
      cell.value = headers[i]; // Direct string assignment
      cell.cellStyle = CellStyle(bold: true);
    }

    // 5. Add data rows (starting from row 4)
    for (int row = 0; row < data.length; row++) {
      final rowData = data[row];
      for (int col = 0; col < headers.length; col++) {
        final cell = sheet.cell(
          CellIndex.indexByString("${String.fromCharCode(65 + col)}${row + 4}"),
        );
        cell.value = rowData[headers[col]] ?? ''; // Direct string assignment
      }
    }

    // 6. Auto-size columns
    for (int i = 0; i < headers.length; i++) {
      sheet.setColAutoFit(i);
    }

    // 7. Save file
    Directory directory;
    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        directory =
            (await getExternalStorageDirectory()) ??
            (await getApplicationDocumentsDirectory());
      }
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${directory.path}/rapport_books_$timestamp.xlsx';
    final file = File(filePath);

    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception("Failed to encode Excel file");
    }

    await file.writeAsBytes(bytes);
    print("Excel file saved to: $filePath");

    return filePath;
  } catch (e, stackTrace) {
    print("Error generating Excel: $e");
    print("Stack trace: $stackTrace");
    return null;
  }
}
