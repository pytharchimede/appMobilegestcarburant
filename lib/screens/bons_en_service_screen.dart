import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_services.dart';

class BonsEnServiceScreen extends StatefulWidget {
  const BonsEnServiceScreen({super.key});

  @override
  State<BonsEnServiceScreen> createState() => _BonsEnServiceScreenState();
}

class _BonsEnServiceScreenState extends State<BonsEnServiceScreen> {
  final api = ApiService();
  final _money = NumberFormat('#,##0', 'fr_FR');

  bool loading = false;
  String? error;
  final _items = <Map<String, dynamic>>[];
  bool _hasMore = true;
  int _page = 1;

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
      while (_hasMore && _page <= 50) {
        final resp = await api.fetchBons(page: _page);
        final bons = List<Map<String, dynamic>>.from(resp['bons']);
        // Filtre: non désactivés et sans reçu station
        final filtered = bons.where((b) {
          final desactive =
              int.tryParse((b['desactive'] ?? '0').toString()) ?? 0;
          final img = (b['img_recu_station'] ?? '').toString().trim();
          return desactive == 0 && img.isEmpty;
        }).toList();
        _items.addAll(filtered);
        _hasMore = resp['hasMore'] == true;
        _page++;
        if (bons.isEmpty) break;
      }
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

  Future<void> _desactiver(String code) async {
    final ok = await api.desactiverBon(codeBon: code);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bon désactivé')),
      );
      await _refresh();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Échec de la désactivation")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF17333F),
        title: const Text('Bons en cours de service'),
        actions: [
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
                          final montant = _money.format(
                            double.tryParse(
                                    (b['montant'] ?? b['quantite'] ?? '0')
                                        .toString()
                                        .replaceAll(' ', '')
                                        .replaceAll('\u00A0', '')) ??
                                0,
                          );
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
                                onPressed: () => _desactiver(code),
                                icon: const Icon(Icons.block,
                                    color: Colors.redAccent),
                                label: const Text('Désactiver',
                                    style: TextStyle(color: Colors.redAccent)),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
