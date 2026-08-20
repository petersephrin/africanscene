import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:universal_html/html.dart' as html;

class ExportService {
  /// Export data rows to CSV and trigger browser download or share
  static Future<void> exportToCsv({
    required String filename,
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) async {
    final buffer = StringBuffer();
    final allRows = [headers, ...rows];
    for (final row in allRows) {
      final formattedRow = row.map((cell) {
        if (cell == null) return '';
        final str = cell.toString();
        if (str.contains(',') || str.contains('"') || str.contains('\n') || str.contains('\r')) {
          return '"${str.replaceAll('"', '""')}"';
        }
        return str;
      }).join(',');
      buffer.writeln(formattedRow);
    }
    final bytes = utf8.encode(buffer.toString());

    _triggerDownload(bytes: Uint8List.fromList(bytes), filename: '$filename.csv', mimeType: 'text/csv');
  }

  /// Export data rows to Excel (.xlsx) and trigger download
  static Future<void> exportToExcel({
    required String filename,
    required String sheetName,
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel[excel.getDefaultSheet() ?? sheetName];

    // Append headers
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    // Append rows
    for (final row in rows) {
      sheet.appendRow(
        row.map((cell) {
          if (cell == null) return TextCellValue('');
          if (cell is num) return IntCellValue(cell.toInt());
          if (cell is bool) return BoolCellValue(cell);
          return TextCellValue(cell.toString());
        }).toList(),
      );
    }

    final fileBytes = excel.save();
    if (fileBytes != null) {
      _triggerDownload(
        bytes: Uint8List.fromList(fileBytes),
        filename: '$filename.xlsx',
        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    }
  }

  /// Export list of maps to formatted JSON file
  static Future<void> exportToJson({
    required String filename,
    required dynamic jsonData,
  }) async {
    final jsonString = JsonEncoder.withIndent('  ', (object) {
      if (object is Timestamp) return object.toDate().toIso8601String();
      if (object is DateTime) return object.toIso8601String();
      return object.toString();
    }).convert(jsonData);
    final bytes = utf8.encode(jsonString);

    _triggerDownload(
      bytes: Uint8List.fromList(bytes),
      filename: '$filename.json',
      mimeType: 'application/json',
    );
  }

  static void _triggerDownload({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  }) {
    if (kIsWeb) {
      try {
        final blob = html.Blob([bytes], mimeType);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', filename);
        anchor.click();
        html.Url.revokeObjectUrl(url);
      } catch (e) {
        debugPrint('Web download error: $e');
      }
    } else {
      debugPrint('Exported $filename (${bytes.length} bytes)');
    }
  }
}
