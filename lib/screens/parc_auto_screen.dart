import 'package:flutter/material.dart';

class ParcAutoScreen extends StatelessWidget {
  final List<Map<String, dynamic>> autos = [
    {
      "plaque": "AB-123-CD",
      "marque": "Toyota",
      "modele": "Hilux",
      "chauffeur": "Kouassi Jean",
      "permis": "PERM-2025-001",
      "carte_grise": "CG-2024-001",
      "assurance": "AXA - 12/2025",
      "photo_url": null,
      "documents": [
        {"type": "Permis", "url": null},
        {"type": "Carte grise", "url": null},
        {"type": "Assurance", "url": null},
      ]
    },
    {
      "plaque": "CD-456-EF",
      "marque": "Hyundai",
      "modele": "Santa Fe",
      "chauffeur": "Traoré Fatou",
      "permis": "PERM-2024-002",
      "carte_grise": "CG-2023-002",
      "assurance": "NSIA - 08/2024",
      "photo_url": null,
      "documents": [
        {"type": "Permis", "url": null},
        {"type": "Carte grise", "url": null},
        {"type": "Assurance", "url": null},
      ]
    },
  ];

  final List<Map<String, dynamic>> engins = [
    {
      "nom": "Chargeuse Caterpillar",
      "type": "Engin de chantier",
      "numero_serie": "CAT-ENG-001",
      "carte_grise": "CG-ENG-001",
      "assurance": "SUNU - 10/2025",
      "photo_url": null,
      "documents": [
        {"type": "Carte grise", "url": null},
        {"type": "Assurance", "url": null},
      ]
    },
    {
      "nom": "Tractopelle JCB",
      "type": "Engin de chantier",
      "numero_serie": "JCB-ENG-002",
      "carte_grise": "CG-ENG-002",
      "assurance": "NSIA - 03/2026",
      "photo_url": null,
      "documents": [
        {"type": "Carte grise", "url": null},
        {"type": "Assurance", "url": null},
      ]
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF17333F),
      appBar: AppBar(
        backgroundColor: Color(0xFF17333F),
        title: Text("Parc automobile & engins"),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text("Véhicules",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          ...autos.map((auto) => Card(
                color: Color(0xFF223C4A),
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: Icon(Icons.directions_car, color: Colors.white),
                  title: Text("${auto['marque']} ${auto['modele']}",
                      style: TextStyle(color: Colors.white)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Plaque : ${auto['plaque']}",
                          style: TextStyle(color: Colors.white70)),
                      Text("Chauffeur : ${auto['chauffeur']}",
                          style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                  trailing: Icon(Icons.arrow_forward_ios,
                      color: Colors.white54, size: 16),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AutoDetailDialog(auto: auto),
                    );
                  },
                ),
              )),
          SizedBox(height: 24),
          Text("Engins",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          ...engins.map((engin) => Card(
                color: Color(0xFF223C4A),
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading:
                      Icon(Icons.precision_manufacturing, color: Colors.white),
                  title: Text("${engin['nom']}",
                      style: TextStyle(color: Colors.white)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Type : ${engin['type']}",
                          style: TextStyle(color: Colors.white70)),
                      Text("N° série : ${engin['numero_serie']}",
                          style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                  trailing: Icon(Icons.arrow_forward_ios,
                      color: Colors.white54, size: 16),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => EnginDetailDialog(engin: engin),
                    );
                  },
                ),
              )),
        ],
      ),
    );
  }
}

class AutoDetailDialog extends StatelessWidget {
  final Map<String, dynamic> auto;
  const AutoDetailDialog({required this.auto});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Color(0xFF223C4A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text("Détail véhicule", style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Plaque : ${auto['plaque']}",
              style: TextStyle(color: Colors.white70)),
          Text("Marque : ${auto['marque']}",
              style: TextStyle(color: Colors.white70)),
          Text("Modèle : ${auto['modele']}",
              style: TextStyle(color: Colors.white70)),
          Text("Chauffeur : ${auto['chauffeur']}",
              style: TextStyle(color: Colors.white70)),
          Text("Permis : ${auto['permis']}",
              style: TextStyle(color: Colors.white70)),
          Text("Carte grise : ${auto['carte_grise']}",
              style: TextStyle(color: Colors.white70)),
          Text("Assurance : ${auto['assurance']}",
              style: TextStyle(color: Colors.white70)),
          SizedBox(height: 12),
          Text("Documents :",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ...((auto['documents'] as List).map((doc) => Row(
                children: [
                  Icon(Icons.insert_drive_file,
                      color: Colors.white54, size: 18),
                  SizedBox(width: 4),
                  Text("${doc['type']}",
                      style: TextStyle(color: Colors.white54)),
                ],
              ))),
        ],
      ),
      actions: [
        TextButton(
          child: Text("Fermer", style: TextStyle(color: Colors.white)),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}

class EnginDetailDialog extends StatelessWidget {
  final Map<String, dynamic> engin;
  const EnginDetailDialog({required this.engin});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Color(0xFF223C4A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text("Détail engin", style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Nom : ${engin['nom']}",
              style: TextStyle(color: Colors.white70)),
          Text("Type : ${engin['type']}",
              style: TextStyle(color: Colors.white70)),
          Text("N° série : ${engin['numero_serie']}",
              style: TextStyle(color: Colors.white70)),
          Text("Carte grise : ${engin['carte_grise']}",
              style: TextStyle(color: Colors.white70)),
          Text("Assurance : ${engin['assurance']}",
              style: TextStyle(color: Colors.white70)),
          SizedBox(height: 12),
          Text("Documents :",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ...((engin['documents'] as List).map((doc) => Row(
                children: [
                  Icon(Icons.insert_drive_file,
                      color: Colors.white54, size: 18),
                  SizedBox(width: 4),
                  Text("${doc['type']}",
                      style: TextStyle(color: Colors.white54)),
                ],
              ))),
        ],
      ),
      actions: [
        TextButton(
          child: Text("Fermer", style: TextStyle(color: Colors.white)),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
