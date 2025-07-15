import 'dart:io';
import 'package:excel/excel.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/api_services.dart';

class RapportJournalierScreen extends StatefulWidget {
  const RapportJournalierScreen({Key? key}) : super(key: key);

  @override
  State<RapportJournalierScreen> createState() =>
      _RapportJournalierScreenState();
}

class _RapportJournalierScreenState extends State<RapportJournalierScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final ApiService apiService = ApiService();

  Map<String, List<Map<String, dynamic>>> rapports = {};
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadRapports();
  }

  Future<void> _loadRapports() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      rapports = await apiService.fetchRapportsJournalier(
        dateDebut: _focusedDay,
        dateFin: _focusedDay,
      );
    } catch (e) {
      error = e.toString();
    }
    setState(() {
      isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _rapportDuJour {
    final key = (_selectedDay ?? _focusedDay).toIso8601String().substring(0, 10);
    return rapports[key] ?? [];
  }

  void _modifierEtatRapport(int index) async {
    final rapport = _rapportDuJour[index];
    String etat = rapport['etat'] ?? "Non démarré";
    final commentaireController = TextEditingController(text: rapport['commentaire'] ?? "");

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Color(0xFF223C4A),
        title: Text("État de la tâche", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: etat,
              dropdownColor: Color(0xFF223C4A),
              decoration: InputDecoration(
                labelText: "État",
                labelStyle: TextStyle(color: Colors.white),
              ),
              items: [
                "Non démarré",
                "Annulé",
                "Exécuté en partie",
                "Exécuté totalement"
              ]
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e, style: TextStyle(color: _etatColor(e))),
                      ))
                  .toList(),
              onChanged: (val) => etat = val!,
            ),
            SizedBox(height: 8),
            TextField(
              controller: commentaireController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Commentaire",
                labelStyle: TextStyle(color: Colors.white),
              ),
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text("Annuler", style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text("Valider"),
            onPressed: () async {
              final key = (_selectedDay ?? _focusedDay).toIso8601String().substring(0, 10);
              final ok = await apiService.updateRapportJournalier(
                planningLineId: rapport['planning_line_id'],
                dateRapport: key,
                etat: etat,
                commentaire: commentaireController.text,
              );
              if (ok) {
                Navigator.pop(context);
                await _loadRapports();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Erreur lors de la mise à jour")),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Color _etatColor(String? etat) {
    switch (etat) {
      case "Annulé":
        return Colors.redAccent;
      case "Exécuté en partie":
        return Colors.orangeAccent;
      case "Exécuté totalement":
        return Colors.greenAccent;
      case "Non démarré":
      default:
        return Colors.white70;
    }
  }

  Future<void> _exporterExcel() async {
    final excel = Excel.createExcel();
    final key = (_selectedDay ?? _focusedDay).toIso8601String().substring(0, 10);
    final sheet = excel['Rapport $key'];
    sheet.appendRow(['Tâche', 'Responsable', 'Heure', 'État', 'Commentaire']);
    for (var rapport in _rapportDuJour) {
      sheet.appendRow([
        rapport['tache'],
        rapport['responsable'],
        rapport['heure'],
        rapport['etat'],
        rapport['commentaire'],
      ]);
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/rapport_$key.xlsx');
    file.writeAsBytesSync(excel.encode()!);
    OpenFile.open(file.path);
  }

  Future<void> _exporterPDF() async {
    final pdf = pw.Document();
    final key = (_selectedDay ?? _focusedDay).toIso8601String().substring(0, 10);
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Rapport du $key', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(
              headers: ['Tâche', 'Responsable', 'Heure', 'État', 'Commentaire'],
              data: _rapportDuJour.map((rapport) => [
                rapport['tache'],
                rapport['responsable'],
                rapport['heure'],
                rapport['etat'],
                rapport['commentaire'],
              ]).toList(),
            ),
          ],
        ),
      ),
    );
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/rapport_$key.pdf');
    await file.writeAsBytes(await pdf.save());
    OpenFile.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF17333F),
      appBar: AppBar(
        backgroundColor: Color(0xFF17333F),
        title: Text("Rapport journalier"),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.file_download, color: Colors.white),
            onSelected: (value) {
              if (value == 'excel') _exporterExcel();
              if (value == 'pdf') _exporterPDF();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.grid_on, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Exporter en Excel'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Exporter en PDF'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.greenAccent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              weekendTextStyle: TextStyle(color: Colors.redAccent),
              defaultTextStyle: TextStyle(color: Colors.white),
              outsideTextStyle: TextStyle(color: Colors.white38),
            ),
            headerStyle: HeaderStyle(
              titleTextStyle:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              formatButtonVisible: false,
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: Colors.white70),
              weekendStyle: TextStyle(color: Colors.redAccent),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
            child: Row(
              children: [
                Text(
                  "Rapport du ${(_selectedDay ?? _focusedDay).day}/${(_selectedDay ?? _focusedDay).month}/${(_selectedDay ?? _focusedDay).year}",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.picture_as_pdf, color: Colors.white),
                  onPressed: _exporterPDF,
                  tooltip: "Exporter en PDF",
                ),
                IconButton(
                  icon: Icon(Icons.table_chart, color: Colors.white),
                  onPressed: _exporterExcel,
                  tooltip: "Exporter en Excel",
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.white))
                : error != null
                    ? Center(
                        child: Text("Erreur: $error",
                            style: TextStyle(color: Colors.redAccent)))
                    : _rapportDuJour.isEmpty
                        ? Center(
                            child: Text("Aucune tâche prévue",
                                style: TextStyle(color: Colors.white54)))
                        : ListView.separated(
                            itemCount: _rapportDuJour.length,
                            separatorBuilder: (_, __) => Divider(color: Colors.white24),
                            itemBuilder: (context, index) {
                              final rapport = _rapportDuJour[index];
                              return ListTile(
                                leading:
                                    Icon(Icons.event_note, color: Colors.greenAccent),
                                title: Text(rapport['tache'] ?? '',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Responsable : ${rapport['responsable'] ?? ''}\nHeure : ${rapport['heure'] ?? ''}",
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          "État : ",
                                          style: TextStyle(
                                              color: Colors.white70,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          rapport['etat'] ?? "Non démarré",
                                          style: TextStyle(
                                            color: _etatColor(rapport['etat']),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if ((rapport['commentaire'] ?? '').isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2.0),
                                        child: Text(
                                          "Commentaire : ${rapport['commentaire']}",
                                          style: TextStyle(
                                              color: Colors.white54,
                                              fontStyle: FontStyle.italic,
                                              fontSize: 13),
                                        ),
                                      ),
                                  ],
                                ),
                                onTap: () => _modifierEtatRapport(index),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
