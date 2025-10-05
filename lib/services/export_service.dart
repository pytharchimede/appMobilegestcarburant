import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/foundation.dart';

class ExportService {
  static Future<File> exportCsv(List<Map<String, dynamic>> rows,
      {String fileName = 'historique_carburant.csv'}) async {
    final buffer = StringBuffer();
    if (rows.isEmpty) {
      buffer.writeln('date,rechargement,sortie_servie,solde_evolutif');
    } else {
      final headers = <String>{};
      for (final r in rows) {
        headers.addAll(r.keys);
      }
      final ordered = headers.toList();
      buffer.writeln(ordered.join(','));
      for (final r in rows) {
        buffer.writeln(ordered.map((h) => _csvEscape(r[h])).join(','));
      }
    }
    final dir = await _exportDir();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(buffer.toString());
    return file;
  }

  static Future<File> exportExcel(List<Map<String, dynamic>> rows,
      {String fileName = 'historique_carburant.xlsx'}) async {
    final excel = Excel.createExcel();
    final sheet = excel['Historique'];
    if (rows.isNotEmpty) {
      final headers = <String>{};
      for (final r in rows) {
        headers.addAll(r.keys);
      }
      final ordered = headers.toList();
      sheet.appendRow(ordered);
      for (final r in rows) {
        sheet.appendRow(ordered.map((h) => r[h]).toList());
      }
    } else {
      sheet.appendRow(['Aucune donnée']);
    }
    final dir = await _exportDir();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(excel.encode()!);
    return file;
  }

  static Future<File> exportPdf(
      List<Map<String, dynamic>> rows, Map<String, dynamic> stats,
      {String fileName = 'historique_carburant.pdf'}) async {
    final pdf = pw.Document();
    final headers = <String>{};
    for (final r in rows) {
      headers.addAll(r.keys);
    }
    final ordered = headers.toList();
    pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) {
          return [
            pw.Text('Récapitulatif Carburant',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text(
                'Période: ${stats['premiereDate'] ?? '-'} -> ${stats['derniereDate'] ?? '-'}'),
            pw.Text(
                'Total rechargé: ${(stats['totalRechargement'] ?? 0)}  |  Total servi: ${(stats['totalServi'] ?? 0)}  |  Solde: ${(stats['soldeActuel'] ?? 0)}'),
            pw.Text(
                'Utilisation: ${(((stats['utilisation'] ?? 0.0) as num) * 100).toStringAsFixed(1)}%'),
            pw.SizedBox(height: 12),
            if (rows.isEmpty)
              pw.Text('Aucune donnée')
            else
              pw.Table.fromTextArray(
                headers: ordered,
                data: rows
                    .map((r) =>
                        ordered.map((h) => (r[h] ?? '').toString()).toList())
                    .toList(),
                cellStyle: const pw.TextStyle(fontSize: 8),
                headerStyle:
                    pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerLeft,
              ),
          ];
        }));
    final dir = await _exportDir();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<void> openFile(File f) async {
    if (kIsWeb) return; // sur web on pourrait proposer un download différemment
    await OpenFile.open(f.path);
  }

  static Future<Directory> _exportDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final export = Directory('${dir.path}/exports');
    if (!await export.exists()) await export.create(recursive: true);
    return export;
  }

  static String _csvEscape(dynamic v) {
    final s = (v == null ? '' : v.toString());
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"' + s.replaceAll('"', '""') + '"';
    }
    return s;
  }
}
