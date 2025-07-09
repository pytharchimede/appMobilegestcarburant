import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class BonDetailScreen extends StatelessWidget {
  final Map<String, dynamic> bon;

  const BonDetailScreen({required this.bon});

  @override
  Widget build(BuildContext context) {
    final montant = double.tryParse(bon['montant'].toString()) ?? 0;
    final photoUrl =
        bon['photo_url']; // Mets ici la clé réelle si tu as une photo

    return Scaffold(
      backgroundColor: Color(0xFF17333F),
      appBar: AppBar(
        backgroundColor: Color(0xFF17333F),
        title: Text("Détail du bon"),
      ),
      body: Center(
        child: Card(
          color: Color(0xFF223C4A),
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
                  // Photo ou avatar
                  CircleAvatar(
                    radius: 40,
                    backgroundImage:
                        (photoUrl != null && photoUrl.toString().isNotEmpty)
                            ? NetworkImage(photoUrl)
                            : null,
                    backgroundColor: Colors.white10,
                    child: (photoUrl == null || photoUrl.toString().isEmpty)
                        ? Icon(Icons.person, color: Colors.white54, size: 48)
                        : null,
                  ),
                  SizedBox(height: 16),
                  // QR Code
                  QrImageView(
                    data:
                        'https://fidest.ci/decaissement/bon_essence.php?id_bon=${bon['num_fiche'] ?? ''}',
                    version: QrVersions.auto,
                    size: 100,
                    backgroundColor: Colors.white,
                  ),
                  SizedBox(height: 16),
                  Text(
                    bon['code_bon']?.toString() ?? '',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        letterSpacing: 2),
                  ),
                  Divider(color: Colors.white24, height: 32),
                  _infoRow("Nom du demandeur", bon['nom_beneficiaire']),
                  _infoRow("Montant", "${montant.toStringAsFixed(0)} XOF"),
                  _infoRow("Date", bon['date_demande']),
                  _infoRow("Motif", bon['motif']),
                  _infoRow("Désignation", bon['vehicule']),
                  // _infoRow("Quantité", bon['quantite']),
                  _infoRow("Numéro fiche", bon['num_fiche']),
                  // _infoRow("DG", bon['dg_nom']),
                  _infoRow("Créé le", bon['created_at']),
                  SizedBox(height: 16),
                  Text(
                    "Bon généré par Gestion Carburant",
                    style: TextStyle(color: Colors.white38, fontSize: 12),
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
