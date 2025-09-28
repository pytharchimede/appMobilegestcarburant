import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_services.dart';

class BonsDuJourScreen extends StatefulWidget {
  const BonsDuJourScreen({super.key});

  @override
  State<BonsDuJourScreen> createState() => _BonsDuJourScreenState();
}

class _BonsDuJourScreenState extends State<BonsDuJourScreen> {
  final api = ApiService();
  final _money = NumberFormat('#,##0', 'fr_FR');

  bool loading = false;
  String? error;
  final _items = <Map<String, dynamic>>[];
  bool _hasMore = true;
  int _page = 1;

  String _orderBy = 'beneficiaire'; // 'beneficiaire' | 'montant' | 'date'

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      loading = true;
      error = null;
      _items.clear();
      _page = 1;
      _hasMore = true;
    });
    try {
      final today = DateTime.now();
      while (_hasMore && _page <= 50) {
        final resp =
            await api.fetchBons(page: _page, dateDebut: today, dateFin: today);
        final bons = List<Map<String, dynamic>>.from(resp['bons']);
        _items.addAll(bons);
        _hasMore = resp['hasMore'] == true;
        _page++;
        if (bons.isEmpty) break;
      }
      _sort();
      setState(() {
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  void _sort() {
    if (_orderBy == 'beneficiaire') {
      _items.sort((a, b) => (a['nom_beneficiaire'] ?? '')
          .toString()
          .toLowerCase()
          .compareTo((b['nom_beneficiaire'] ?? '').toString().toLowerCase()));
    } else if (_orderBy == 'montant') {
      double val(dynamic v) =>
          double.tryParse(
              v.toString().replaceAll(' ', '').replaceAll('\u00A0', '')) ??
          0.0;
      _items.sort((a, b) => val(a['montant'] ?? a['quantite'])
          .compareTo(val(b['montant'] ?? b['quantite'])));
    } else {
      DateTime d(dynamic v) =>
          DateTime.tryParse((v ?? '').toString()) ?? DateTime.now();
      _items.sort((a, b) => d(a['date'] ?? a['date_demande'])
          .compareTo(d(b['date'] ?? b['date_demande'])));
    }
  }

  Future<void> _shareWhatsApp(String text) async {
    final url = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir WhatsApp')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayStr = DateFormat('dd/MM/yyyy').format(DateTime.now());
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF17333F),
        title: Text('Bons du jour · $todayStr'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              setState(() {
                _orderBy = v;
                _sort();
              });
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                  value: 'beneficiaire', child: Text('Trier par bénéficiaire')),
              PopupMenuItem(value: 'montant', child: Text('Trier par montant')),
              PopupMenuItem(value: 'date', child: Text('Trier par date')),
            ],
          ),
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Erreur: $error'))
              : _items.isEmpty
                  ? const Center(child: Text('Aucun bon'))
                  : RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final b = _items[i];
                          final code = (b['code_bon'] ?? '').toString();
                          final bene = (b['nom_beneficiaire'] ?? '').toString();
                          final motif =
                              (b['motif'] ?? b['note'] ?? b['notes'] ?? '')
                                  .toString();
                          final montant = _money.format(double.tryParse(
                                  (b['montant'] ?? b['quantite'] ?? '0')
                                      .toString()
                                      .replaceAll(' ', '')
                                      .replaceAll('\u00A0', '')) ??
                              0.0);
                          // Lien correct du bon d'essence à partager
                          final lienBon =
                              'https://fidest.ci/decaissement/bon/bon_essence.php?id_bon=$code';
                          // Message conforme à la demande
                          final withMotif =
                              motif.trim().isNotEmpty ? " pour $motif" : '';
                          final txt =
                              "Bonjour, voici votre bon d'essence émis par $bene$withMotif d'un montant de $montant F:\n$lienBon";
                          return Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF223C4A),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              title: Text('$code — $bene',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text('$montant F',
                                  style:
                                      const TextStyle(color: Colors.white70)),
                              trailing: TextButton.icon(
                                onPressed: () => _shareWhatsApp(txt),
                                icon: const Icon(Icons.share,
                                    color: Colors.lightGreenAccent),
                                label: const Text('WhatsApp',
                                    style: TextStyle(
                                        color: Colors.lightGreenAccent)),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
