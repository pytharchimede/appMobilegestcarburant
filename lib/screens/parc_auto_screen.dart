import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ParcAutoScreen extends StatefulWidget {
  @override
  State<ParcAutoScreen> createState() => _ParcAutoScreenState();
}

class _ParcAutoScreenState extends State<ParcAutoScreen> {
  List<Map<String, dynamic>> autos = [
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

  List<Map<String, dynamic>> engins = [
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: Icon(Icons.add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AddParcElementDialog(
              onAdd: (element, isEngin) {
                setState(() {
                  if (isEngin) {
                    engins.add(element);
                  } else {
                    autos.add(element);
                  }
                });
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
      content: SingleChildScrollView(
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
                          child: Text(e, style: TextStyle(color: Colors.white)),
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
                      ? Icon(Icons.camera_alt, color: Colors.white54, size: 36)
                      : null,
                ),
              ),
              SizedBox(height: 12),
              ..._buildFields(),
              SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text("Documents :", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                        validator: (val) => val == null || val.isEmpty ? "Obligatoire" : null,
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
                  label: Text("Ajouter un document", style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    setState(() => documents.add({"type": "", "url": null}));
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
              data['photo_url'] = image;
              data['documents'] = documents;
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
          _textField("Marque", "marque"),
          _textField("Modèle", "modele"),
          _textField("Chauffeur", "chauffeur"),
          _textField("Permis", "permis"),
          _textField("Carte grise", "carte_grise"),
          _textField("Assurance", "assurance"),
        ];
      case "Engin":
        return [
          _textField("Nom", "nom"),
          _textField("Type d'engin", "type"),
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
