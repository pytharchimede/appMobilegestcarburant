import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/api_services.dart';

class GraphiqueWidget extends StatefulWidget {
  @override
  _GraphiqueWidgetState createState() => _GraphiqueWidgetState();
}

class _GraphiqueWidgetState extends State<GraphiqueWidget> {
  final ApiService apiService = ApiService();
  double pourcentage = 0.0;
  double totalIn = 0.0;
  double totalOut = 0.0;
  List<Map<String, dynamic>> donnees = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Charger les stats (utilisation) + la série d'évolution pour les graphes
      final stats = await apiService.fetchSoldeEvolutionStats();
      final data = await apiService.fetchSoldeEvolution();
      setState(() {
        pourcentage = (stats['utilisation'] ?? 0.0).toDouble().clamp(0.0, 1.0);
        totalIn = (stats['totalRechargement'] ?? 0.0).toDouble();
        totalOut = (stats['totalServi'] ?? 0.0).toDouble();
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
      return Card(
        color: Color(0xFF17333F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
              child: CircularProgressIndicator(color: Color(0xFF00A9A5))),
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
              'Erreur: $error',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ),
      );
    }

    // Préparation des séries pour les 3 graphes séparés
    final List<Map<String, dynamic>> dataTriee = [...donnees];
    dataTriee.sort((a, b) {
      final da = a['date'];
      final db = b['date'];
      if (da is String && db is String) return da.compareTo(db);
      final ja = (a['jour'] ?? 0) as num;
      final jb = (b['jour'] ?? 0) as num;
      return ja.compareTo(jb);
    });

    double safeNum(dynamic v) => (v is num) ? v.toDouble() : 0.0;
    final List<String> labels = [];
    final List<FlSpot> rechargementsSpots = [];
    final List<FlSpot> demandesSpots = [];
    final List<FlSpot> soldeSpots = [];
    double cumul = 0.0;
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
      final double soldeVal = p.containsKey('solde_evolutif')
          ? safeNum(p['solde_evolutif'])
          : (cumul += recharge - demandeServie);
      soldeSpots.add(FlSpot(x, soldeVal));
    }

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
                SizedBox(
                  width: 110,
                  height: 110,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 110,
                        height: 110,
                        child: CircularProgressIndicator(
                          value: pourcentage,
                          backgroundColor: Colors.white24,
                          color: Color(0xFF00A9A5),
                          strokeWidth: 12,
                        ),
                      ),
                      Text(
                        "${(pourcentage * 100).toInt()}%",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 28),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Niveau de carburant utilisé",
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Utilisation : ${(pourcentage * 100).toInt()}%",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "${numberFmt.format(totalOut)} / ${numberFmt.format(totalIn)}",
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
              color: Color(0xFF00A9A5),
              spots: soldeSpots,
              labels: labels,
              fill: true,
            ),
          ],
        ),
      ),
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
