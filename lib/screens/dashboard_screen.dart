import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';
import '../widgets/station_selection_dialog.dart';
import '../widgets/graphique_widget.dart';
import '../widgets/solde_evolution_widget.dart';
import '../widgets/separate_charts_widget.dart';
import '../widgets/solde_widget.dart';
import '../services/api_services.dart';
import 'historique_bons_screen.dart'; // Importer l'écran HistoriqueBonsScreen
import 'demandes_en_attente_screen.dart'; // en haut du fichier
import 'parc_auto_screen.dart'; // Importer l'écran ParcAutoScreen
import '../widgets/logistique_drawer.dart';
import 'chauffeurs_screen.dart'; // Importer l'écran ChauffeursScreen
import 'recapitulatif_screen.dart';
import 'rechargements_screen.dart';
import 'bons_en_service_screen.dart';
import 'bons_du_jour_screen.dart';
import 'bons_doublons_screen.dart';
import '../utils/notification_helper.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService apiService = ApiService();
  late Future<Map<String, dynamic>> soldeStatsFuture;
  DateTime? _lastRefresh;
  Map<String, dynamic>? _statsCache;
  final _fmt = NumberFormat("#,##0", "fr_FR");
  bool _showSeparatedCharts = false;
  int _pendingDemandes = 0;
  int _doublons = 0;
  bool _announced = false;
  bool _lowStockBanner = false; // indique si on affiche la bannière bas stock
  bool _wasAboveLowThreshold = true; // pour détecter transition
  final ValueNotifier<double> _historyProgress = ValueNotifier<double>(0.0);
  bool _loadingFullHistory = false;
  bool _fadeOutProgress = false; // animation de sortie barre

  @override
  void initState() {
    super.initState();
    soldeStatsFuture = _loadFullStats();

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

    // Charger les compteurs pour badges
    _loadPendingCounts();
  }

  Future<void> _loadPendingCounts() async {
    // Demandes en attente
    try {
      final list = await apiService.fetchDemandesEnAttente();
      if (mounted) setState(() => _pendingDemandes = list.length);
    } catch (_) {}

    // Doublons (par code) calculés côté client sur quelques pages pour éviter les charges
    _computeDoublonsCount(maxPages: 20);
  }

  Future<void> _computeDoublonsCount({int maxPages = 20}) async {
    int page = 1;
    bool hasMore = true;
    final Map<String, int> occ = {};
    while (hasMore && page <= maxPages) {
      try {
        final resp = await apiService.fetchBons(page: page);
        final bons = List<Map<String, dynamic>>.from(resp['bons']);
        for (final b in bons) {
          final des = int.tryParse((b['desactive'] ?? '0').toString()) ?? 0;
          if (des != 0) continue;
          final code = (b['code_bon'] ?? '').toString();
          if (code.isEmpty) continue;
          occ.update(code, (v) => v + 1, ifAbsent: () => 1);
        }
        final dupCount = occ.values.where((c) => c >= 2).length;
        if (mounted) setState(() => _doublons = dupCount);
        hasMore = resp['hasMore'] == true;
        page++;
        if (bons.isEmpty) break;
      } catch (_) {
        break;
      }
    }
    _announceIfNeeded();
  }

  void _announceIfNeeded() {
    if (_announced) return;
    if (!mounted) return;
    if (_pendingDemandes > 0 || _doublons > 0) {
      _announced = true;
      if (_pendingDemandes > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$_pendingDemandes demande(s) en attente')),
        );
        NotificationHelper.instance.showSimple(
          id: 101,
          title: 'Demandes en attente',
          body: '$_pendingDemandes demande(s) requièrent votre action',
        );
      }
      if (_doublons > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$_doublons doublon(s) détecté(s)')),
        );
        NotificationHelper.instance.showSimple(
          id: 102,
          title: 'Doublons détectés',
          body: '$_doublons doublon(s) de bons à vérifier',
        );
      }
    }
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
                soldeStatsFuture = _loadFullStats(force: true);
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
                  _buildSoldeSection(data),
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
                    badgeCount: _pendingDemandes,
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
                  MenuItem(
                    icon: Icons.add_circle,
                    title: "Rechargements station",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RechargementsScreen()),
                      );
                    },
                  ),
                  MenuItem(
                    icon: Icons.bar_chart,
                    title: "Récapitulatif",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RecapitulatifScreen()),
                      );
                    },
                  ),
                  // Nouveaux accès après Récapitulatif
                  MenuItem(
                    icon: Icons.local_gas_station,
                    title: "Bons en cours de service",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const BonsEnServiceScreen()),
                      );
                    },
                  ),
                  MenuItem(
                    icon: Icons.today,
                    title: "Bons du jour",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const BonsDuJourScreen()),
                      );
                    },
                  ),
                  MenuItem(
                    icon: Icons.copy_all,
                    title: "Doublons (par code)",
                    badgeCount: _doublons,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const BonsDoublonsScreen()),
                      );
                    },
                  ),
                  SizedBox(height: 100),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _loadFullStats({bool force = false}) async {
    _historyProgress.value = 0.0;
    _loadingFullHistory = true;
    _fadeOutProgress = false;
    late Map<String, dynamic> stats;
    try {
      // On réutilise la méthode existante qui calcule puis met en cache Hive.
      stats = await apiService.fetchSoldeEvolutionStatsAll(
        maxYears: 5,
        forceRefresh: force,
        onProgress: (p) {
          // Lissage léger: ne jamais reculer la progression
          if (p >= _historyProgress.value) {
            _historyProgress.value = p;
            assert(() {
              debugPrint(
                  '[FullHistoryProgress] ${(p * 100).toStringAsFixed(1)}%');
              return true;
            }());
          }
        },
      );
      _lastRefresh = DateTime.now();
      _statsCache = stats;
      // Alerte haute utilisation
      final utilPct = ((stats['utilisation'] ?? 0.0) * 100);
      if (utilPct >= 90) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Alerte: ${utilPct.toStringAsFixed(0)}% utilisé')),
          );
        });
      }
      // Alerte bas niveau
      final totalRechargement = (stats['totalRechargement'] ?? 0).toDouble();
      final soldeActuel = (stats['soldeActuel'] ?? 0).toDouble();
      if (totalRechargement > 0) {
        final restantPct = (soldeActuel / totalRechargement) * 100;
        if (restantPct <= 10) {
          if (_wasAboveLowThreshold) {
            _lowStockBanner = true;
            _wasAboveLowThreshold = false;
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final msg =
                'Alerte: seulement ${restantPct.toStringAsFixed(1)}% du stock reste';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg)),
            );
            NotificationHelper.instance.showSimple(
              id: 103,
              title: 'Stock carburant bas',
              body: msg,
            );
          });
        } else {
          _wasAboveLowThreshold = true;
          _lowStockBanner = false;
        }
      }
      return stats;
    } finally {
      _loadingFullHistory = true; // reste true jusqu’au fade out
      Future.microtask(() => _historyProgress.value = 1.0);
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        if (_historyProgress.value >= 1.0) {
          setState(() => _fadeOutProgress = true);
          Future.delayed(const Duration(milliseconds: 550), () {
            if (!mounted) return;
            setState(() {
              _loadingFullHistory = false; // retire définitivement
            });
          });
        }
      });
    }
  }

  Widget _buildSoldeSection(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_loadingFullHistory)
          AnimatedOpacity(
            opacity: _fadeOutProgress ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            child: ValueListenableBuilder<double>(
              valueListenable: _historyProgress,
              builder: (context, v, _) {
                final pct = (v * 100).clamp(0, 100).toStringAsFixed(0);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF223C4A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_download,
                          color: Colors.white54, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: v.clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: Colors.white10,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.tealAccent.withOpacity(0.85)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('$pct%',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: const Color(0xFF17333F),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              title: const Text('Progression',
                                  style: TextStyle(color: Colors.white)),
                              content: Text(
                                'Chargement historique...\n$pct% effectué.',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Fermer'),
                                )
                              ],
                            ),
                          );
                        },
                        child: const Icon(Icons.info_outline,
                            size: 18, color: Colors.white54),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_lastRefresh != null)
              Text('Maj: ' + _timeFmt(_lastRefresh!),
                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
            IconButton(
              tooltip: 'Recalculer historique',
              onPressed: () => setState(
                  () => soldeStatsFuture = _loadFullStats(force: true)),
              icon: const Icon(Icons.refresh, color: Colors.white70),
            )
          ],
        ),
        SoldeWidget(
          soldeActuel: (data['soldeActuel'] ?? 0).toDouble(),
          totalRechargement: (data['totalRechargement'] ?? 0).toDouble(),
          totalServi: (data['totalServi'] ?? 0).toDouble(),
          dernierRechargement:
              (data['dernierRechargement'] as num?)?.toDouble(),
          dateDernierRechargement: data['dateDernierRechargement']?.toString(),
          onRecharge: _onRechargePressed,
          onRefresh: () =>
              setState(() => soldeStatsFuture = _loadFullStats(force: true)),
        ),
        const SizedBox(height: 8),
        if (_statsCache != null) _buildDailyAverageBanner(),
        if (_lowStockBanner) ...[
          const SizedBox(height: 8),
          _buildLowStockBanner(),
        ],
      ],
    );
  }

  String _timeFmt(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Widget _buildDailyAverageBanner() {
    final stats = _statsCache!;
    final totalIn = (stats['totalRechargement'] ?? 0).toDouble();
    final totalOut = (stats['totalServi'] ?? 0).toDouble();
    final nbJours = (stats['nbJours'] ?? 0) as int;
    if (nbJours <= 0 || (totalIn == 0 && totalOut == 0))
      return const SizedBox.shrink();
    final moyIn = (totalIn / nbJours).round();
    final moyOut = (totalOut / nbJours).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF223C4A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        const Icon(Icons.analytics, color: Colors.white54, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Moy. journalière: ${_fmt.format(moyOut)} servi / ${_fmt.format(moyIn)} rechargé (sur $nbJours j)',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        )
      ]),
    );
  }

  Widget _buildLowStockBanner() {
    final totalRechargement =
        (_statsCache?['totalRechargement'] ?? 0).toDouble();
    final soldeActuel = (_statsCache?['soldeActuel'] ?? 0).toDouble();
    if (totalRechargement <= 0) return const SizedBox.shrink();
    final restantPct = (soldeActuel / totalRechargement * 100).clamp(0, 100);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Colors.redAccent.withOpacity(0.25),
          const Color(0xFF223C4A)
        ]),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Colors.redAccent.withOpacity(0.5), width: 0.8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.redAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Stock restant critique: ${restantPct.toStringAsFixed(1)}% (${_fmt.format(soldeActuel)} FCFA)',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() => _lowStockBanner = false);
            },
            child: const Text('Masquer',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
          )
        ],
      ),
    );
  }
}

class MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap; // Ajoute ce paramètre
  final int? badgeCount;
  const MenuItem(
      {required this.icon, required this.title, this.onTap, this.badgeCount});

  @override
  Widget build(BuildContext context) {
    final bc = (badgeCount ?? 0);
    return Card(
      color: Color(0xFF17333F),
      child: Stack(
        children: [
          ListTile(
            leading: Icon(icon, color: Colors.white),
            title: Text(title, style: TextStyle(color: Colors.white)),
            trailing:
                Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
            onTap: onTap,
          ),
          if (bc > 0)
            Positioned(
              right: 36,
              top: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  bc > 99 ? '99+' : bc.toString(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
