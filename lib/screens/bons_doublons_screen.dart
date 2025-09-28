import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_services.dart';

class BonsDoublonsScreen extends StatefulWidget {
  const BonsDoublonsScreen({super.key});

  @override
  State<BonsDoublonsScreen> createState() => _BonsDoublonsScreenState();
}

class _BonsDoublonsScreenState extends State<BonsDoublonsScreen> {
  final api = ApiService();
  final _money = NumberFormat('#,##0', 'fr_FR');

  bool loading = false;
  String? error;
  final _items = <Map<String,
      dynamic>>[]; // grouped structure: {'code_bon': x, 'occurrences': [bon, bon], 'total': ...}
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
      final all = <Map<String, dynamic>>[];
      while (_hasMore && _page <= 50) {
        final resp = await api.fetchBons(page: _page);
        final bons = List<Map<String, dynamic>>.from(resp['bons']);
        all.addAll(bons);
        _hasMore = resp['hasMore'] == true;
        _page++;
        if (bons.isEmpty) break;
      }
      // Filtrer que desactive=0
      final actifs = all
          .where((b) =>
              (int.tryParse((b['desactive'] ?? '0').toString()) ?? 0) == 0)
          .toList();
      // Grouper par code_bon
      final Map<String, List<Map<String, dynamic>>> groups = {};
      for (final b in actifs) {
        final code = (b['code_bon'] ?? '').toString();
        if (code.isEmpty) continue;
        groups.putIfAbsent(code, () => []).add(b);
      }
      // Garder uniquement ceux avec >= 2 occurrences
      final result = <Map<String, dynamic>>[];
      for (final entry in groups.entries) {
        if (entry.value.length >= 2) {
          double total = 0.0;
          for (final b in entry.value) {
            total += double.tryParse((b['montant'] ?? b['quantite'] ?? '0')
                    .toString()
                    .replaceAll(' ', '')
                    .replaceAll('\u00A0', '')) ??
                0.0;
          }
          result.add({
            'code_bon': entry.key,
            'occurrences': entry.value,
            'total': total
          });
        }
      }
      _items.addAll(result);
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
          const SnackBar(content: Text('Un des doublons a été désactivé')));
      await _refresh();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Échec de la désactivation")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF17333F),
        title: const Text('Doublons de bons (par code)'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh))
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Erreur: $error'))
              : _items.isEmpty
                  ? const Center(child: Text('Aucun doublon'))
                  : RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final g = _items[i];
                          final code = (g['code_bon'] ?? '').toString();
                          final total = _money.format(g['total'] ?? 0);
                          final occs = List<Map<String, dynamic>>.from(
                              g['occurrences'] ?? []);
                          return Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF223C4A),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ExpansionTile(
                              collapsedIconColor: Colors.white54,
                              iconColor: Colors.white70,
                              title: Text('Code $code — Total ${total} F',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              children: [
                                for (final b in occs)
                                  ListTile(
                                    title: Text(
                                        (b['nom_beneficiaire'] ?? '')
                                            .toString(),
                                        style: const TextStyle(
                                            color: Colors.white)),
                                    subtitle: Text(
                                        _money.format(double.tryParse(
                                                    (b['montant'] ??
                                                            b['quantite'] ??
                                                            '0')
                                                        .toString()
                                                        .replaceAll(' ', '')
                                                        .replaceAll(
                                                            '\u00A0', '')) ??
                                                0.0) +
                                            ' F',
                                        style: const TextStyle(
                                            color: Colors.white70)),
                                  ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        right: 12, bottom: 12),
                                    child: TextButton.icon(
                                      onPressed: () => _desactiver(code),
                                      icon: const Icon(Icons.block,
                                          color: Colors.redAccent),
                                      label: const Text('Désactiver un',
                                          style: TextStyle(
                                              color: Colors.redAccent)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
