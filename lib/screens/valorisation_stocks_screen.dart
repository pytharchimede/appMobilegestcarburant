import 'package:flutter/material.dart';
import '../services/api_services.dart';

class ValorisationStocksScreen extends StatefulWidget {
  const ValorisationStocksScreen({Key? key}) : super(key: key);

  @override
  State<ValorisationStocksScreen> createState() =>
      _ValorisationStocksScreenState();
}

class _ValorisationStocksScreenState extends State<ValorisationStocksScreen> {
  final ApiService apiService = ApiService();
  List<Map<String, dynamic>> stocks = [];
  List<Map<String, dynamic>> categories = [];
  int totalStockValue = 0;
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
      final result = await apiService.fetchValorisationStocks();
      stocks = result['stocks'];
      totalStockValue = result['total'] ?? 0;
      categories = await apiService.fetchStockCategories();
    } catch (e) {
      error = e.toString();
    }
    setState(() {
      isLoading = false;
    });
  }

  void _ajouterOuModifierStock({Map<String, dynamic>? stock}) async {
    final designationController =
        TextEditingController(text: stock?['designation'] ?? '');
    final quantiteController =
        TextEditingController(text: stock?['quantite']?.toString() ?? '');
    final prixUnitaireController =
        TextEditingController(text: stock?['prix_unitaire']?.toString() ?? '');
    final emplacementController =
        TextEditingController(text: stock?['emplacement'] ?? '');
    String? selectedCategorie = stock?['categorie'] ??
        (categories.isNotEmpty ? categories.first['libelle'] : null);

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: Color(0xFF223C4A),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            stock == null ? "Ajouter un stock" : "Modifier le stock",
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCategorie,
                  dropdownColor: Color(0xFF223C4A),
                  decoration: InputDecoration(
                    labelText: "Catégorie",
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                  style: TextStyle(color: Colors.white),
                  items: categories
                      .map((cat) => DropdownMenuItem<String>(
                            value: cat['libelle'],
                            child: Text(cat['libelle'],
                                style: TextStyle(color: Colors.white)),
                          ))
                      .toList(),
                  onChanged: (val) =>
                      setStateDialog(() => selectedCategorie = val),
                ),
                _textField("Désignation", designationController),
                _textField("Quantité", quantiteController, isNumber: true),
                _textField("Prix unitaire", prixUnitaireController,
                    isNumber: true),
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
              child: Text(stock == null ? "Ajouter" : "Modifier"),
              onPressed: () async {
                try {
                  final ok = await apiService.ajouterOuModifierStock(
                    id: stock?['id'],
                    categorie: selectedCategorie ?? "",
                    designation: designationController.text,
                    quantite: int.tryParse(quantiteController.text) ?? 0,
                    prixUnitaire:
                        int.tryParse(prixUnitaireController.text) ?? 0,
                    emplacement: emplacementController.text,
                  );
                  if (ok) {
                    Navigator.pop(context);
                    await _loadData();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text("Erreur lors de l'enregistrement")),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF17333F),
      appBar: AppBar(
        backgroundColor: Color(0xFF17333F),
        title: Text("Valorisation des stocks"),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.white))
          : error != null
              ? Center(
                  child:
                      Text(error!, style: TextStyle(color: Colors.redAccent)))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.stacked_bar_chart,
                              color: Colors.greenAccent),
                          SizedBox(width: 8),
                          Text(
                            "Total stock : $totalStockValue FCFA",
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
                        separatorBuilder: (_, __) =>
                            Divider(color: Colors.white24),
                        itemBuilder: (context, index) {
                          final s = stocks[index];
                          final quantite =
                              int.tryParse(s['quantite'].toString()) ?? 0;
                          final prixUnitaire =
                              int.tryParse(s['prix_unitaire'].toString()) ?? 0;
                          final montant = quantite * prixUnitaire;
                          return Card(
                            color: Color(0xFF223C4A),
                            child: ListTile(
                              leading: Icon(Icons.inventory,
                                  color: Colors.greenAccent),
                              title: Text(
                                s['designation'],
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Catégorie : ${s['categorie']}",
                                      style: TextStyle(color: Colors.white70)),
                                  Text("Quantité : $quantite",
                                      style: TextStyle(color: Colors.white70)),
                                  Text("Prix unitaire : $prixUnitaire FCFA",
                                      style: TextStyle(color: Colors.white70)),
                                  Text("Montant : $montant FCFA",
                                      style: TextStyle(
                                          color: Colors.greenAccent,
                                          fontWeight: FontWeight.bold)),
                                  Text("Emplacement : ${s['emplacement']}",
                                      style: TextStyle(color: Colors.white70)),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.edit, color: Colors.white70),
                                onPressed: () =>
                                    _ajouterOuModifierStock(stock: s),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: Icon(Icons.add),
        onPressed: categories.isEmpty ? null : () => _ajouterOuModifierStock(),
        tooltip: "Ajouter un stock",
      ),
    );
  }
}
