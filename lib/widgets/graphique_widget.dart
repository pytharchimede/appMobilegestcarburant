import 'package:flutter/material.dart';
import '../services/api_services.dart';

class GraphiqueWidget extends StatefulWidget {
  @override
  _GraphiqueWidgetState createState() => _GraphiqueWidgetState();
}

class _GraphiqueWidgetState extends State<GraphiqueWidget> {
  final ApiService apiService = ApiService();
  double pourcentage = 0.0;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadUtilisation();
  }

  Future<void> _loadUtilisation() async {
    try {
      double value = await apiService.fetchCarburantUtilisation();
      setState(() {
        pourcentage = value.clamp(0.0, 1.0);
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

    return Card(
      color: Color(0xFF17333F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
