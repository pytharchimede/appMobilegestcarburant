import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class BonSortieScreen extends StatefulWidget {
  const BonSortieScreen({Key? key}) : super(key: key);

  @override
  State<BonSortieScreen> createState() => _BonSortieScreenState();
}

class _BonSortieScreenState extends State<BonSortieScreen> {
  // Liste de chantiers simulés
  final List<Map<String, dynamic>> chantiers = [
    {"id": 1, "libelle": "Chantier Siège"},
    {"id": 2, "libelle": "Chantier Annexe"},
    {"id": 3, "libelle": "Chantier Extension"},
  ];

  // Données de test pour les bons de sortie
  List<Map<String, dynamic>> bons = [
    {
      "numero": "BS-2025-001",
      "date": DateTime(2025, 7, 15),
      "beneficiaire": "Equipe chantier A",
      "categorie": "Ciment",
      "quantite": 20,
      "motif": "Consommation chantier",
      "piece": null,
      "commentaire": "Sortie validée",
      "affectation": "Sur chantier",
      "chantierId": 1,
    },
    {
      "numero": "BS-2025-002",
      "date": DateTime(2025, 7, 16),
      "beneficiaire": "Bureau",
      "categorie": "Papier",
      "quantite": 5,
      "motif": "Usage bureau",
      "piece": null,
      "commentaire": "",
      "affectation": "Pour le bureau",
      "chantierId": null,
    },
  ];

  final List<String> categories = [
    "Carburant",
    "Ciment",
    "Fer à béton",
    "Outils",
    "Papier",
    "Divers",
  ];

  final List<String> affectations = [
    "En stock",
    "Sur chantier",
    "Pour le bureau",
    "Autre",
  ];

  final List<String> motifs = [
    "Consommation chantier",
    "Usage bureau",
    "Transfert",
    "Retour fournisseur",
    "Autre",
  ];

  void _ajouterBon() async {
    final numeroController = TextEditingController();
    DateTime date = DateTime.now();
    final beneficiaireController = TextEditingController();
    String? selectedCategorie = categories.first;
    String? selectedAffectation = affectations.first;
    int? selectedChantierId = chantiers.first['id'];
    String? selectedMotif = motifs.first;
    final quantiteController = TextEditingController();
    final commentaireController = TextEditingController();
    XFile? pieceJointe;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: Color(0xFF223C4A),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Nouveau bon de sortie",
              style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _textField("Numéro du bon", numeroController),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Text("Date :", style: TextStyle(color: Colors.white)),
                      SizedBox(width: 8),
                      TextButton(
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.green),
                        child: Text("${date.day}/${date.month}/${date.year}"),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: date,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            builder: (context, child) => Theme(
                              data: ThemeData.dark(),
                              child: child!,
                            ),
                          );
                          if (picked != null)
                            setStateDialog(() => date = picked);
                        },
                      ),
                    ],
                  ),
                ),
                _textField("Bénéficiaire", beneficiaireController),
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
                              value: cat,
                              child: Text(cat,
                                  style: TextStyle(color: Colors.white)),
                            ))
                        .toList(),
                    onChanged: (val) =>
                        setStateDialog(() => selectedCategorie = val),
                  ),
                ),
                _textField("Quantité", quantiteController, isNumber: true),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: DropdownButtonFormField<String>(
                    value: selectedMotif,
                    dropdownColor: Color(0xFF223C4A),
                    decoration: InputDecoration(
                      labelText: "Motif de sortie",
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                    style: TextStyle(color: Colors.white),
                    items: motifs
                        .map((motif) => DropdownMenuItem<String>(
                              value: motif,
                              child: Text(motif,
                                  style: TextStyle(color: Colors.white)),
                            ))
                        .toList(),
                    onChanged: (val) =>
                        setStateDialog(() => selectedMotif = val),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: DropdownButtonFormField<String>(
                    value: selectedAffectation,
                    dropdownColor: Color(0xFF223C4A),
                    decoration: InputDecoration(
                      labelText: "Affectation",
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                    style: TextStyle(color: Colors.white),
                    items: affectations
                        .map((aff) => DropdownMenuItem<String>(
                              value: aff,
                              child: Text(aff,
                                  style: TextStyle(color: Colors.white)),
                            ))
                        .toList(),
                    onChanged: (val) =>
                        setStateDialog(() => selectedAffectation = val),
                  ),
                ),
                if (selectedAffectation == "Sur chantier")
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: DropdownButtonFormField<int>(
                      value: selectedChantierId,
                      dropdownColor: Color(0xFF223C4A),
                      decoration: InputDecoration(
                        labelText: "Chantier",
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      style: TextStyle(color: Colors.white),
                      items: chantiers
                          .map((chantier) => DropdownMenuItem<int>(
                                value: chantier['id'],
                                child: Text(chantier['libelle'],
                                    style: TextStyle(color: Colors.white)),
                              ))
                          .toList(),
                      onChanged: (val) =>
                          setStateDialog(() => selectedChantierId = val),
                    ),
                  ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.attachment, color: Colors.white70),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pieceJointe == null
                            ? "Aucune pièce jointe"
                            : "Pièce jointe ajoutée",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    TextButton(
                      style:
                          TextButton.styleFrom(foregroundColor: Colors.green),
                      child: Text("Scanner"),
                      onPressed: () async {
                        final picker = ImagePicker();
                        final picked =
                            await picker.pickImage(source: ImageSource.camera);
                        if (picked != null)
                          setStateDialog(() => pieceJointe = picked);
                      },
                    ),
                  ],
                ),
                _textField("Commentaire", commentaireController),
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
                  bons.add({
                    "numero": numeroController.text,
                    "date": date,
                    "beneficiaire": beneficiaireController.text,
                    "categorie": selectedCategorie ?? "",
                    "quantite": int.tryParse(quantiteController.text) ?? 0,
                    "motif": selectedMotif ?? "",
                    "piece": pieceJointe,
                    "commentaire": commentaireController.text,
                    "affectation": selectedAffectation,
                    "chantierId": selectedAffectation == "Sur chantier"
                        ? selectedChantierId
                        : null,
                  });
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
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

  String? _libelleChantier(int? id) {
    if (id == null) return null;
    final chantier = chantiers.firstWhere(
      (c) => c['id'] == id,
      orElse: () => {},
    );
    return chantier['libelle'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF17333F),
      appBar: AppBar(
        backgroundColor: Color(0xFF17333F),
        title: Text("Bons de sortie"),
      ),
      body: bons.isEmpty
          ? Center(
              child: Text("Aucun bon de sortie",
                  style: TextStyle(color: Colors.white54)))
          : ListView.separated(
              padding: EdgeInsets.all(16),
              itemCount: bons.length,
              separatorBuilder: (_, __) => Divider(color: Colors.white24),
              itemBuilder: (context, index) {
                final b = bons[index];
                return Card(
                  color: Color(0xFF223C4A),
                  child: ListTile(
                    leading: Icon(Icons.output, color: Colors.greenAccent),
                    title: Text(b['numero'],
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            "Date : ${b['date'].day}/${b['date'].month}/${b['date'].year}",
                            style: TextStyle(color: Colors.white70)),
                        Text("Bénéficiaire : ${b['beneficiaire']}",
                            style: TextStyle(color: Colors.white70)),
                        Text("Catégorie : ${b['categorie']}",
                            style: TextStyle(color: Colors.white70)),
                        Text("Quantité : ${b['quantite']}",
                            style: TextStyle(color: Colors.white70)),
                        Text("Motif : ${b['motif']}",
                            style: TextStyle(color: Colors.white70)),
                        Text(
                          "Affectation : ${b['affectation']}" +
                              (b['affectation'] == "Sur chantier" &&
                                      b['chantierId'] != null
                                  ? " (${_libelleChantier(b['chantierId'])})"
                                  : ""),
                          style: TextStyle(color: Colors.white70),
                        ),
                        if ((b['commentaire'] ?? '').isNotEmpty)
                          Text("Commentaire : ${b['commentaire']}",
                              style: TextStyle(color: Colors.white54)),
                        if (b['piece'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              children: [
                                Icon(Icons.image,
                                    color: Colors.greenAccent, size: 18),
                                SizedBox(width: 4),
                                Text("Scan disponible",
                                    style: TextStyle(
                                        color: Colors.greenAccent,
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                      ],
                    ),
                    onTap: b['piece'] != null
                        ? () {
                            showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                backgroundColor: Colors.black,
                                child: Image.file(File(b['piece'].path)),
                              ),
                            );
                          }
                        : null,
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: Icon(Icons.add),
        onPressed: _ajouterBon,
        tooltip: "Ajouter un bon de sortie",
      ),
    );
  }
}
