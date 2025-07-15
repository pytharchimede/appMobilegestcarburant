import 'package:flutter/material.dart';
import '../services/api_services.dart';

class MaterielScreen extends StatefulWidget {
  const MaterielScreen({Key? key}) : super(key: key);

  @override
  State<MaterielScreen> createState() => _MaterielScreenState();
}

class _MaterielScreenState extends State<MaterielScreen> {
  final ApiService apiService = ApiService();
  List<Map<String, dynamic>> materiels = [];
  List<Map<String, dynamic>> categories = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      categories = await apiService.fetchMaterielCategories();
      materiels = await apiService.fetchMateriels();
    } catch (e) {
      error = e.toString();
    }
    setState(() {
      isLoading = false;
    });
  }

  void _ajouterMateriel() async {
    final nomController = TextEditingController();
    String? selectedCategorie = categories.isNotEmpty ? categories.first['libelle'] : null;
    final etatController = TextEditingController();
    final quantiteController = TextEditingController();
    final emplacementController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Color(0xFF223C4A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Ajouter un matériel", style: TextStyle(color: Colors.white)),
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
                            child: Text(cat['libelle'] as String, style: TextStyle(color: Colors.white)),
                          ))
                      .toList(),
                  onChanged: (val) {
                    selectedCategorie = val;
                  },
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
            onPressed: () async {
              try {
                final ok = await apiService.ajouterMateriel(
                  nom: nomController.text,
                  categorie: selectedCategorie ?? "",
                  etat: etatController.text,
                  quantite: int.tryParse(quantiteController.text) ?? 1,
                  emplacement: emplacementController.text,
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
    );
  }

  Widget _textField(String label, TextEditingController controller, {bool isNumber = false}) {
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
        title: Text("Matériel"),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.white))
          : error != null
              ? Center(child: Text(error!, style: TextStyle(color: Colors.redAccent)))
              : materiels.isEmpty
                  ? Center(child: Text("Aucun matériel", style: TextStyle(color: Colors.white54)))
                  : ListView.separated(
                      padding: EdgeInsets.all(16),
                      itemCount: materiels.length,
                      separatorBuilder: (_, __) => Divider(color: Colors.white24),
                      itemBuilder: (context, index) {
                        final m = materiels[index];
                        return Card(
                          color: Color(0xFF223C4A),
                          child: ListTile(
                            leading: Icon(Icons.handyman, color: Colors.greenAccent),
                            title: Text(m['nom'], style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Catégorie : ${m['categorie']}", style: TextStyle(color: Colors.white70)),
                                Text("État : ${m['etat']}", style: TextStyle(color: Colors.white70)),
                                Text("Quantité : ${m['quantite']}", style: TextStyle(color: Colors.white70)),
                                Text("Emplacement : ${m['emplacement']}", style: TextStyle(color: Colors.white70)),
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
        tooltip: "Ajouter un matériel",
      ),
    );
  }
}
