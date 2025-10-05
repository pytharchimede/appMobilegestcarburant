import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/api_services.dart';

class SeparateChartsWidget extends StatefulWidget {
  const SeparateChartsWidget({super.key});

  @override
  State<SeparateChartsWidget> createState() => _SeparateChartsWidgetState();
}

class _SeparateChartsWidgetState extends State<SeparateChartsWidget> {
  final ApiService apiService = ApiService();
  bool isLoading = true;
  String? error;
  List<Map<String, dynamic>> donnees = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data =
          await apiService.fetchSoldeEvolutionFullHistory(maxYears: 20);
      setState(() {
        donnees = List<Map<String, dynamic>>.from(data);
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
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Text('Erreur: $error',
          style: const TextStyle(color: Colors.redAccent));
    }

    // Prépare les séries
    final dataTriee = [...donnees]; // déjà trié
    double safeNum(dynamic v) => (v is num) ? v.toDouble() : 0.0;
    final List<String> labels = [];
    final List<FlSpot> rechargementsSpots = [];
    final List<FlSpot> demandesSpots = [];
    final List<FlSpot> soldeSpots = [];
    double cumul = 0.0;
    final int step = dataTriee.length > 1200
        ? 4
        : (dataTriee.length > 800 ? 3 : (dataTriee.length > 400 ? 2 : 1));
    int visIndex = 0;
    for (int i = 0; i < dataTriee.length; i++) {
      if (i % step != 0 && i != dataTriee.length - 1) continue;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MiniChart(
          title: 'Entrées (Rechargements)',
          color: Colors.greenAccent,
          spots: rechargementsSpots,
          labels: labels,
        ),
        const SizedBox(height: 12),
        _MiniChart(
          title: 'Sorties (Servies)',
          color: Colors.redAccent,
          spots: demandesSpots,
          labels: labels,
        ),
        const SizedBox(height: 12),
        _MiniChart(
          title: 'Solde évolutif',
          color: const Color(0xFF00A9A5),
          spots: soldeSpots,
          labels: labels,
          fill: true,
        ),
      ],
    );
  }
}

class _MiniChart extends StatelessWidget {
  final String title;
  final Color color;
  final List<FlSpot> spots;
  final List<String> labels;
  final bool fill;

  const _MiniChart({
    required this.title,
    required this.color,
    required this.spots,
    required this.labels,
    this.fill = false,
  });

  @override
  Widget build(BuildContext context) {
    double seriesMax(List<FlSpot> s) =>
        s.isEmpty ? 0 : s.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    final maxY = seriesMax(spots);
    final pad = maxY * 0.15;
    final double niceMax = (maxY + pad) > 0 ? (maxY + pad) : 1.0;
    final numberFmt = NumberFormat.compact(locale: 'fr_FR');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 6),
        SizedBox(
          height: 110,
          child: LineChart(
            LineChartData(
              backgroundColor: Colors.transparent,
              minY: 0,
              maxY: niceMax,
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 20,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final idx = value.round();
                      final step = (labels.length / 6).ceil().clamp(1, 10);
                      if (idx % step == 0 && idx >= 0 && idx < labels.length) {
                        return Text(labels[idx],
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 9));
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (value, meta) => Text(
                      numberFmt.format(value),
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 9),
                    ),
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
                  color: color,
                  barWidth: 3,
                  belowBarData:
                      BarAreaData(show: fill, color: color.withOpacity(0.12)),
                  spots: spots,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
