import 'package:flutter/material.dart';
import '../widgets/solde_widget.dart';
import '../widgets/station_selection_dialog.dart';
import '../widgets/graphique_widget.dart';
import '../widgets/solde_evolution_widget.dart';
import '../services/api_services.dart';
import 'historique_bons_screen.dart'; // Importer l'écran HistoriqueBonsScreen

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService apiService = ApiService();
  late Future<Map<String, dynamic>> soldeFuture;

  @override
  void initState() {
    super.initState();
    soldeFuture = apiService.fetchSolde();
  }

  void _onRechargePressed() {
    showDialog(
      context: context,
      builder: (_) => StationSelectionDialog(
        onValider: (telephone, nomGerant, montant) async {
          try {
            bool success = await apiService.rechargerStation(
              telephone: telephone,
              nom: nomGerant,
              montant: montant,
            );
            Navigator.pop(context); // Ferme la boîte de dialogue ici SEULEMENT
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Rechargement effectué avec succès !")),
              );
              setState(() {
                soldeFuture = apiService.fetchSolde();
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Échec du rechargement")),
              );
            }
          } catch (e) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Erreur réseau ou serveur")),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tableau de Bord')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: soldeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur de chargement'));
          } else {
            final data = snapshot.data!;
            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SoldeWidget(
                    solde: data['solde'],
                    dernierCredit: data['dernierCredit'],
                    onRecharge: _onRechargePressed,
                  ),
                  SizedBox(height: 20),
                  GraphiqueWidget(),
                  SizedBox(height: 20),
                  SoldeEvolutionWidget(),
                  SizedBox(height: 20),
                  MenuItem(
                      icon: Icons.receipt_long, title: "Historique des bons"),
                  MenuItem(
                      icon: Icons.pending_actions,
                      title: "Demandes en attente"),
                  MenuItem(icon: Icons.bar_chart, title: "Statistiques"),
                  SizedBox(height: 100),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}

class MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;

  const MenuItem({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color(0xFF17333F),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title, style: TextStyle(color: Colors.white)),
        trailing:
            Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => HistoriqueBonsScreen()),
          );
        },
      ),
    );
  }
}
