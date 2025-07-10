import 'dart:io';
import 'package:excel/excel.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({Key? key}) : super(key: key);

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, List<Map<String, String>>> plannings = {
    // Exemple de données simulées
    "2025-07-10": [
      {"tache": "Réception livraison carburant", "responsable": "M. Yao", "heure": "08:00"},
      {"tache": "Entretien camion", "responsable": "M. Traoré", "heure": "14:00"},
    ],
    "2025-07-11": [
      {"tache": "Inventaire matériel", "responsable": "Mme Kone", "heure": "09:00"},
    ],
  };

  List<Map<String, String>> get _planningDuJour {
    final key = (_selectedDay ?? _focusedDay).toIso8601String().substring(0, 10);
    return plannings[key] ?? [];
  }

  void _ajouterPlanning() async {
    final tacheController = TextEditingController();
    final responsableController = TextEditingController();
    final heureController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Color(0xFF223C4A),
        title: Text("Ajouter une tâche", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tacheController,
              decoration: InputDecoration(labelText: "Tâche", labelStyle: TextStyle(color: Colors.white)),
              style: TextStyle(color: Colors.white),
            ),
            TextField(
              controller: responsableController,
              decoration: InputDecoration(labelText: "Responsable", labelStyle: TextStyle(color: Colors.white)),
              style: TextStyle(color: Colors.white),
            ),
            TextField(
              controller: heureController,
              decoration: InputDecoration(labelText: "Heure", labelStyle: TextStyle(color: Colors.white)),
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
            child: Text("Ajouter"),
            onPressed: () {
              final key = (_selectedDay ?? _focusedDay).toIso8601String().substring(0, 10);
              setState(() {
                plannings.putIfAbsent(key, () => []);
                plannings[key]!.add({
                  "tache": tacheController.text,
                  "responsable": responsableController.text,
                  "heure": heureController.text,
                });
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _exporterExcel() async {
    final excel = Excel.createExcel();
    final key = (_selectedDay ?? _focusedDay).toIso8601String().substring(0, 10);
    final sheet = excel['Planning $key'];
    sheet.appendRow(['Tâche', 'Responsable', 'Heure']);
    for (var plan in _planningDuJour) {
      sheet.appendRow([plan['tache'], plan['responsable'], plan['heure']]);
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/planning_$key.xlsx');
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
            pw.Text('Planning du $key', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(
              headers: ['Tâche', 'Responsable', 'Heure'],
              data: _planningDuJour.map((plan) => [plan['tache'], plan['responsable'], plan['heure']]).toList(),
            ),
          ],
        ),
      ),
    );
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/planning_$key.pdf');
    await file.writeAsBytes(await pdf.save());
    OpenFile.open(file.path);
  }

  void _exporterPlanning() {
    // À brancher plus tard (PDF, Excel, etc.)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Fonction export à venir !")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF17333F),
      appBar: AppBar(
        backgroundColor: Color(0xFF17333F),
        title: Text("Planning journalier"),
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
              titleTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Planning du ${(_selectedDay ?? _focusedDay).day}/${(_selectedDay ?? _focusedDay).month}/${(_selectedDay ?? _focusedDay).year}",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white, // <-- Ajoute ceci
                  ),
                  icon: Icon(Icons.add),
                  label: Text("Ajouter"),
                  onPressed: _ajouterPlanning,
                ),
              ],
            ),
          ),
          Expanded(
            child: _planningDuJour.isEmpty
                ? Center(child: Text("Aucune tâche prévue", style: TextStyle(color: Colors.white54)))
                : ListView.separated(
                    itemCount: _planningDuJour.length,
                    separatorBuilder: (_, __) => Divider(color: Colors.white24),
                    itemBuilder: (context, index) {
                      final plan = _planningDuJour[index];
                      return ListTile(
                        leading: Icon(Icons.event_note, color: Colors.greenAccent),
                        title: Text(plan['tache'] ?? '', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          "Responsable : ${plan['responsable'] ?? ''}\nHeure : ${plan['heure'] ?? ''}",
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}