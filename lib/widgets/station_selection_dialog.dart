import 'package:flutter/material.dart';
import '../services/api_services.dart';

class StationSelectionDialog extends StatefulWidget {
  final void Function(String telephone, String nomGerant) onSelected;

  StationSelectionDialog({required this.onSelected});

  @override
  _StationSelectionDialogState createState() => _StationSelectionDialogState();
}

class _StationSelectionDialogState extends State<StationSelectionDialog> {
  final ApiService apiService = ApiService();
  List<Map<String, dynamic>> stations = [];
  Map<String, dynamic>? selectedStation;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    try {
      final data = await apiService.fetchStationsService();
      setState(() {
        stations = data;
        if (stations.isNotEmpty) selectedStation = stations[0];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = "Erreur de chargement : $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (error != null) {
      return AlertDialog(
        title: Text('Erreur'),
        content: Text(error!),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text('Sélectionnez la station'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<Map<String, dynamic>>(
            isExpanded: true,
            value: selectedStation,
            items: stations.map((station) {
              return DropdownMenuItem(
                value: station,
                child: Text(station['nom_station']),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedStation = value;
              });
            },
          ),
          SizedBox(height: 16),
          if (selectedStation != null) ...[
            Text(
              "Nom station : ${selectedStation!['nom_station']}",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text("Nom gérant : ${selectedStation!['nom_gerant']}"),
            Text("Téléphone : ${selectedStation!['telephone_gerant']}"),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: selectedStation == null
              ? null
              : () {
                  widget.onSelected(
                    selectedStation!['telephone_gerant'],
                    selectedStation!['nom_gerant'],
                  );
                },
          child: Text('Envoyer OTP'),
        ),
      ],
    );
  }
}
