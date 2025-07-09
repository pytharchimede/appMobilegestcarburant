import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_services.dart';

class HistoriqueBonsScreen extends StatefulWidget {
  @override
  State<HistoriqueBonsScreen> createState() => _HistoriqueBonsScreenState();
}

class _HistoriqueBonsScreenState extends State<HistoriqueBonsScreen> {
  final ApiService apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  final NumberFormat formatMontant = NumberFormat("#,##0", "fr_FR");

  List<Map<String, dynamic>> bons = [];
  bool isLoading = false;
  bool hasMore = true;
  int page = 1;
  double montantTotal = 0;

  // Filtres
  String? station;
  DateTime? dateDebut;
  DateTime? dateFin;
  double? montantMin;
  double? montantMax;

  @override
  void initState() {
    super.initState();
    _loadBons();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100 && !isLoading && hasMore) {
        _loadBons();
      }
    });
  }

  Future<void> _loadBons({bool reset = false}) async {
    if (isLoading) return;
    setState(() => isLoading = true);

    if (reset) {
      bons.clear();
      page = 1;
      montantTotal = 0;
      hasMore = true;
    }

    try {
      final result = await apiService.fetchBons(
        page: page,
        station: station,
        dateDebut: dateDebut,
        dateFin: dateFin,
        montantMin: montantMin,
        montantMax: montantMax,
      );
      setState(() {
        bons.addAll(result['bons']);
        montantTotal = result['montantTotal'];
        hasMore = result['hasMore'];
        page++;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur de chargement")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showFiltreDialog() async {
    String? selectedStation = station;
    DateTime? selectedDebut = dateDebut;
    DateTime? selectedFin = dateFin;
    double? selectedMin = montantMin;
    double? selectedMax = montantMax;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF17333F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Filtres", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            children: [
              // Station (à adapter selon ta liste de stations)
              TextField(
                decoration: InputDecoration(
                  labelText: "Station",
                  labelStyle: TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Color(0xFF223C4A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                style: TextStyle(color: Colors.white),
                onChanged: (v) => selectedStation = v,
                controller: TextEditingController(text: selectedStation),
              ),
              SizedBox(height: 12),
              // Dates
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDebut ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => selectedDebut = picked);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Color(0xFF223C4A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          selectedDebut != null
                              ? DateFormat('dd/MM/yyyy').format(selectedDebut!)
                              : "Date début",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedFin ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => selectedFin = picked);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Color(0xFF223C4A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          selectedFin != null
                              ? DateFormat('dd/MM/yyyy').format(selectedFin!)
                              : "Date fin",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              // Montant min/max
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Montant min",
                        labelStyle: TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Color(0xFF223C4A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (v) => selectedMin = double.tryParse(v),
                      controller: TextEditingController(text: selectedMin?.toString() ?? ''),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Montant max",
                        labelStyle: TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Color(0xFF223C4A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (v) => selectedMax = double.tryParse(v),
                      controller: TextEditingController(text: selectedMax?.toString() ?? ''),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                station = selectedStation;
                dateDebut = selectedDebut;
                dateFin = selectedFin;
                montantMin = selectedMin;
                montantMax = selectedMax;
              });
              Navigator.pop(context);
              _loadBons(reset: true);
            },
            child: Text("Appliquer", style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Annuler", style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF17333F),
      appBar: AppBar(
        title: Text("Historique des bons"),
        backgroundColor: Color(0xFF17333F),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_alt, color: Colors.white),
            onPressed: _showFiltreDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF223C4A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Montant total", style: TextStyle(color: Colors.white70)),
                Text(
                  "${formatMontant.format(montantTotal)} XOF",
                  style: TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 20),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: bons.length + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= bons.length) {
                  return Center(child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ));
                }
                final bon = bons[index];
                double montant = double.tryParse(bon['montant'].toString()) ?? 0;
                return Card(
                  color: Color(0xFF223C4A),
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Icon(Icons.receipt, color: Colors.white),
                    title: Text(
                      bon['nom_station']?.toString() ?? 'Station inconnue',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Montant : ${formatMontant.format(montant)} XOF",
                          style: TextStyle(color: Colors.white70),
                        ),
                        Text(
                          "Date : ${bon['date_demande'] ?? ''}",
                          style: TextStyle(color: Colors.white54),
                        ),
                        if ((bon['nom_gerant'] ?? '').toString().isNotEmpty)
                          Text("Gérant : ${bon['nom_gerant']}", style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                    onTap: () {
                      // TODO: Afficher le détail du bon si besoin
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}