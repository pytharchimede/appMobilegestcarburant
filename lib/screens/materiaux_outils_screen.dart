import 'package:flutter/material.dart';

class MateriauxOutilsScreen extends StatefulWidget {
  const MateriauxOutilsScreen({Key? key}) : super(key: key);

  @override
  State<MateriauxOutilsScreen> createState() => _MateriauxOutilsScreenState();
}

class _MateriauxOutilsScreenState extends State<MateriauxOutilsScreen> {
  // Liste JSON simulée pour les catégories
  final List<Map<String, dynamic>> categories = [
    {"id": 1, "libelle": "Matériau de construction"},
    {"id": 2, "libelle": "Outil à main"},
    {"id": 3, "libelle": "Outil électrique"},
    {"id": 4, "libelle": "Consommable"},
  ];

  List<Map<String, dynamic>> materiaux = [
    {
      "nom": "Ciment 50kg",
      "categorie": "Matériau de construction",
      "etat": "Stocké",
      "quantite": 20,
      "emplacement": "Magasin principal",
    },
    {
      "nom": "Marteau Stanley",
      "categorie": "Outil à main",
      "etat": "Disponible",
      "quantite": 5,
      "emplacement": "Atelier",
    },
  ];

  void _ajouterMateriau() async {
    final nomController = TextEditingController();
    String? selectedCategorie = categories.first['libelle'];
    final etatController = TextEditingController();
    final quantiteController = TextEditingController();
    final emplacementController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Color(0xFF223C4A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Ajouter un matériau/outil",
            style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _textField("Nom", nomController),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: DropdownButtonFormField<String>(
                  value: selectedCategorie,
                  dropdownColor: Color(0xFF223C4A),
                  decoration: InputDecoration(
                    labelText: "Catégorie",
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                  style: TextStyle(color: Colors.white),
                  items: categories
                      .map((cat) => DropdownMenuItem<String>(
                            value: cat['libelle'] as String,
                            child: Text(cat['libelle'] as String,
                                style: TextStyle(color: Colors.white)),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => selectedCategorie = val),
                ),
              ),
              _textField("État", etatController),
              _textField("Quantité", quantiteController, isNumber: true),
              _textField("Emplacement", emplacementController),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text("Annuler", style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text("Ajouter"),
            onPressed: () {
              setState(() {
                materiaux.add({
                  "nom": nomController.text,
                  "categorie": selectedCategorie ?? "",
                  "etat": etatController.text,
                  "quantite": int.tryParse(quantiteController.text) ?? 1,
                  "emplacement": emplacementController.text,
                });
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _textField(String label, TextEditingController controller,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white),
        ),
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF17333F),
      appBar: AppBar(
        backgroundColor: Color(0xFF17333F),
        title: Text("Matériaux & Outils"),
      ),
      body: materiaux.isEmpty
          ? Center(
              child: Text("Aucun matériau ou outil",
                  style: TextStyle(color: Colors.white54)))
          : ListView.separated(
              padding: EdgeInsets.all(16),
              itemCount: materiaux.length,
              separatorBuilder: (_, __) => Divider(color: Colors.white24),
              itemBuilder: (context, index) {
                final m = materiaux[index];
                return Card(
                  color: Color(0xFF223C4A),
                  child: ListTile(
                    leading:
                        Icon(Icons.construction, color: Colors.greenAccent),
                    title: Text(m['nom'],
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Catégorie : ${m['categorie']}",
                            style: TextStyle(color: Colors.white70)),
                        Text("État : ${m['etat']}",
                            style: TextStyle(color: Colors.white70)),
                        Text("Quantité : ${m['quantite']}",
                            style: TextStyle(color: Colors.white70)),
                        Text("Emplacement : ${m['emplacement']}",
                            style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: Icon(Icons.add),
        onPressed: _ajouterMateriau,
        tooltip: "Ajouter un matériau ou outil",
      ),
    );
  }
}
