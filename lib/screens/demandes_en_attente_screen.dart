import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_services.dart'; // Assure-toi d'importer ton ApiService

class DemandesEnAttenteScreen extends StatefulWidget {
  @override
  State<DemandesEnAttenteScreen> createState() =>
      _DemandesEnAttenteScreenState();
}

class _DemandesEnAttenteScreenState extends State<DemandesEnAttenteScreen> {
  List<Map<String, dynamic>> demandes = []; // À remplir via ton ApiService
  bool isLoading = true;
  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadDemandes();
  }

  Future<void> _loadDemandes() async {
    try {
      final result = await apiService.fetchDemandesEnAttente();
      setState(() {
        demandes = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur de chargement des demandes")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF17333F),
      appBar: AppBar(
        backgroundColor: Color(0xFF17333F),
        title: Text("Demandes en attente"),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : demandes.isEmpty
              ? Center(
                  child: Text("Aucune demande en attente",
                      style: TextStyle(color: Colors.white70)))
              : ListView.builder(
                  itemCount: demandes.length,
                  itemBuilder: (context, index) {
                    final demande = demandes[index];
                    return Card(
                        color:
                            Color(0xFFFFA726), // Orange pour signaler l'attente
                        margin:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading:
                              Icon(Icons.hourglass_top, color: Colors.white),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                demande['num_fiche']?.toString() ?? '',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "${demande['montant_fiche'] ?? ''} XOF",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Text(
                                demande['precision_fiche']?.toString() ?? '',
                                style: TextStyle(color: Colors.white70),
                              ),
                              SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.person,
                                      color: Colors.white54, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    demande['beficiaire_fiche']?.toString() ??
                                        '',
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                  Spacer(),
                                  Icon(Icons.calendar_today,
                                      color: Colors.white54, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    demande['date_creat_fiche']?.toString() ??
                                        '',
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Icon(Icons.arrow_forward_ios,
                              color: Colors.white54, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DemandeDetailScreen(
                                  demande: demande,
                                  onAccept: () {
                                    // Appelle ton API pour accepter
                                    Navigator.pop(context);
                                    _loadDemandes();
                                  },
                                  onRefuse: () {
                                    // Appelle ton API pour refuser
                                    Navigator.pop(context);
                                    _loadDemandes();
                                  },
                                ),
                              ),
                            );
                          },
                        ));
                  },
                ),
    );
  }
}

class DemandeDetailScreen extends StatelessWidget {
  final Map<String, dynamic> demande;
  final VoidCallback onAccept;
  final VoidCallback onRefuse;

  const DemandeDetailScreen({
    required this.demande,
    required this.onAccept,
    required this.onRefuse,
  });

  @override
  Widget build(BuildContext context) {
    final montant =
        double.tryParse(demande['montant_fiche']?.toString() ?? '0') ?? 0;

    return Scaffold(
      backgroundColor: Color(0xFF17333F),
      appBar: AppBar(
        backgroundColor: Color(0xFF17333F),
        title: Text("Demande en attente"),
      ),
      body: Center(
        child: Card(
          color: Color(0xFFFFA726),
          margin: EdgeInsets.all(24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hourglass_top, color: Colors.white, size: 48),
                  SizedBox(height: 16),
                  Text(
                    demande['num_fiche']?.toString() ?? '',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        letterSpacing: 2),
                  ),
                  Divider(color: Colors.white24, height: 32),
                  _infoRow("Nom du bénéficiaire", demande['beficiaire_fiche']),
                  _infoRow("Montant", "${montant.toStringAsFixed(0)} XOF"),
                  _infoRow("Date", demande['date_creat_fiche']),
                  _infoRow("Motif", demande['precision_fiche']),
                  _infoRow("Numéro fiche", demande['num_fiche']),
                  _infoRow("Entreprise", demande['entreprise']),
                  // Ajoute d'autres champs si besoin
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        icon: Icon(Icons.check),
                        label: Text("Accepter"),
                        onPressed: onAccept,
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        icon: Icon(Icons.close),
                        label: Text("Refuser"),
                        onPressed: onRefuse,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style:
                  TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value?.toString() ?? '',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
