import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ParametresScreen extends StatefulWidget {
  const ParametresScreen({Key? key}) : super(key: key);

  @override
  State<ParametresScreen> createState() => _ParametresScreenState();
}

class _ParametresScreenState extends State<ParametresScreen> {
  String entreprise = "Ma Société";
  XFile? logo;
  bool darkMode = true;

  List<String> categories = [
    "Carburant",
    "Matériau de construction",
    "Outil à main",
    "Mobilier",
    "Informatique",
    "Divers",
  ];

  List<String> chantiers = [
    "Chantier Siège",
    "Chantier Annexe",
    "Chantier Extension",
  ];

  void _ajouterCategorie() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Color(0xFF223C4A),
        title: Text("Nouvelle catégorie", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: "Nom de la catégorie",
            labelStyle: TextStyle(color: Colors.white),
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
                if (controller.text.isNotEmpty && !categories.contains(controller.text)) {
                  categories.add(controller.text);
                }
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _ajouterChantier() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Color(0xFF223C4A),
        title: Text("Nouveau chantier", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: "Nom du chantier",
            labelStyle: TextStyle(color: Colors.white),
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
                if (controller.text.isNotEmpty && !chantiers.contains(controller.text)) {
                  chantiers.add(controller.text);
                }
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _changerLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => logo = picked);
  }

  void _changerNomEntreprise() async {
    final controller = TextEditingController(text: entreprise);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Color(0xFF223C4A),
        title: Text("Nom de l'entreprise", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: "Nom",
            labelStyle: TextStyle(color: Colors.white),
          ),
        ),
        actions: [
          TextButton(
            child: Text("Annuler", style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text("Enregistrer"),
            onPressed: () {
              setState(() {
                entreprise = controller.text;
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _reinitialiserDonnees() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Color(0xFF223C4A),
        title: Text("Réinitialiser les données", style: TextStyle(color: Colors.white)),
        content: Text(
          "Cette action supprimera toutes les données locales de l'application. Continuer ?",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            child: Text("Annuler", style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text("Oui, tout effacer"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() {
        // Ici tu pourrais vider toutes les listes et remettre les valeurs par défaut
        categories = [
          "Carburant",
          "Matériau de construction",
          "Outil à main",
          "Mobilier",
          "Informatique",
          "Divers",
        ];
        chantiers = [
          "Chantier Siège",
          "Chantier Annexe",
          "Chantier Extension",
        ];
        entreprise = "Ma Société";
        logo = null;
        darkMode = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Données réinitialisées.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF17333F),
      appBar: AppBar(
        backgroundColor: Color(0xFF17333F),
        title: Text("Paramètres"),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text("Général", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          ListTile(
            leading: logo == null
                ? Icon(Icons.business, color: Colors.white)
                : CircleAvatar(backgroundImage: FileImage(File(logo!.path))),
            title: Text("Nom de l'entreprise", style: TextStyle(color: Colors.white)),
            subtitle: Text(entreprise, style: TextStyle(color: Colors.white70)),
            trailing: Icon(Icons.edit, color: Colors.white70),
            onTap: _changerNomEntreprise,
          ),
          ListTile(
            leading: Icon(Icons.image, color: Colors.white),
            title: Text("Logo", style: TextStyle(color: Colors.white)),
            trailing: Icon(Icons.edit, color: Colors.white70),
            onTap: _changerLogo,
          ),
          SwitchListTile(
            value: darkMode,
            onChanged: (val) => setState(() => darkMode = val),
            title: Text("Mode sombre", style: TextStyle(color: Colors.white)),
            secondary: Icon(Icons.dark_mode, color: Colors.white),
          ),
          Divider(color: Colors.white24),
          Text("Catégories", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
          ...categories.map((cat) => ListTile(
                leading: Icon(Icons.category, color: Colors.white),
                title: Text(cat, style: TextStyle(color: Colors.white)),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () {
                    setState(() {
                      categories.remove(cat);
                    });
                  },
                ),
              )),
          ListTile(
            leading: Icon(Icons.add, color: Colors.green),
            title: Text("Ajouter une catégorie", style: TextStyle(color: Colors.white)),
            onTap: _ajouterCategorie,
          ),
          Divider(color: Colors.white24),
          Text("Chantiers", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
          ...chantiers.map((chantier) => ListTile(
                leading: Icon(Icons.location_on, color: Colors.white),
                title: Text(chantier, style: TextStyle(color: Colors.white)),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () {
                    setState(() {
                      chantiers.remove(chantier);
                    });
                  },
                ),
              )),
          ListTile(
            leading: Icon(Icons.add, color: Colors.green),
            title: Text("Ajouter un chantier", style: TextStyle(color: Colors.white)),
            onTap: _ajouterChantier,
          ),
          Divider(color: Colors.white24),
          ListTile(
            leading: Icon(Icons.delete_forever, color: Colors.redAccent),
            title: Text("Réinitialiser toutes les données", style: TextStyle(color: Colors.redAccent)),
            onTap: _reinitialiserDonnees,
          ),
        ],
      ),
    );
  }
}