import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_services.dart';

class BonEntreeScreen extends StatefulWidget {
  const BonEntreeScreen({Key? key}) : super(key: key);

  @override
  State<BonEntreeScreen> createState() => _BonEntreeScreenState();
}

class _BonEntreeScreenState extends State<BonEntreeScreen> {
  final ApiService apiService = ApiService();
  List<Map<String, dynamic>> chantiers = [];
  List<String> categories = [];
  List<Map<String, dynamic>> bons = [];

  final List<String> affectations = [
    "En stock",
    "Sur chantier",
    "Pour le bureau",
    "Autre",
  ];

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      chantiers = await apiService.fetchChantiers();
      categories = await apiService.fetchBonEntreeCategories();
      bons = await apiService.fetchBonsEntree();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur chargement : $e")),
      );
    }
    setState(() => isLoading = false);
  }

  void _ajouterBon() async {
    print("ouvrir formulaire");
    print("categories: $categories");
    print("chantiers: $chantiers");

    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Aucune catégorie disponible")),
      );
      return;
    }
    if (chantiers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Aucun chantier disponible")),
      );
      return;
    }

    final numeroController = TextEditingController();
    DateTime date = DateTime.now();
    final fournisseurController = TextEditingController();
    String? selectedCategorie = categories.first;
    String? selectedAffectation = affectations.first;
    int? selectedChantierId = int.tryParse(chantiers.first['id'].toString());
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
          title: Text("Nouveau bon d'entrée",
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
                _textField("Fournisseur", fournisseurController),
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
                      // ...
                      items: chantiers
                          .map((chantier) => DropdownMenuItem<int>(
                                value: int.tryParse(chantier['id'].toString()),
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
              onPressed: () async {
                try {
                  final ok = await apiService.ajouterBonEntree(
                    numero: numeroController.text,
                    date: date,
                    fournisseur: fournisseurController.text,
                    categorie: selectedCategorie ?? "",
                    quantite: int.tryParse(quantiteController.text) ?? 0,
                    piece: pieceJointe,
                    commentaire: commentaireController.text,
                    affectation: selectedAffectation ?? "",
                    chantierId: selectedAffectation == "Sur chantier"
                        ? selectedChantierId
                        : null,
                  );
                  if (ok) {
                    Navigator.pop(context);
                    await _loadData();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Erreur lors de l'ajout")),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Erreur API : $e")),
                  );
                }
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
        title: Text("Bons d'entrée"),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : bons.isEmpty
              ? Center(
                  child: Text("Aucun bon d'entrée",
                      style: TextStyle(color: Colors.white54)))
              : ListView.separated(
                  padding: EdgeInsets.all(16),
                  itemCount: bons.length,
                  separatorBuilder: (_, __) => Divider(color: Colors.white24),
                  itemBuilder: (context, index) {
                    final b = bons[index];
                    final date =
                        DateTime.tryParse(b['date'] ?? "") ?? DateTime.now();
                    return Card(
                      color: Color(0xFF223C4A),
                      child: ListTile(
                        leading: Icon(Icons.input, color: Colors.greenAccent),
                        title: Text(
                          b['numero'] ?? "",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                "Date : ${date.day}/${date.month}/${date.year}",
                                style: TextStyle(color: Colors.white70)),
                            Text("Fournisseur : ${b['fournisseur'] ?? ""}",
                                style: TextStyle(color: Colors.white70)),
                            Text("Catégorie : ${b['categorie'] ?? ""}",
                                style: TextStyle(color: Colors.white70)),
                            Text("Quantité : ${b['quantite'] ?? ""}",
                                style: TextStyle(color: Colors.white70)),
                            Text(
                              "Affectation : ${b['affectation'] ?? ""}" +
                                  ((b['affectation'] == "Sur chantier" &&
                                          b['chantier_id'] != null)
                                      ? " (${_libelleChantier(b['chantier_id'])})"
                                      : ""),
                              style: TextStyle(color: Colors.white70),
                            ),
                            if ((b['commentaire'] ?? '').toString().isNotEmpty)
                              Text("Commentaire : ${b['commentaire']}",
                                  style: TextStyle(color: Colors.white54)),
                            if (b['piece'] != null &&
                                b['piece'].toString().isNotEmpty)
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
                        onTap: (b['piece'] != null &&
                                b['piece'].toString().isNotEmpty)
                            ? () {
                                showDialog(
                                  context: context,
                                  builder: (_) => Dialog(
                                    backgroundColor: Colors.black,
                                    child: Image.network(
                                      // Adapte l'URL selon ton API
                                      'https://fidest.ci/decaissement/uploads/${b['piece']}',
                                      errorBuilder: (_, __, ___) => Center(
                                          child: Text("Image non disponible",
                                              style: TextStyle(
                                                  color: Colors.white))),
                                    ),
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
        onPressed:
            (categories.isEmpty || chantiers.isEmpty) ? null : _ajouterBon,
        tooltip: "Ajouter un bon d'entrée",
      ),
    );
  }
}
