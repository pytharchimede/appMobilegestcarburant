import 'package:flutter/material.dart';
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
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Full history stats désormais
      final stats = await apiService.fetchSoldeEvolutionStatsAll(maxYears: 20);
      setState(() {
        pourcentage = (stats['utilisation'] ?? 0.0).toDouble().clamp(0.0, 1.0);
        totalIn = (stats['totalRechargement'] ?? 0.0).toDouble();
        totalOut = (stats['totalServi'] ?? 0.0).toDouble();
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
                        "Utilisation cumulée (toute l'activité)",
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
          ],
        ),
      ),
    );
  }
}
