import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../services/api_services.dart';
import '../services/export_service.dart';

class SoldeEvolutionWidget extends StatefulWidget {
  @override
  _SoldeEvolutionWidgetState createState() => _SoldeEvolutionWidgetState();
}

class _SoldeEvolutionWidgetState extends State<SoldeEvolutionWidget> {
  final ApiService apiService = ApiService();
  List<Map<String, dynamic>> donnees = [];
  bool isLoading = true;
  String? error;
  Map<String, dynamic>? _statsAll;

  @override
  void initState() {
    super.initState();
    _loadDonnees();
  }

  Future<void> _loadDonnees() async {
    try {
      final data =
          await apiService.fetchSoldeEvolutionFullHistory(maxYears: 20);
      final stats = await apiService.fetchSoldeEvolutionStatsAll(maxYears: 20);
      setState(() {
        donnees = data;
        isLoading = false;
        _statsAll = stats;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Card(
        color: Color(0xFF17333F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFF00A9A5)),
          ),
        ),
      );
    }

    if (error != null) {
      return Card(
        color: Color(0xFF17333F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text(
              'Erreur : $error',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ),
      );
    }

    // Les données full history sont déjà triées dans le service
    final List<Map<String, dynamic>> dataTriee = [...donnees];

    double safeNum(dynamic v) => (v is num) ? v.toDouble() : 0.0;

    final List<String> labels = [];
    final List<FlSpot> rechargementsSpots = [];
    final List<FlSpot> demandesSpots = [];
    final List<FlSpot> soldeSpots = [];
    double cumul = 0.0;
    // Downsampling pour performance si dataset volumineux
    final int step = dataTriee.length > 1200
        ? 4
        : (dataTriee.length > 800 ? 3 : (dataTriee.length > 400 ? 2 : 1));
    int visIndex = 0;
    for (int i = 0; i < dataTriee.length; i++) {
      if (i % step != 0 && i != dataTriee.length - 1)
        continue; // garder dernier point
      final p = dataTriee[i];
      final dateStr = (p['date'] ?? '').toString();
      String label = '';
      if (dateStr.length >= 10) {
        label = '${dateStr.substring(8, 10)}/${dateStr.substring(5, 7)}';
      }
      labels.add(label);
      final recharge = safeNum(p['rechargement'] ?? p['entree']);
      final demandeServie =
          safeNum(p['sortie_servie'] ?? p['demande_servie'] ?? p['sortie']);
      cumul += recharge - demandeServie;
      final x = visIndex.toDouble();
      rechargementsSpots.add(FlSpot(x, recharge));
      demandesSpots.add(FlSpot(x, demandeServie));
      soldeSpots.add(FlSpot(x, cumul));
      visIndex++;
    }

    double seriesMax(List<FlSpot> s) =>
        s.isEmpty ? 0 : s.map((e) => e.y).reduce(math.max);
    double niceStep(double maxVal) {
      if (maxVal <= 0) return 1;
      final raw = maxVal / 4; // ~4 graduations
      final pow10 = (math.log(raw) / math.log(10)).floor();
      final base = math.pow(10, pow10).toDouble();
      final candidates = [1 * base, 2 * base, 5 * base, 10 * base];
      double best = candidates.first;
      for (final c in candidates) {
        if ((raw - c).abs() < (raw - best).abs()) best = c;
      }
      return best;
    }

    final maxVal = [
      seriesMax(rechargementsSpots),
      seriesMax(demandesSpots),
      seriesMax(soldeSpots),
    ].reduce(math.max);
    final pad = maxVal * 0.1;
    final maxY = maxVal + pad;
    final yInterval = niceStep(maxY);
    final numberFmt = NumberFormat.compact(locale: 'fr_FR');

    return Card(
      color: Color(0xFF17333F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Historique global (Entrées / Sorties / Solde)',
                      style: TextStyle(color: Colors.white70)),
                ),
                _ExportMenu(rows: dataTriee, stats: _statsAll),
              ],
            ),
            SizedBox(height: 6),
            if (_statsAll != null)
              Text(
                  'Période: ${_statsAll!['premiereDate'] ?? '-'} -> ${_statsAll!['derniereDate'] ?? '-'}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
            SizedBox(height: 6),
            Container(
              height: 220,
              child: LineChart(
                LineChartData(
                  backgroundColor: Colors.transparent,
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.round();
                          // Afficher ~6 labels max
                          final step = (labels.length / 6).ceil().clamp(1, 10);
                          if (idx % step == 0 &&
                              idx >= 0 &&
                              idx < labels.length) {
                            return Text(labels[idx],
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 10));
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: yInterval,
                        getTitlesWidget: (value, meta) => Text(
                            numberFmt.format(value),
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 10)),
                      ),
                    ),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      color: Colors.greenAccent,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                          show: true,
                          color: Colors.greenAccent.withOpacity(0.12)),
                      spots: rechargementsSpots,
                    ),
                    LineChartBarData(
                      isCurved: true,
                      color: Colors.redAccent,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                          show: true,
                          color: Colors.redAccent.withOpacity(0.10)),
                      spots: demandesSpots,
                    ),
                    LineChartBarData(
                      isCurved: true,
                      color: Color(0xFF00A9A5),
                      barWidth: 3,
                      belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF00A9A5).withOpacity(0.10)),
                      spots: soldeSpots,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.show_chart, color: Colors.greenAccent, size: 16),
                Text(' Rechargements',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                SizedBox(width: 12),
                Icon(Icons.show_chart, color: Colors.redAccent, size: 16),
                Text(' Demandes servies',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                SizedBox(width: 12),
                Icon(Icons.show_chart, color: Color(0xFF00A9A5), size: 16),
                Text(' Solde évolutif',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportMenu extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final Map<String, dynamic>? stats;
  const _ExportMenu({required this.rows, required this.stats});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Exporter / Partager',
      icon: const Icon(Icons.more_vert, color: Colors.white70),
      onSelected: (v) async {
        final messenger = ScaffoldMessenger.of(context);
        try {
          if (v == 'csv') {
            final f = await ExportService.exportCsv(rows);
            messenger.showSnackBar(SnackBar(content: Text('CSV: ${f.path}')));
            await ExportService.openFile(f);
          } else if (v == 'excel') {
            final f = await ExportService.exportExcel(rows);
            messenger.showSnackBar(SnackBar(content: Text('Excel: ${f.path}')));
            await ExportService.openFile(f);
          } else if (v == 'pdf') {
            final f = await ExportService.exportPdf(rows, stats ?? {});
            messenger.showSnackBar(SnackBar(content: Text('PDF: ${f.path}')));
            await ExportService.openFile(f);
          } else if (v == 'share') {
            final summary = _buildSummary(stats);
            messenger.showSnackBar(SnackBar(
                content: Text('Résumé prêt (${summary.length} caractères).')));
          }
        } catch (e) {
          messenger.showSnackBar(SnackBar(content: Text('Erreur: $e')));
        }
      },
      itemBuilder: (c) => const [
        PopupMenuItem(value: 'csv', child: Text('Exporter CSV')),
        PopupMenuItem(value: 'excel', child: Text('Exporter Excel')),
        PopupMenuItem(value: 'pdf', child: Text('Exporter PDF')),
        PopupMenuItem(value: 'share', child: Text('Partager résumé')),
      ],
    );
  }

  String _buildSummary(Map<String, dynamic>? stats) {
    if (stats == null) return 'Aucun résumé';
    final utilPct =
        (((stats['utilisation'] ?? 0.0) as num) * 100).toStringAsFixed(1);
    return 'Carburant – Période ${stats['premiereDate'] ?? '-'} -> ${stats['derniereDate'] ?? '-'}\n'
        'Total rechargé: ${stats['totalRechargement']}\n'
        'Total servi: ${stats['totalServi']}\n'
        'Solde: ${stats['soldeActuel']}\n'
        'Utilisation: $utilPct%';
  }
}
