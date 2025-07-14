import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_services.dart';

class ParcAutoScreen extends StatefulWidget {
  @override
  State<ParcAutoScreen> createState() => _ParcAutoScreenState();
}

class _ParcAutoScreenState extends State<ParcAutoScreen> {
  List<Map<String, dynamic>> autos = [];
  List<Map<String, dynamic>> engins = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVehicules();
  }

  Future<void> _loadVehicules() async {
    setState(() => isLoading = true);
    try {
      final api = ApiService();
      final vehicules = await api.fetchVehicules(); // À ajouter dans ApiService
      setState(() {
        autos = vehicules
            .where((v) => v['type'] == 'Véhicule' || v['type'] == 'Camion')
            .toList();
        engins = vehicules.where((v) => v['type'] == 'Engin').toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur chargement véhicules : $e")),
      );
    }
    setState(() => isLoading = false);
  }

  Future<void> _ajouterVehicule(Map<String, dynamic> data, bool isEngin) async {
    try {
      final api = ApiService();
      final ok = await api.ajouterVehicule(data); // À ajouter dans ApiService
      if (ok) {
        _loadVehicules();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ajouté avec succès")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur ajout : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF17333F),
      appBar: AppBar(
        backgroundColor: Color(0xFF17333F),
        title: Text("Parc automobile & engins"),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
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
                        leading:
                            Icon(Icons.directions_car, color: Colors.white),
                        title: Text("${auto['marque']} ${auto['modele']}",
                            style: TextStyle(color: Colors.white)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Plaque : ${auto['plaque']}",
                                style: TextStyle(color: Colors.white70)),
                            Text("Chauffeur : ${auto['chauffeur_nom'] ?? ''}",
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
                        leading: Icon(Icons.precision_manufacturing,
                            color: Colors.white),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: Icon(Icons.add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AddParcElementDialog(
              onAdd: (element, isEngin) {
                _ajouterVehicule(element, isEngin);
              },
            ),
          );
        },
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
          Text("Chauffeur : ${auto['chauffeur_nom']}",
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

class AddParcElementDialog extends StatefulWidget {
  final Function(Map<String, dynamic>, bool) onAdd;
  const AddParcElementDialog({required this.onAdd});

  @override
  State<AddParcElementDialog> createState() => _AddParcElementDialogState();
}

class _AddParcElementDialogState extends State<AddParcElementDialog> {
  String type = "Véhicule";
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> data = {};
  XFile? image;
  List<Map<String, dynamic>> documents = [];

  // Pour les listes déroulantes
  List<Map<String, dynamic>> chauffeurs = [];
  List<Map<String, dynamic>> marques = [];
  final List<String> typesEngin = [
    "Pelle",
    "Grue",
    "Nacelle",
    "Bulldozer",
    "Tracteur",
    "Compacteur",
    "Autre"
  ];
  Map<String, dynamic>? selectedChauffeur;
  Map<String, dynamic>? selectedMarque;
  String? selectedTypeEngin;

  bool loadingLists = true;

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  Future<void> _loadLists() async {
    setState(() => loadingLists = true);
    try {
      final api = ApiService();
      final ch = await api.fetchChauffeurs();
      final mq = await api.fetchMarques();
      setState(() {
        chauffeurs = ch;
        marques = mq;
        selectedChauffeur = chauffeurs.isNotEmpty ? chauffeurs.first : null;
        selectedMarque = marques.isNotEmpty ? marques.first : null;
        selectedTypeEngin = typesEngin.first;
      });
    } catch (e) {
      // ignore
    }
    setState(() => loadingLists = false);
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => image = picked);
  }

  Future<void> pickDocImage(int index) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => documents[index]['url'] = picked);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Color(0xFF223C4A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            type == "Engin"
                ? Icons.precision_manufacturing
                : type == "Camion"
                    ? Icons.local_shipping
                    : Icons.directions_car,
            color: Colors.greenAccent,
          ),
          SizedBox(width: 8),
          Text(
            "Ajouter un $type",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: loadingLists
          ? Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: type,
                      dropdownColor: Color(0xFF223C4A),
                      decoration: InputDecoration(
                        labelText: "Type",
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      items: ["Véhicule", "Camion", "Engin"]
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e,
                                    style: TextStyle(color: Colors.white)),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          type = val!;
                          documents.clear();
                        });
                      },
                    ),
                    SizedBox(height: 12),
                    GestureDetector(
                      onTap: pickImage,
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white10,
                        backgroundImage:
                            image != null ? FileImage(File(image!.path)) : null,
                        child: image == null
                            ? Icon(Icons.camera_alt,
                                color: Colors.white54, size: 36)
                            : null,
                      ),
                    ),
                    SizedBox(height: 12),
                    ..._buildFields(),
                    SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Documents :",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                    ...documents.asMap().entries.map((entry) {
                      int i = entry.key;
                      var doc = entry.value;
                      return Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: doc['type'],
                              decoration: InputDecoration(
                                labelText: "Type de document",
                                labelStyle: TextStyle(color: Colors.white),
                              ),
                              style: TextStyle(color: Colors.white),
                              onChanged: (val) => doc['type'] = val,
                              validator: (val) => val == null || val.isEmpty
                                  ? "Obligatoire"
                                  : null,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.attach_file, color: Colors.white),
                            onPressed: () => pickDocImage(i),
                          ),
                          if (doc['url'] != null)
                            Icon(Icons.check_circle, color: Colors.green),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() => documents.removeAt(i));
                            },
                          ),
                        ],
                      );
                    }),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        icon: Icon(Icons.add, color: Colors.white),
                        label: Text("Ajouter un document",
                            style: TextStyle(color: Colors.white)),
                        onPressed: () {
                          setState(
                              () => documents.add({"type": "", "url": null}));
                        },
                      ),
                    ),
                  ],
                ),
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
            if (_formKey.currentState!.validate()) {
              data['type'] = type;
              data['photo_url'] = image?.path ?? "";
              data['documents'] = documents
                  .map((doc) => {
                        "type": doc['type'],
                        "url":
                            doc['url'] is XFile ? doc['url'].path : doc['url']
                      })
                  .toList();
              if (type == "Véhicule" || type == "Camion") {
                data['chauffeur_nom'] = selectedChauffeur?['nom'] ?? "";
                data['marque'] = selectedMarque?['nom'] ?? "";
                // Ajoute les autres champs déjà gérés par _textField
              }
              if (type == "Engin") {
                data['type_engin'] = selectedTypeEngin ?? "";
                // Ajoute les autres champs déjà gérés par _textField
              }
              widget.onAdd(data, type == "Engin");
              Navigator.pop(context);
            }
          },
        ),
      ],
    );
  }

  List<Widget> _buildFields() {
    switch (type) {
      case "Véhicule":
      case "Camion":
        return [
          _textField("Plaque", "plaque"),
          DropdownButtonFormField<Map<String, dynamic>>(
            value: selectedMarque,
            dropdownColor: Color(0xFF223C4A),
            decoration: InputDecoration(
              labelText: "Marque",
              labelStyle: TextStyle(color: Colors.white),
            ),
            items: marques
                .map((m) => DropdownMenuItem(
                      value: m,
                      child:
                          Text(m['nom'], style: TextStyle(color: Colors.white)),
                    ))
                .toList(),
            onChanged: (val) => setState(() => selectedMarque = val),
          ),
          _textField("Modèle", "modele"),
          DropdownButtonFormField<Map<String, dynamic>>(
            value: selectedChauffeur,
            dropdownColor: Color(0xFF223C4A),
            decoration: InputDecoration(
              labelText: "Chauffeur",
              labelStyle: TextStyle(color: Colors.white),
            ),
            items: chauffeurs
                .map((c) => DropdownMenuItem(
                      value: c,
                      child:
                          Text(c['nom'], style: TextStyle(color: Colors.white)),
                    ))
                .toList(),
            onChanged: (val) => setState(() => selectedChauffeur = val),
          ),
          _textField("Permis", "permis"),
          _textField("Carte grise", "carte_grise"),
          _textField("Assurance", "assurance"),
        ];
      case "Engin":
        return [
          _textField("Nom", "nom"),
          DropdownButtonFormField<String>(
            value: selectedTypeEngin,
            dropdownColor: Color(0xFF223C4A),
            decoration: InputDecoration(
              labelText: "Type d'engin",
              labelStyle: TextStyle(color: Colors.white),
            ),
            items: typesEngin
                .map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t, style: TextStyle(color: Colors.white)),
                    ))
                .toList(),
            onChanged: (val) => setState(() => selectedTypeEngin = val),
          ),
          _textField("N° série", "numero_serie"),
          _textField("Carte grise", "carte_grise"),
          _textField("Assurance", "assurance"),
        ];
      default:
        return [];
    }
  }

  Widget _textField(String label, String key) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white),
      ),
      style: TextStyle(color: Colors.white),
      validator: (val) => val == null || val.isEmpty ? "Champ requis" : null,
      onChanged: (val) => data[key] = val,
    );
  }
}
