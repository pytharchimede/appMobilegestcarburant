import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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

    return Card(
      color: Color(0xFF17333F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Évolution du solde", style: TextStyle(color: Colors.white70)),
            SizedBox(height: 10),
            Container(
              height: 150,
              child: LineChart(
                LineChartData(
                  backgroundColor: Colors.transparent,
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: 5,
                        getTitlesWidget: (value, meta) {
                          if (value % 5 == 0 || value == 1 || value == 30) {
                            return Text(
                              "${value.toInt()}j",
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 10),
                            );
                          }
                          return Container();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                        interval: 50000,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            "${(value / 1000).toInt()}k",
                            style:
                                TextStyle(color: Colors.white54, fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    // Solde (ligne principale)
                    LineChartBarData(
                      isCurved: true,
                      color: Color(0xFF00A9A5),
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Color(0xFF00A9A5).withOpacity(0.2),
                      ),
                      spots: donnees
                          .map((point) => FlSpot(
                              (point['jour'] as num).toDouble(),
                              (point['solde'] as num).toDouble()))
                          .toList(),
                    ),
                    // Entrées (optionnel, en pointillés)
                    LineChartBarData(
                      isCurved: false,
                      color: Colors.greenAccent,
                      barWidth: 1,
                      isStrokeCapRound: true,
                      dashArray: [5, 5],
                      spots: donnees
                          .map((point) => FlSpot(
                              (point['jour'] as num).toDouble(),
                              (point['entree'] as num).toDouble()))
                          .toList(),
                    ),
                    // Sorties (optionnel, en pointillés)
                    LineChartBarData(
                      isCurved: false,
                      color: Colors.redAccent,
                      barWidth: 1,
                      isStrokeCapRound: true,
                      dashArray: [5, 5],
                      spots: donnees
                          .map((point) => FlSpot(
                              (point['jour'] as num).toDouble(),
                              (point['sortie'] as num).toDouble()))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Icon(Icons.show_chart, color: Color(0xFF00A9A5), size: 16),
                Text(" Solde",
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                SizedBox(width: 12),
                Icon(Icons.show_chart, color: Colors.greenAccent, size: 16),
                Text(" Entrées",
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                SizedBox(width: 12),
                Icon(Icons.show_chart, color: Colors.redAccent, size: 16),
                Text(" Sorties",
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
