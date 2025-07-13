import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class InventaireStockScreen extends StatefulWidget {
  const InventaireStockScreen({Key? key}) : super(key: key);

  @override
  State<InventaireStockScreen> createState() => _InventaireStockScreenState();
}

class _InventaireStockScreenState extends State<InventaireStockScreen> {
  final List<String> categories = [
    "Carburant",
    "Matériau de construction",
    "Outil à main",
    "Mobilier",
    "Informatique",
    "Divers",
  ];

  List<Map<String, dynamic>> inventaires = [
    {
      "date": DateTime(2025, 7, 10),
      "categorie": "Carburant",
      "designation": "Gasoil",
      "quantite": 1200,
      "emplacement": "Citerne principale",
      "photo": null,
      "qrcode": "INV-20250710-001",
    },
    {
      "date": DateTime(2025, 7, 12),
      "categorie": "Mobilier",
      "designation": "Chaise de bureau",
      "quantite": 10,
      "emplacement": "Bureau direction",
      "photo": null,
      "qrcode": "INV-20250712-002",
    },
  ];

  DateTime? _selectedDate;

  void _ajouterInventaire() async {
    DateTime date = DateTime.now();
    String? selectedCategorie = categories.first;
    final designationController = TextEditingController();
    final quantiteController = TextEditingController();
    final emplacementController = TextEditingController();
    XFile? photo;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: Color(0xFF223C4A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Nouvel inventaire", style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  children: [
                    Text("Date :", style: TextStyle(color: Colors.white)),
                    SizedBox(width: 8),
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: Colors.green),
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
                        if (picked != null) setStateDialog(() => date = picked);
                      },
                    ),
                  ],
                ),
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
                              child: Text(cat, style: TextStyle(color: Colors.white)),
                            ))
                        .toList(),
                    onChanged: (val) => setStateDialog(() => selectedCategorie = val),
                  ),
                ),
                _textField("Désignation", designationController),
                _textField("Quantité", quantiteController, isNumber: true),
                _textField("Emplacement", emplacementController),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.camera_alt, color: Colors.white70),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        photo == null ? "Aucune photo" : "Photo ajoutée",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: Colors.green),
                      child: Text("Prendre photo"),
                      onPressed: () async {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(source: ImageSource.camera);
                        if (picked != null) setStateDialog(() => photo = picked);
                      },
                    ),
                  ],
                ),
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
                final qrcode = "INV-${DateFormat('yyyyMMdd').format(date)}-${inventaires.length + 1}";
                setState(() {
                  inventaires.add({
                    "date": date,
                    "categorie": selectedCategorie ?? "",
                    "designation": designationController.text,
                    "quantite": int.tryParse(quantiteController.text) ?? 0,
                    "emplacement": emplacementController.text,
                    "photo": photo,
                    "qrcode": qrcode,
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

  List<Map<String, dynamic>> get _inventairesFiltres {
    if (_selectedDate == null) return inventaires;
    return inventaires.where((inv) =>
      inv['date'].year == _selectedDate!.year &&
      inv['date'].month == _selectedDate!.month &&
      inv['date'].day == _selectedDate!.day
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF17333F),
      appBar: AppBar(
        backgroundColor: Color(0xFF17333F),
        title: Text("Inventaire de stock"),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_alt, color: Colors.white),
            tooltip: "Filtrer par date",
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                builder: (context, child) => Theme(
                  data: ThemeData.dark(),
                  child: child!,
                ),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
          ),
          IconButton(
            icon: Icon(Icons.clear, color: Colors.white),
            tooltip: "Réinitialiser le filtre",
            onPressed: () => setState(() => _selectedDate = null),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.inventory, color: Colors.greenAccent),
                SizedBox(width: 8),
                Text(
                  _selectedDate == null
                      ? "Tous les inventaires"
                      : "Inventaires du ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                  style: TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ],
            ),
          ),
          Expanded(
            child: _inventairesFiltres.isEmpty
                ? Center(child: Text("Aucun inventaire", style: TextStyle(color: Colors.white54)))
                : ListView.separated(
                    padding: EdgeInsets.all(16),
                    itemCount: _inventairesFiltres.length,
                    separatorBuilder: (_, __) => Divider(color: Colors.white24),
                    itemBuilder: (context, index) {
                      final inv = _inventairesFiltres[index];
                      return Card(
                        color: Color(0xFF223C4A),
                        child: ListTile(
                          leading: inv['photo'] == null
                              ? Icon(Icons.inventory, color: Colors.greenAccent)
                              : GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => Dialog(
                                        backgroundColor: Colors.black,
                                        child: Image.file(File(inv['photo'].path)),
                                      ),
                                    );
                                  },
                                  child: CircleAvatar(
                                    backgroundImage: FileImage(File(inv['photo'].path)),
                                    radius: 22,
                                  ),
                                ),
                          title: Text(inv['designation'],
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Catégorie : ${inv['categorie']}", style: TextStyle(color: Colors.white70)),
                              Text("Quantité : ${inv['quantite']}", style: TextStyle(color: Colors.white70)),
                              Text("Emplacement : ${inv['emplacement']}", style: TextStyle(color: Colors.white70)),
                              Text("Date : ${DateFormat('dd/MM/yyyy').format(inv['date'])}", style: TextStyle(color: Colors.white70)),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  QrImageView(
                                    data: inv['qrcode'],
                                    size: 48,
                                    backgroundColor: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text("QR Code", style: TextStyle(color: Colors.greenAccent)),
                                ],
                              ),
                            ],
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
        onPressed: _ajouterInventaire,
        tooltip: "Nouvel inventaire",
      ),
    );
  }
}