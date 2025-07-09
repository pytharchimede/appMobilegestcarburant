import 'package:flutter/material.dart';
import '../services/api_services.dart';

class StationSelectionDialog extends StatefulWidget {
  final void Function(String telephone, String nomGerant, double montant)? onValider;

  StationSelectionDialog({this.onValider});

  @override
  _StationSelectionDialogState createState() => _StationSelectionDialogState();
}

class _StationSelectionDialogState extends State<StationSelectionDialog> {
  final ApiService apiService = ApiService();
  List<Map<String, dynamic>> stations = [];
  Map<String, dynamic>? selectedStation;
  bool isLoading = true;
  String? error;
  final TextEditingController montantController = TextEditingController();

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
    return AlertDialog(
      backgroundColor: Color(0xFF17333F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Rechargement de station',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: isLoading
          ? SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : error != null
              ? Text(error!, style: TextStyle(color: Colors.red))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButton<Map<String, dynamic>>(
                      isExpanded: true,
                      dropdownColor: Color(0xFF223C4A),
                      value: selectedStation,
                      items: stations.map((station) {
                        return DropdownMenuItem(
                          value: station,
                          child: Text(
                            station['nom_station'],
                            style: TextStyle(color: Colors.white),
                          ),
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
                        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Nom gérant : ${selectedStation!['nom_gerant']}",
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        "Téléphone : ${selectedStation!['telephone_gerant']}",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                    SizedBox(height: 24),
                    TextField(
                      controller: montantController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: Colors.white, fontSize: 18),
                      decoration: InputDecoration(
                        labelText: "Montant à recharger",
                        labelStyle: TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Color(0xFF223C4A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.attach_money, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Color(0xFF00A9A5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: (selectedStation == null || montantController.text.isEmpty)
              ? null
              : () {
                  final montant = double.tryParse(montantController.text.replaceAll(',', '.'));
                  if (montant == null || montant <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Veuillez saisir un montant valide.")),
                    );
                    return;
                  }
                  if (widget.onValider != null) {
                    widget.onValider!(
                      selectedStation!['telephone_gerant'],
                      selectedStation!['nom_gerant'],
                      montant,
                    );
                  }
                },
          child: Text('Valider', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Annuler', style: TextStyle(color: Colors.white54)),
        ),
      ],
    );
  }
}
