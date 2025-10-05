import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gestion_carburant/screens/bon_detail_screen.dart';
import 'package:flutter/services.dart';
import '../services/export_service.dart';
import '../services/api_services.dart';
import '../services/cache_service.dart';

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
  bool fromCacheGlobal =
      false; // indique si la dernière page chargée venait du cache
  bool staleCache = false; // indique si cache expiré utilisé (fallback)
  int _stalePagesCount = 0; // nombre de pages servies en mode stale
  Duration _ttl = const Duration(hours: 1);
  String? _parseError; // erreur de parsing potentielle
  bool _emptyResponse = false; // réponse vide serveur

  // Filtres
  String? station;
  DateTime? dateDebut;
  DateTime? dateFin;
  double? montantMin;
  double? montantMax;
  String? statutFiltre; // 'servi','attente','annule'
  String _searchCode = '';

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
        cacheTtl: _ttl,
      );
      setState(() {
        bons.addAll(List<Map<String, dynamic>>.from(result['bons']));
        montantTotal = (result['montantTotal'] ?? 0.0).toDouble();
        hasMore = result['hasMore'] == true;
        fromCacheGlobal = result['fromCache'] == true && page == 1;
        if (result['stale'] == true) {
          if (page == 1) {
            staleCache = true;
          }
          _stalePagesCount++;
        }
        if (page == 1) {
          _parseError = result['parseError'] as String?;
          _emptyResponse = result['emptyResponse'] == true;
        }
        page++;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur de chargement: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _forceRefresh() async {
    await CacheService.clearBonsCache();
    await _loadBons(reset: true);
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
    Duration tempTtl = _ttl;

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
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: statutFiltre,
                decoration: InputDecoration(
                  labelText: 'Statut',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF223C4A),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                dropdownColor: const Color(0xFF223C4A),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Tous')),
                  DropdownMenuItem(value: 'servi', child: Text('Servi')),
                  DropdownMenuItem(value: 'attente', child: Text('En attente')),
                  DropdownMenuItem(value: 'annule', child: Text('Annulé')),
                ],
                onChanged: (v) => statutFiltre = v,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: tempTtl.inMinutes,
                decoration: InputDecoration(
                  labelText: 'Durée cache (TTL)',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF223C4A),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                dropdownColor: const Color(0xFF223C4A),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 15, child: Text('15 min')),
                  DropdownMenuItem(value: 30, child: Text('30 min')),
                  DropdownMenuItem(value: 60, child: Text('1 h')),
                  DropdownMenuItem(value: 120, child: Text('2 h')),
                ],
                onChanged: (v) {
                  if (v != null) tempTtl = Duration(minutes: v);
                },
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
                _ttl = tempTtl;
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
          if (_stalePagesCount > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.deepOrangeAccent.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'stale: $_stalePagesCount',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontStyle: FontStyle.italic),
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.filter_alt, color: Colors.white),
            onPressed: _showFiltreDialog,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (val) async {
              if (val == 'purge') {
                await CacheService.clearBonsCache();
                if (mounted) {
                  setState(() {
                    _stalePagesCount = 0;
                    staleCache = false;
                  });
                }
                await _loadBons(reset: true);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Cache des bons purgé avec succès.')),
                  );
                }
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'purge',
                child: Text('Purger cache bons'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Bandeau indicateur cache + refresh
          if (fromCacheGlobal)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade700.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.offline_bolt, color: Colors.amber, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      staleCache
                          ? 'Affichage depuis le cache (stale) expiré. Glissez vers le bas pour tenter de rafraîchir.'
                          : 'Affichage depuis le cache local (TTL actif). Glissez vers le bas pour actualiser.',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: _forceRefresh,
                    child: const Text('Rafraîchir'),
                  )
                ],
              ),
            ),
          if (_parseError != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orangeAccent.withOpacity(0.6)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.orangeAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Données partielles: ${_parseError!}\nVous pouvez rafraîchir pour réessayer.',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Masquer',
                    onPressed: () => setState(() => _parseError = null),
                    icon: const Icon(Icons.close,
                        size: 18, color: Colors.white54),
                  )
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Recherche code bon',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF223C4A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (v) =>
                  setState(() => _searchCode = v.trim().toLowerCase()),
            ),
          ),
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
                Row(children: [
                  const Text("Montant total",
                      style: TextStyle(color: Colors.white70)),
                  if (fromCacheGlobal) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: staleCache
                            ? Colors.deepOrangeAccent.withOpacity(0.35)
                            : Colors.blueGrey.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        staleCache ? '(stale)' : '(cache)',
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontStyle: FontStyle.italic),
                      ),
                    )
                  ]
                ]),
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
            child: RefreshIndicator(
              color: Colors.tealAccent,
              backgroundColor: const Color(0xFF223C4A),
              onRefresh: _forceRefresh,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  if (_emptyResponse && bons.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 48, 24, 12),
                        child: Column(
                          children: [
                            Icon(Icons.inbox_outlined,
                                size: 56, color: Colors.white30),
                            SizedBox(height: 12),
                            Text('Aucune donnée (réponse vide serveur).',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600)),
                            SizedBox(height: 8),
                            Text(
                              'Tirez pour rafraîchir. Si le problème persiste, vérifier l’API historique_bons.',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= bons.length)
                          return const SizedBox.shrink();
                        final bon = bons[index];
                        if (!_matchesFilters(bon))
                          return const SizedBox.shrink();
                        final status = _resolveBonStatus(bon);
                        return Card(
                          color: const Color(0xFF223C4A),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
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
                                  child: Icon(status.icon,
                                      size: 14, color: status.color),
                                ),
                              ],
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  bon['code_bon']?.toString() ?? '',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
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
                                      Icon(status.icon,
                                          size: 14, color: status.color),
                                      const SizedBox(width: 6),
                                      Text(status.label,
                                          style: TextStyle(
                                              color: status.color,
                                              fontWeight: FontWeight.w600)),
                                      if (status.hasReceipt) ...[
                                        const SizedBox(width: 10),
                                        InkWell(
                                          onTap: () => _showReceiptDialog(
                                              status.receiptUrl!),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(Icons.image,
                                                  size: 14,
                                                  color:
                                                      Colors.lightBlueAccent),
                                              SizedBox(width: 4),
                                              Text('Voir reçu',
                                                  style: TextStyle(
                                                      color: Colors
                                                          .lightBlueAccent)),
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
                                      style: const TextStyle(
                                          color: Colors.white54),
                                    ),
                                    const Spacer(),
                                    const Icon(Icons.calendar_today,
                                        color: Colors.white54, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      bon['date_demande']?.toString() ?? '',
                                      style: const TextStyle(
                                          color: Colors.white54),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert,
                                  color: Colors.white70, size: 20),
                              onSelected: (v) async {
                                if (v == 'detail') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BonDetailScreen(bon: bon),
                                    ),
                                  );
                                } else if (v == 'copy') {
                                  final code = (bon['code_bon'] ??
                                          bon['num_fiche'] ??
                                          '')
                                      .toString();
                                  await Clipboard.setData(
                                      ClipboardData(text: code));
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text('Code $code copié')),
                                    );
                                  }
                                } else if (v == 'pdf') {
                                  try {
                                    final file =
                                        await ExportService.exportBonPdf(bon);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text('PDF généré')),
                                      );
                                    }
                                    await ExportService.openFile(file);
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text('Erreur PDF')),
                                      );
                                    }
                                  }
                                } else if (v == 'share') {
                                  final code =
                                      bon['code_bon']?.toString() ?? '';
                                  final montant = double.tryParse(
                                          bon['montant']?.toString() ?? '0') ??
                                      0;
                                  final motif = bon['motif']?.toString() ?? '';
                                  final date =
                                      bon['date_demande']?.toString() ?? '';
                                  final beneficiaire =
                                      bon['nom_beneficiaire']?.toString() ?? '';
                                  final resume =
                                      'Bon carburant $code\nMontant: ${formatMontant.format(montant)} XOF\nBénéficiaire: $beneficiaire\nMotif: $motif\nDate: $date';
                                  _shareText(resume);
                                } else if (v == 'recu' &&
                                    status.hasReceipt &&
                                    status.receiptUrl != null) {
                                  _showReceiptDialog(status.receiptUrl!);
                                }
                              },
                              itemBuilder: (c) => [
                                const PopupMenuItem(
                                    value: 'detail',
                                    child: Text('Voir détail')),
                                const PopupMenuItem(
                                    value: 'copy', child: Text('Copier code')),
                                const PopupMenuItem(
                                    value: 'pdf', child: Text('Exporter PDF')),
                                if (status.hasReceipt)
                                  const PopupMenuItem(
                                      value: 'recu', child: Text('Voir reçu')),
                                const PopupMenuItem(
                                    value: 'share', child: Text('Partager')),
                              ],
                            ),
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
                      childCount: bons.length,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: hasMore
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : const SizedBox(height: 40),
                  )
                ],
              ),
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

extension _BonShareExt on _HistoriqueBonsScreenState {
  void _shareText(String text) => Share.share(text, subject: 'Bon carburant');
  bool _matchesFilters(Map<String, dynamic> bon) {
    if (_searchCode.isNotEmpty) {
      final code =
          (bon['code_bon'] ?? bon['num_fiche'] ?? '').toString().toLowerCase();
      if (!code.contains(_searchCode)) return false;
    }
    if (statutFiltre == null) return true;
    final s = _resolveBonStatus(bon);
    if (statutFiltre == 'servi') return s.label == 'Déjà servi';
    if (statutFiltre == 'attente') return s.label == 'En attente de service';
    if (statutFiltre == 'annule') return s.label == 'Annulé';
    return true;
  }
}
