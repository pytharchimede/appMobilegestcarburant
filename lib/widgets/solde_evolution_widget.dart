import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SoldeEvolutionWidget extends StatelessWidget {
  // Données JSON simulées
  final List<Map<String, dynamic>> donneesTest = [
    {"jour": 1, "solde": 350000},
    {"jour": 5, "solde": 420000},
    {"jour": 10, "solde": 380000},
    {"jour": 15, "solde": 470000},
    {"jour": 20, "solde": 500000},
    {"jour": 25, "solde": 450000},
    {"jour": 30, "solde": 520000},
  ];

  @override
  Widget build(BuildContext context) {
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
                    LineChartBarData(
                      isCurved: true,
                      color: Color(0xFF00A9A5),
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Color(0xFF00A9A5).withOpacity(0.2),
                      ),
                      spots: donneesTest
                          .map((point) => FlSpot(point['jour'].toDouble(),
                              point['solde'].toDouble()))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
