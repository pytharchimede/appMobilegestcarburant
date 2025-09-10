import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gestion_carburant/screens/bon_detail_screen.dart';
import '../services/api_services.dart';

class HistoriqueBonsScreen extends StatefulWidget {
  @override
  State<HistoriqueBonsScreen> createState() => _HistoriqueBonsScreenState();
}

class _HistoriqueBonsScreenState extends State<HistoriqueBonsScreen> {
  final ApiService apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  final NumberFormat formatMontant = NumberFormat("#,##0", "fr_FR");

  // Base URL où sont stockées les images des reçus (à adapter si besoin)
  static const String _uploadsBaseUrl =
      'https://fidest.ci/decaissement/uploads/recu_station/';

  // Données et pagination
  List<Map<String, dynamic>> bons = [];
  bool isLoading = false;
  bool hasMore = true;
  int page = 1;
  double montantTotal = 0;

  // Filtres
  String? station;
  DateTime? dateDebut;
  DateTime? dateFin;
  double? montantMin;
  double? montantMax;

  @override
  void initState() {
    super.initState();
    _loadBons();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 100 &&
          !isLoading &&
          hasMore) {
        _loadBons();
      }
    });
  }

  Future<void> _loadBons({bool reset = false}) async {
    if (isLoading) return;
    setState(() => isLoading = true);

    if (reset) {
      bons.clear();
      page = 1;
      montantTotal = 0;
      hasMore = true;
    }

    try {
      final result = await apiService.fetchBons(
        page: page,
        station: station,
        dateDebut: dateDebut,
        dateFin: dateFin,
        montantMin: montantMin,
        montantMax: montantMax,
      );
      setState(() {
        bons.addAll(List<Map<String, dynamic>>.from(result['bons']));
        montantTotal = (result['montantTotal'] ?? 0.0).toDouble();
        hasMore = result['hasMore'] == true;
        page++;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur de chargement")),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Détermine l'état du bon et ses attributs d'affichage (texte, couleur, icône)
  ({
    String label,
    Color color,
    IconData icon,
    bool hasReceipt,
    String? receiptUrl
  }) _resolveBonStatus(Map<String, dynamic> bon) {
    final desactive = int.tryParse(bon['desactive']?.toString() ?? '0') ?? 0;
    final img = (bon['img_recu_station'] ?? '').toString().trim();
    final hasReceipt = img.isNotEmpty;
    String? receiptUrl;
    if (hasReceipt) {
      // Si le champ contient déjà une URL absolue, on la garde telle quelle
      // Sinon on préfixe par la base des uploads (dossier recu_station)
      receiptUrl = img.startsWith('http')
          ? img
          : (img.startsWith('recu_station/')
              ? 'https://fidest.ci/decaissement/uploads/' + img
              : _uploadsBaseUrl + img);
    }

    if (desactive == 1) {
      return (
        label: 'Annulé',
        color: Colors.redAccent,
        icon: Icons.cancel,
        hasReceipt: false,
        receiptUrl: null,
      );
    }

    if (hasReceipt) {
      return (
        label: 'Déjà servi',
        color: Colors.green,
        icon: Icons.check_circle,
        hasReceipt: true,
        receiptUrl: receiptUrl,
      );
    }

    return (
      label: 'En attente de service',
      color: Colors.amber,
      icon: Icons.schedule,
      hasReceipt: false,
      receiptUrl: null,
    );
  }

  Future<void> _openReceiptUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.platformDefault)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossible d'ouvrir le reçu")),
        );
      }
    }
  }

  // Ancien aperçu en Dialog remplacé par l'ouverture navigateur via url_launcher

  void _showFiltreDialog() async {
    String? selectedStation = station;
    DateTime? selectedDebut = dateDebut;
    DateTime? selectedFin = dateFin;
    double? selectedMin = montantMin;
    double? selectedMax = montantMax;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF17333F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Filtres",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            children: [
              // Station (à adapter selon ta liste de stations)
              TextField(
                decoration: InputDecoration(
                  labelText: "Station",
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF223C4A),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (v) => selectedStation = v,
                controller: TextEditingController(text: selectedStation),
              ),
              const SizedBox(height: 12),
              // Dates
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDebut ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => selectedDebut = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF223C4A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          selectedDebut != null
                              ? DateFormat('dd/MM/yyyy').format(selectedDebut!)
                              : "Date début",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedFin ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => selectedFin = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF223C4A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          selectedFin != null
                              ? DateFormat('dd/MM/yyyy').format(selectedFin!)
                              : "Date fin",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Montant min/max
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Montant min",
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF223C4A),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (v) => selectedMin = double.tryParse(v),
                      controller: TextEditingController(
                          text: selectedMin?.toString() ?? ''),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Montant max",
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF223C4A),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (v) => selectedMax = double.tryParse(v),
                      controller: TextEditingController(
                          text: selectedMax?.toString() ?? ''),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                station = selectedStation;
                dateDebut = selectedDebut;
                dateFin = selectedFin;
                montantMin = selectedMin;
                montantMax = selectedMax;
              });
              Navigator.pop(context);
              _loadBons(reset: true);
            },
            child:
                const Text("Appliquer", style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text("Annuler", style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF17333F),
      appBar: AppBar(
        title: const Text("Historique des bons"),
        backgroundColor: const Color(0xFF17333F),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt, color: Colors.white),
            onPressed: _showFiltreDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF223C4A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Montant total",
                    style: TextStyle(color: Colors.white70)),
                Text(
                  "${formatMontant.format(montantTotal)} XOF",
                  style: const TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 20),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: bons.length + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= bons.length) {
                  return const Center(
                      child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ));
                }
                final bon = bons[index];
                final status = _resolveBonStatus(bon);
                return Card(
                  color: const Color(0xFF223C4A),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        const Icon(Icons.receipt, color: Colors.white),
                        Container(
                          margin: const EdgeInsets.only(top: 18),
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: status.color.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child:
                              Icon(status.icon, size: 14, color: status.color),
                        ),
                      ],
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          bon['code_bon']?.toString() ?? '',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "${formatMontant.format(double.tryParse(bon['montant'].toString()) ?? 0)} XOF",
                          style: const TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          bon['motif']?.toString() ?? '',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 6),
                        // Badge d'état avec action Voir reçu
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: status.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: status.color.withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(status.icon, size: 14, color: status.color),
                              const SizedBox(width: 6),
                              Text(status.label,
                                  style: TextStyle(
                                      color: status.color,
                                      fontWeight: FontWeight.w600)),
                              if (status.hasReceipt) ...[
                                const SizedBox(width: 10),
                                InkWell(
                                  onTap: () =>
                                      _openReceiptUrl(status.receiptUrl!),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.image,
                                          size: 14,
                                          color: Colors.lightBlueAccent),
                                      SizedBox(width: 4),
                                      Text('Voir reçu',
                                          style: TextStyle(
                                              color: Colors.lightBlueAccent)),
                                    ],
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.person,
                                color: Colors.white54, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              bon['nom_beneficiaire']?.toString() ?? '',
                              style: const TextStyle(color: Colors.white54),
                            ),
                            const Spacer(),
                            const Icon(Icons.calendar_today,
                                color: Colors.white54, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              bon['date_demande']?.toString() ?? '',
                              style: const TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        color: Colors.white54, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BonDetailScreen(bon: bon),
                        ),
                      );
                    },
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
