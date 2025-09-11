import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../services/api_services.dart';

class SoldeEvolutionWidget extends StatefulWidget {
  @override
  _SoldeEvolutionWidgetState createState() => _SoldeEvolutionWidgetState();
}

class _SoldeEvolutionWidgetState extends State<SoldeEvolutionWidget> {
  final ApiService apiService = ApiService();
  List<Map<String, dynamic>> donnees = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadDonnees();
  }

  Future<void> _loadDonnees() async {
    try {
      final data = await apiService.fetchSoldeEvolution();
      setState(() {
        donnees = data;
        isLoading = false;
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

    // Préparer deux séries positives superposées à partir des données API
    final List<Map<String, dynamic>> dataTriee = [...donnees];
    dataTriee.sort((a, b) {
      final da = a['date'];
      final db = b['date'];
      if (da is String && db is String) {
        return da.compareTo(db);
      }
      final ja = (a['jour'] ?? 0) as num;
      final jb = (b['jour'] ?? 0) as num;
      return ja.compareTo(jb);
    });

    double safeNum(dynamic v) => (v is num) ? v.toDouble() : 0.0;

    final List<String> labels = [];
    final List<FlSpot> rechargementsSpots = [];
    final List<FlSpot> demandesSpots = [];
    for (int i = 0; i < dataTriee.length; i++) {
      final p = dataTriee[i];
      final dateStr = (p['date'] ?? '').toString();
      String label;
      if (dateStr.isNotEmpty && dateStr.length >= 10) {
        label = '${dateStr.substring(8, 10)}/${dateStr.substring(5, 7)}';
      } else {
        label = 'J${((p['jour'] ?? (i + 1)) as num).toInt()}';
      }
      labels.add(label);

      final x = i.toDouble();
      final recharge = p.containsKey('rechargement')
          ? safeNum(p['rechargement'])
          : safeNum(p['entree']).abs();
      final demandeServie = p.containsKey('sortie_servie')
          ? safeNum(p['sortie_servie'])
          : safeNum(p['sortie']).abs();
      rechargementsSpots.add(FlSpot(x, recharge));
      demandesSpots.add(FlSpot(x, demandeServie));
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

    final maxVal =
        math.max(seriesMax(rechargementsSpots), seriesMax(demandesSpots));
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
            Text('Rechargements vs Demandes servies',
                style: TextStyle(color: Colors.white70)),
            SizedBox(height: 10),
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
