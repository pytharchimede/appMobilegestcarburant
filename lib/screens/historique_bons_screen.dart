import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gestion_carburant/screens/bon_detail_screen.dart';
import '../services/api_services.dart';

class HistoriqueBonsScreen extends StatefulWidget {
  final DateTime? initialDateDebut;
  final DateTime? initialDateFin;

  const HistoriqueBonsScreen(
      {Key? key, this.initialDateDebut, this.initialDateFin})
      : super(key: key);

  @override
  State<HistoriqueBonsScreen> createState() => _HistoriqueBonsScreenState();
}

class _HistoriqueBonsScreenState extends State<HistoriqueBonsScreen> {
  final ApiService apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  final NumberFormat formatMontant = NumberFormat("#,##0", "fr_FR");

  // Base URL où sont stockées les images des reçus
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
    // Appliquer les dates initiales si fournies
    dateDebut = widget.initialDateDebut;
    dateFin = widget.initialDateFin;
    _loadBons(reset: true);
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

  // Détermine l'état du bon et ses attributs d'affichage
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

  // Aperçu in-app du reçu (avec fallback ouverture navigateur)
  void _showReceiptDialog(String url) {
    // Sur le Web, ouvrir directement dans le navigateur pour contourner
    // les restrictions hotlinking/CORS côté serveur.
    if (kIsWeb) {
      _openReceiptUrl(url);
      return;
    }

    final cacheBust = DateTime.now().millisecondsSinceEpoch;
    final urlWithBust =
        url.contains('?') ? "$url&_=$cacheBust" : "$url?_=$cacheBust";
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF17333F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _ReceiptPreviewDialogBody(
            url: urlWithBust,
            onOpenExternal: () => _openReceiptUrl(url),
          ),
        ),
      ),
    );
  }

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
                                      _showReceiptDialog(status.receiptUrl!),
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

class _ReceiptPreviewDialogBody extends StatefulWidget {
  final String url;
  final VoidCallback onOpenExternal;
  const _ReceiptPreviewDialogBody(
      {required this.url, required this.onOpenExternal});

  @override
  State<_ReceiptPreviewDialogBody> createState() =>
      _ReceiptPreviewDialogBodyState();
}

class _ReceiptPreviewDialogBodyState extends State<_ReceiptPreviewDialogBody> {
  Uint8List? _bytes;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) _fetchBytes();
  }

  Future<void> _fetchBytes() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await http.get(
        Uri.parse(widget.url),
        headers: {
          'Referer': 'https://fidest.ci',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36',
          'Accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
        },
      );
      if (resp.statusCode == 200) {
        _bytes = resp.bodyBytes;
        _error = null;
      } else {
        _error = 'HTTP ${resp.statusCode}';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_bytes != null) {
      content = InteractiveViewer(
        child: Image.memory(_bytes!, fit: BoxFit.contain),
      );
    } else if (kIsWeb) {
      content = InteractiveViewer(
        child: Image.network(
          widget.url,
          fit: BoxFit.contain,
          loadingBuilder: (c, w, p) {
            if (p == null) return w;
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            );
          },
          errorBuilder: (c, e, s) => _errorBox(context),
        ),
      );
    } else if (_loading) {
      content = const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      content = _errorBox(context);
    }

    return Stack(
      children: [
        Positioned.fill(child: content),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }

  Widget _errorBox(BuildContext context) {
    return Container(
      color: const Color(0xFF223C4A),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Impossible de charger le reçu',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 12),
          if (!kIsWeb)
            ElevatedButton.icon(
              onPressed: _fetchBytes,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
              ),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Réessayer',
                  style: TextStyle(color: Colors.white)),
            ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: widget.onOpenExternal,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlueAccent,
            ),
            icon: const Icon(Icons.open_in_new, color: Colors.white),
            label: const Text('Ouvrir dans le navigateur',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
