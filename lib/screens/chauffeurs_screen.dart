import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_services.dart';
import 'package:url_launcher/url_launcher.dart';

class ChauffeursScreen extends StatefulWidget {
  @override
  State<ChauffeursScreen> createState() => _ChauffeursScreenState();
}

class _ChauffeursScreenState extends State<ChauffeursScreen> {
  List<Map<String, dynamic>> chauffeurs = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadChauffeurs();
  }

  Future<void> _loadChauffeurs() async {
    setState(() => loading = true);
    try {
      final api = ApiService();
      chauffeurs = await api.fetchChauffeurs();
    } catch (e) {}
    setState(() => loading = false);
  }

  Future<void> _ajouterChauffeur() async {
    final nomController = TextEditingController();
    final telController = TextEditingController();
    final permisController = TextEditingController();
    final groupeController = TextEditingController();
    XFile? photoFile;
    List<Map<String, dynamic>> pieces = [];

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: Color(0xFF223C4A),
          title: Text("Ajouter un chauffeur",
              style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Nom",
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                ),
                TextField(
                  controller: telController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Téléphone",
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                ),
                TextField(
                  controller: permisController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Permis",
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                ),
                TextField(
                  controller: groupeController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Groupe sanguin",
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked =
                        await picker.pickImage(source: ImageSource.gallery);
                    if (picked != null)
                      setStateDialog(() => photoFile = picked);
                  },
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white10,
                    backgroundImage: photoFile != null
                        ? FileImage(File(photoFile!.path))
                        : null,
                    child: photoFile == null
                        ? Icon(Icons.camera_alt, color: Colors.white54)
                        : null,
                  ),
                ),
                SizedBox(height: 12),
                Text("Pièces jointes :", style: TextStyle(color: Colors.white)),
                ...pieces.asMap().entries.map((entry) {
                  int i = entry.key;
                  var piece = entry.value;
                  return Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: piece['type'],
                          decoration: InputDecoration(
                            labelText: "Type de pièce",
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                          style: TextStyle(color: Colors.white),
                          onChanged: (val) => piece['type'] = val,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.attach_file, color: Colors.white),
                        onPressed: () async {
                          final picker = ImagePicker();
                          final picked = await picker.pickImage(
                              source: ImageSource.gallery);
                          if (picked != null)
                            setStateDialog(() => piece['file'] = picked);
                        },
                      ),
                      if (piece['file'] != null)
                        Icon(Icons.check_circle, color: Colors.green),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setStateDialog(() => pieces.removeAt(i));
                        },
                      ),
                    ],
                  );
                }),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: Icon(Icons.add, color: Colors.white),
                    label: Text("Ajouter une pièce",
                        style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      setStateDialog(
                          () => pieces.add({"type": "", "file": null}));
                    },
                  ),
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
              onPressed: () async {
                if (nomController.text.isEmpty) return;
                try {
                  final api = ApiService();
                  await api.ajouterChauffeur(
                    nom: nomController.text,
                    telephone: telController.text,
                    permis: permisController.text,
                    groupeSanguin: groupeController.text,
                    photo: photoFile,
                    pieces: pieces,
                  );
                  Navigator.pop(context);
                  _loadChauffeurs();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Chauffeur ajouté avec succès")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Erreur ajout chauffeur : $e")),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF17333F),
      appBar: AppBar(
        backgroundColor: Color(0xFF17333F),
        title: Text("Chauffeurs"),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: _ajouterChauffeur,
          ),
        ],
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(16),
              children: chauffeurs
                  .map((ch) => Card(
                        color: Color(0xFF223C4A),
                        child: ListTile(
                          leading: ch['photo_url'] != null &&
                                  ch['photo_url'].toString().isNotEmpty
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(
                                      'https://fidest.ci/decaissement/api/${ch['photo_url']}'),
                                )
                              : Icon(Icons.person, color: Colors.white),
                          title: Text(ch['nom'] ?? '',
                              style: TextStyle(color: Colors.white)),
                          subtitle: Text(ch['telephone'] ?? '',
                              style: TextStyle(color: Colors.white70)),
                          trailing: Icon(Icons.arrow_forward_ios,
                              color: Colors.white54, size: 16),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) =>
                                  ChauffeurDetailDialog(chauffeur: ch),
                            );
                          },
                        ),
                      ))
                  .toList(),
            ),
    );
  }
}

class ChauffeurDetailDialog extends StatefulWidget {
  final Map<String, dynamic> chauffeur;
  const ChauffeurDetailDialog({required this.chauffeur});

  @override
  State<ChauffeurDetailDialog> createState() => _ChauffeurDetailDialogState();
}

class _ChauffeurDetailDialogState extends State<ChauffeurDetailDialog> {
  List<Map<String, dynamic>> pieces = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadPieces();
  }

  Future<void> _loadPieces() async {
    setState(() => loading = true);
    try {
      final api = ApiService();
      final res =
          await api.fetchChauffeurPieces(widget.chauffeur['id'].toString());
      setState(() => pieces = res);
    } catch (e) {}
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final ch = widget.chauffeur;
    return Dialog(
      backgroundColor: Color(0xFF223C4A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.white10,
                backgroundImage: ch['photo_url'] != null &&
                        ch['photo_url'].toString().isNotEmpty
                    ? NetworkImage(
                        'https://fidest.ci/decaissement/api/${ch['photo_url']}')
                    : null,
                child: (ch['photo_url'] == null ||
                        ch['photo_url'].toString().isEmpty)
                    ? Icon(Icons.person, color: Colors.white, size: 48)
                    : null,
              ),
              SizedBox(height: 16),
              Text(ch['nom'] ?? '',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22)),
              SizedBox(height: 8),
              if (ch['telephone'] != null &&
                  ch['telephone'].toString().isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone, color: Colors.greenAccent, size: 18),
                    SizedBox(width: 6),
                    Text(ch['telephone'],
                        style: TextStyle(color: Colors.white70)),
                  ],
                ),
              if (ch['permis'] != null && ch['permis'].toString().isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.credit_card, color: Colors.blueAccent, size: 18),
                    SizedBox(width: 6),
                    Text("Permis : ${ch['permis']}",
                        style: TextStyle(color: Colors.white70)),
                  ],
                ),
              if (ch['groupe_sanguin'] != null &&
                  ch['groupe_sanguin'].toString().isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bloodtype, color: Colors.redAccent, size: 18),
                    SizedBox(width: 6),
                    Text("Groupe : ${ch['groupe_sanguin']}",
                        style: TextStyle(color: Colors.white70)),
                  ],
                ),
              SizedBox(height: 18),
              Divider(color: Colors.white24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text("Pièces jointes :",
                    style: TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold)),
              ),
              loading
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : pieces.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text("Aucune pièce",
                              style: TextStyle(color: Colors.white54)),
                        )
                      : Column(
                          children: pieces.map((piece) {
                            final url = piece['url'] ?? '';
                            final isPdf =
                                url.toString().toLowerCase().endsWith('.pdf');
                            return ListTile(
                              leading: isPdf
                                  ? Icon(Icons.picture_as_pdf,
                                      color: Colors.redAccent)
                                  : Icon(Icons.image, color: Colors.blueAccent),
                              title: Text(piece['type'] ?? 'Document',
                                  style: TextStyle(color: Colors.white)),
                              trailing: IconButton(
                                icon: Icon(Icons.open_in_new, color: Colors.white70),
                                onPressed: () async {
                                  final fullUrl = 'https://fidest.ci/decaissement/api/$url';
                                  if (await canLaunchUrl(Uri.parse(fullUrl))) {
                                    await launchUrl(Uri.parse(fullUrl), mode: LaunchMode.externalApplication);
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
              SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  child: Text("Fermer", style: TextStyle(color: Colors.white)),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
