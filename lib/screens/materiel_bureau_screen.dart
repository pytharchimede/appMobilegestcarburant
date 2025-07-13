import 'package:flutter/material.dart';

class MaterielBureauScreen extends StatefulWidget {
  const MaterielBureauScreen({Key? key}) : super(key: key);

  @override
  State<MaterielBureauScreen> createState() => _MaterielBureauScreenState();
}

class _MaterielBureauScreenState extends State<MaterielBureauScreen> {
  // Liste JSON simulée pour les catégories
  final List<Map<String, dynamic>> categories = [
    {"id": 1, "libelle": "Mobilier"},
    {"id": 2, "libelle": "Informatique"},
    {"id": 3, "libelle": "Papeterie"},
    {"id": 4, "libelle": "Accessoire"},
  ];

  List<Map<String, dynamic>> materiels = [
    {
      "nom": "Chaise ergonomique",
      "categorie": "Mobilier",
      "etat": "Disponible",
      "quantite": 10,
      "emplacement": "Bureau direction",
    },
    {
      "nom": "Ordinateur portable HP",
      "categorie": "Informatique",
      "etat": "En maintenance",
      "quantite": 2,
      "emplacement": "Salle informatique",
    },
  ];

  void _ajouterMateriel() async {
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
        title: Text("Ajouter un matériel de bureau",
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
                materiels.add({
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
        title: Text("Matériel de bureau"),
      ),
      body: materiels.isEmpty
          ? Center(
              child: Text("Aucun matériel de bureau",
                  style: TextStyle(color: Colors.white54)))
          : ListView.separated(
              padding: EdgeInsets.all(16),
              itemCount: materiels.length,
              separatorBuilder: (_, __) => Divider(color: Colors.white24),
              itemBuilder: (context, index) {
                final m = materiels[index];
                return Card(
                  color: Color(0xFF223C4A),
                  child: ListTile(
                    leading: Icon(Icons.chair, color: Colors.greenAccent),
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
        onPressed: _ajouterMateriel,
        tooltip: "Ajouter un matériel de bureau",
      ),
    );
  }
}
