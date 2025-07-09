import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddParcElementDialog extends StatefulWidget {
  final Function(Map<String, dynamic> element, bool isEngin) onAdd;
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
      title: Text("Ajouter au parc", style: TextStyle(color: Colors.white)),
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
                    labelStyle: TextStyle(color: Colors.white)),
                items: ["Véhicule", "Engin", "Camion"]
                    .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e, style: TextStyle(color: Colors.white))))
                    .toList(),
                onChanged: (val) => setState(() => type = val!),
              ),
              SizedBox(height: 8),
              GestureDetector(
                onTap: pickImage,
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white10,
                  backgroundImage:
                      image != null ? FileImage(File(image!.path)) : null,
                  child: image == null
                      ? Icon(Icons.camera_alt, color: Colors.white54)
                      : null,
                ),
              ),
              SizedBox(height: 8),
              ..._buildFields(),
              SizedBox(height: 8),
              Text("Documents :",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
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
              TextButton.icon(
                icon: Icon(Icons.add, color: Colors.white),
                label: Text("Ajouter un document",
                    style: TextStyle(color: Colors.white)),
                onPressed: () {
                  setState(() => documents.add({"type": "", "url": null}));
                },
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
              widget.onAdd(data, type != "Véhicule");
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
          _textField("Type", "type"),
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
