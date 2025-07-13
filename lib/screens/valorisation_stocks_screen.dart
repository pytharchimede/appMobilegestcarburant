import 'package:flutter/material.dart';

class ValorisationStocksScreen extends StatelessWidget {
  ValorisationStocksScreen({Key? key}) : super(key: key);

  // Données de test pour les stocks
  final List<Map<String, dynamic>> stocks = [
    {
      "categorie": "Carburant",
      "designation": "Gasoil",
      "quantite": 1200,
      "prixUnitaire": 850,
      "emplacement": "Citerne principale",
    },
    {
      "categorie": "Matériau de construction",
      "designation": "Ciment 50kg",
      "quantite": 80,
      "prixUnitaire": 6500,
      "emplacement": "Magasin principal",
    },
    {
      "categorie": "Outil à main",
      "designation": "Marteau Stanley",
      "quantite": 10,
      "prixUnitaire": 3500,
      "emplacement": "Atelier",
    },
    {
      "categorie": "Mobilier",
      "designation": "Chaise de bureau",
      "quantite": 15,
      "prixUnitaire": 18000,
      "emplacement": "Bureau direction",
    },
  ];

  int get totalStockValue => stocks.fold(
      0,
      (sum, item) =>
          sum + (item['quantite'] as int) * (item['prixUnitaire'] as int));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF17333F),
      appBar: AppBar(
        backgroundColor: Color(0xFF17333F),
        title: Text("Valorisation des stocks"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.stacked_bar_chart, color: Colors.greenAccent),
                SizedBox(width: 8),
                Text(
                  "Total stock : ${totalStockValue.toStringAsFixed(0)} FCFA",
                  style: TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.all(16),
              itemCount: stocks.length,
              separatorBuilder: (_, __) => Divider(color: Colors.white24),
              itemBuilder: (context, index) {
                final s = stocks[index];
                final montant =
                    (s['quantite'] as int) * (s['prixUnitaire'] as int);
                return Card(
                  color: Color(0xFF223C4A),
                  child: ListTile(
                    leading: Icon(Icons.inventory, color: Colors.greenAccent),
                    title: Text(
                      s['designation'],
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Catégorie : ${s['categorie']}",
                            style: TextStyle(color: Colors.white70)),
                        Text("Quantité : ${s['quantite']}",
                            style: TextStyle(color: Colors.white70)),
                        Text("Prix unitaire : ${s['prixUnitaire']} FCFA",
                            style: TextStyle(color: Colors.white70)),
                        Text("Montant : $montant FCFA",
                            style: TextStyle(
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.bold)),
                        Text("Emplacement : ${s['emplacement']}",
                            style: TextStyle(color: Colors.white70)),
                      ],
                    ),
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