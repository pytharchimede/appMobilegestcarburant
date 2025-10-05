import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

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

  /// Exporte un seul bon en PDF (fiche synthétique)
  static Future<File> exportBonPdf(Map<String, dynamic> bon,
      {String? fileName}) async {
    final pdf = pw.Document();
    final fmt = NumberFormat('#,##0', 'fr_FR');
    final code = (bon['code_bon'] ?? bon['num_fiche'] ?? '').toString();
    final montant = double.tryParse(bon['montant']?.toString() ?? '0') ?? 0;
    final titre = 'Bon carburant $code';
    fileName ??= 'bon_$code.pdf';

    pw.Widget line(String label, dynamic value) => pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                    flex: 4,
                    child: pw.Text(label,
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 11))),
                pw.SizedBox(width: 8),
                pw.Expanded(
                    flex: 6,
                    child: pw.Text((value ?? '').toString(),
                        style: const pw.TextStyle(fontSize: 11))),
              ]),
        );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (ctx) => pw.Container(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(titre,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 18)),
              pw.SizedBox(height: 8),
              pw.Divider(),
              line('Code', code),
              line('Bénéficiaire', bon['nom_beneficiaire']),
              line('Montant', '${fmt.format(montant)} XOF'),
              line('Date demande', bon['date_demande']),
              line('Motif', bon['motif']),
              line('Véhicule', bon['vehicule']),
              line('Num fiche', bon['num_fiche']),
              line('Créé le', bon['created_at']),
              pw.SizedBox(height: 16),
              pw.Text('Document généré par Gestion Carburant',
                  style:
                      const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
            ],
          ),
        ),
      ),
    );

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
