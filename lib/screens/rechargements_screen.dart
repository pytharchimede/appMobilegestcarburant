import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_services.dart';

class RechargementsScreen extends StatefulWidget {
  final DateTime? initialStart;
  final DateTime? initialEnd;
  const RechargementsScreen({super.key, this.initialStart, this.initialEnd});

  @override
  State<RechargementsScreen> createState() => _RechargementsScreenState();
}

class _RechargementsScreenState extends State<RechargementsScreen> {
  final api = ApiService();
  final _money = NumberFormat('#,##0', 'fr_FR');
  final String _uploadsBaseUrl = 'https://fidest.ci/decaissement/uploads/';

  DateTimeRange? range;
  bool loading = false;
  String? error;

  final _items = <Map<String, dynamic>>[];
  bool _hasMore = true;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    final start = widget.initialStart ??
        DateTime.now().subtract(const Duration(days: 30));
    final end = widget.initialEnd ?? DateTime.now();
    range = DateTimeRange(
        start: DateTime(start.year, start.month, start.day),
        end: DateTime(end.year, end.month, end.day));
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
        final resp = await api.fetchRechargements(
          page: _page,
          dateDebut: range?.start,
          dateFin: range?.end,
        );
        final rows = List<Map<String, dynamic>>.from(resp['rechargements']);
        _items.addAll(rows);
        _hasMore = resp['hasMore'] == true;
        _page++;
        if (rows.isEmpty) break;
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

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: range,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => range = picked);
      await _refresh();
    }
  }

  String _normalizeReceipt(dynamic v) {
    final img = (v ?? '').toString().trim();
    if (img.isEmpty) return '';
    if (img.startsWith('http')) return img;
    return _uploadsBaseUrl + img;
  }

  Future<void> _openReceipt(String url) async {
    final uri = Uri.parse(url);
    if (kIsWeb) {
      if (!await launchUrl(uri, mode: LaunchMode.platformDefault)) {
        _toast("Impossible d'ouvrir le reçu");
      }
      return;
    }
    if (!await launchUrl(uri, mode: LaunchMode.platformDefault)) {
      _toast("Impossible d'ouvrir le reçu");
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy');
    final title = range == null
        ? 'Rechargements station'
        : 'Rechargements · ${df.format(range!.start)} — ${df.format(range!.end)}';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF17333F),
        title: Text(title),
        actions: [
          IconButton(
            onPressed: _pickRange,
            icon: const Icon(Icons.date_range),
            tooltip: 'Changer la période',
          ),
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Erreur: $error'))
              : _items.isEmpty
                  ? const Center(child: Text('Aucun rechargement'))
                  : RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final r = _items[i];
                          final date =
                              (r['date'] ?? r['jour'] ?? '').toString();
                          final montant = _money.format((r['montant'] ??
                                  r['rechargement'] ??
                                  r['entree'] ??
                                  0) is num
                              ? (r['montant'] ??
                                      r['rechargement'] ??
                                      r['entree'])
                                  .toDouble()
                              : double.tryParse((r['montant'] ??
                                          r['rechargement'] ??
                                          r['entree'] ??
                                          '0')
                                      .toString()
                                      .replaceAll(' ', '')
                                      .replaceAll('\u00A0', '')) ??
                                  0.0);
                          final recuUrl = _normalizeReceipt(
                              r['img_recu'] ?? r['recu'] ?? r['image']);
                          return Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF223C4A),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              leading: const CircleAvatar(
                                backgroundColor: Colors.greenAccent,
                                child: Icon(Icons.add, color: Colors.black87),
                              ),
                              title: Text('+ $montant F',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(date,
                                  style:
                                      const TextStyle(color: Colors.white70)),
                              trailing: (recuUrl.isNotEmpty)
                                  ? TextButton.icon(
                                      onPressed: () => _openReceipt(recuUrl),
                                      icon: const Icon(Icons.image,
                                          size: 18,
                                          color: Colors.lightBlueAccent),
                                      label: const Text('Voir reçu',
                                          style: TextStyle(
                                              color: Colors.lightBlueAccent)),
                                    )
                                  : const Text('-',
                                      style: TextStyle(color: Colors.white24)),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
