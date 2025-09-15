import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';
import '../widgets/station_selection_dialog.dart';
import '../widgets/graphique_widget.dart';
import '../widgets/solde_evolution_widget.dart';
import '../widgets/separate_charts_widget.dart';
import '../services/api_services.dart';
import 'historique_bons_screen.dart'; // Importer l'écran HistoriqueBonsScreen
import 'demandes_en_attente_screen.dart'; // en haut du fichier
import 'parc_auto_screen.dart'; // Importer l'écran ParcAutoScreen
import '../widgets/logistique_drawer.dart';
import 'chauffeurs_screen.dart'; // Importer l'écran ChauffeursScreen

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService apiService = ApiService();
  late Future<Map<String, dynamic>> soldeStatsFuture;
  final _fmt = NumberFormat("#,##0", "fr_FR");
  bool _showSeparatedCharts = false;

  @override
  void initState() {
    super.initState();
    soldeStatsFuture = apiService.fetchSoldeEvolutionStats();

    // Demande la permission (iOS)
    FirebaseMessaging.instance.requestPermission();

    // Récupère le token FCM (à envoyer à ton serveur si besoin)
    FirebaseMessaging.instance.getToken().then((token) {
      print("FCM Token: $token");
    });

    // Notification reçue en premier plan
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        // Affiche une snackbar ou un dialog
        print('Notification reçue: ${message.notification!.title}');
      }
    });

    // Notification cliquée (app en arrière-plan)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Navigue ou affiche une page spécifique
    });
  }

  void _onRechargePressed() {
    showDialog(
      context: context,
      builder: (_) => StationSelectionDialog(
        onValider: (telephone, nomGerant, montant, recuImage) async {
          try {
            final result = await apiService.rechargerStationAvecRecu(
              telephone: telephone,
              nom: nomGerant,
              montant: montant,
              recuImage: recuImage,
            );
            Navigator.pop(context); // Ferme la boîte de dialogue ici SEULEMENT
            if (result['ok'] == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Rechargement effectué avec succès !")),
              );
              setState(() {
                soldeStatsFuture = apiService.fetchSoldeEvolutionStats();
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(result['message']?.toString() ??
                        "Échec du rechargement")),
              );
            }
          } catch (e) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Erreur réseau ou serveur")),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF17333F),
        title: Row(
          children: [
            Icon(Icons.local_shipping, color: Colors.greenAccent),
            SizedBox(width: 8),
            Text(
              'Logistique Pro',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: LogistiqueDrawer(),
      body: FutureBuilder<Map<String, dynamic>>(
        future: soldeStatsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur de chargement'));
          } else {
            final data = snapshot.data!;
            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SoldeStatsCard(
                    solde: (data['soldeActuel'] ?? 0).toDouble(),
                    totalIn: (data['totalRechargement'] ?? 0).toDouble(),
                    totalOut: (data['totalServi'] ?? 0).toDouble(),
                    utilisation: (data['utilisation'] ?? 0).toDouble(),
                    dernierIn:
                        (data['dernierRechargement'] as num?)?.toDouble(),
                    dernierInDate: data['dateDernierRechargement']?.toString(),
                    onRecharge: _onRechargePressed,
                    fmt: _fmt,
                  ),
                  SizedBox(height: 20),
                  GraphiqueWidget(),
                  SizedBox(height: 20),
                  SoldeEvolutionWidget(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(
                            () => _showSeparatedCharts = !_showSeparatedCharts);
                      },
                      icon: Icon(
                        _showSeparatedCharts
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: Colors.white70,
                      ),
                      label: Text(
                        _showSeparatedCharts
                            ? 'Masquer les graphiques séparés'
                            : 'Afficher les graphiques séparés',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                  if (_showSeparatedCharts) ...[
                    SizedBox(height: 8),
                    Card(
                      color: Color(0xFF17333F),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: SeparateChartsWidget(),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                  SizedBox(height: 20),
                  MenuItem(
                    icon: Icons.receipt_long,
                    title: "Historique des bons",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => HistoriqueBonsScreen()),
                      );
                    },
                  ),
                  MenuItem(
                    icon: Icons.pending_actions,
                    title: "Demandes en attente",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => DemandesEnAttenteScreen()),
                      );
                    },
                  ),
                  MenuItem(
                    icon: Icons.directions_car,
                    title: "Gestion du parc automobile",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ParcAutoScreen()),
                      );
                    },
                  ),
                  MenuItem(
                    icon: Icons.person,
                    title: "Gestion des chauffeurs",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ChauffeursScreen()),
                      );
                    },
                  ),
                  MenuItem(icon: Icons.bar_chart, title: "Statistiques"),
                  SizedBox(height: 100),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}

class MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap; // Ajoute ce paramètre

  const MenuItem({required this.icon, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color(0xFF17333F),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title, style: TextStyle(color: Colors.white)),
        trailing:
            Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
        onTap: onTap, // Utilise le onTap passé en paramètre
      ),
    );
  }
}

class _SoldeStatsCard extends StatelessWidget {
  final double solde;
  final double totalIn;
  final double totalOut;
  final double utilisation; // 0..1
  final double? dernierIn;
  final String? dernierInDate;
  final VoidCallback onRecharge;
  final NumberFormat fmt;

  const _SoldeStatsCard({
    required this.solde,
    required this.totalIn,
    required this.totalOut,
    required this.utilisation,
    required this.onRecharge,
    required this.fmt,
    this.dernierIn,
    this.dernierInDate,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (utilisation * 100).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF223C4A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Solde actuel",
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text("${fmt.format(solde)} F CFA",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A9A5),
                  foregroundColor: Colors.white,
                ),
                onPressed: onRecharge,
                icon: const Icon(Icons.add),
                label: const Text('Recharger'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("$percent% utilisé",
                  style: const TextStyle(color: Colors.white70)),
              Text("${fmt.format(totalOut)} / ${fmt.format(totalIn)}",
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: utilisation.clamp(0.0, 1.0),
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(
                utilisation >= 0.9
                    ? Colors.redAccent
                    : (utilisation >= 0.6
                        ? Colors.orangeAccent
                        : Colors.greenAccent),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: "Total rechargé",
                  value: "${fmt.format(totalIn)} F",
                  color: Colors.greenAccent,
                  icon: Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  label: "Total servi",
                  value: "${fmt.format(totalOut)} F",
                  color: Colors.redAccent,
                  icon: Icons.local_gas_station,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if ((dernierIn ?? 0) > 0)
            Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.white38, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Dernier rechargement: ${fmt.format(dernierIn)} F"
                    "${(dernierInDate ?? '').isNotEmpty ? " (" + _humanDate(dernierInDate!) + ")" : ""}",
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  static String _humanDate(String iso) {
    try {
      final d = DateTime.tryParse(iso);
      if (d == null) return iso;
      return "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";
    } catch (_) {
      return iso;
    }
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2F3A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
