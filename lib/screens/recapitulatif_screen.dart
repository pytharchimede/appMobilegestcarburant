import 'dart:convert';
import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:excel/excel.dart' as xls;

import '../services/api_services.dart';
import 'historique_bons_screen.dart';

class RecapitulatifScreen extends StatefulWidget {
  const RecapitulatifScreen({super.key});
  @override
  State<RecapitulatifScreen> createState() => _RecapitulatifScreenState();
}

enum RecapPeriod { day, week, month, year, custom }

class _RecapitulatifScreenState extends State<RecapitulatifScreen> {
  final api = ApiService();

  RecapPeriod period = RecapPeriod.week;
  DateTimeRange? range;
  bool loading = false;
  String? error;

  // Données agrégées
  int bonsCount = 0;
  double bonsTotal = 0;
  Map<DateTime, double> bonsParJour = {};
  double totalRechargement = 0;
  double totalServi = 0;

  // Statuts
  int nbDecaisse = 0;
  int nbAttente = 0;
  int nbAnnule = 0;
  double mtDecaisse = 0;
  double mtAttente = 0;
  double mtAnnule = 0;

  // Liste complète de la période
  List<Map<String, dynamic>> _bonsList = [];

  // Filtres mini-tableau
  final Set<String> _miniSelectedStatuses = {'decaisse', 'attente', 'annule'};

  final _short = NumberFormat.compact(locale: 'fr_FR');
  final _money = NumberFormat('#,##0', 'fr_FR');
  final String _uploadsBaseUrl = 'https://fidest.ci/decaissement/uploads/';

  @override
  void initState() {
    super.initState();
    range = _weekRange(DateTime.now());
    _load();
  }

  DateTimeRange _weekRange(DateTime d) {
    final first = d.subtract(Duration(days: d.weekday - 1));
    final last = first.add(const Duration(days: 6));
    return DateTimeRange(
        start: DateTime(first.year, first.month, first.day),
        end: DateTime(last.year, last.month, last.day));
  }

  DateTimeRange _monthRange(DateTime d) {
    final first = DateTime(d.year, d.month, 1);
    final last = DateTime(d.year, d.month + 1, 0);
    return DateTimeRange(start: first, end: last);
  }

  DateTimeRange _yearRange(int year) {
    final first = DateTime(year, 1, 1);
    final last = DateTime(year, 12, 31);
    return DateTimeRange(start: first, end: last);
  }

  Future<void> _pickRange() async {
    switch (period) {
      case RecapPeriod.day:
        final picked = await showDatePicker(
          context: context,
          initialDate: range?.start ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          setState(() => range = DateTimeRange(start: picked, end: picked));
          _load();
        }
        break;
      case RecapPeriod.week:
        final picked = await showDatePicker(
          context: context,
          initialDate: range?.start ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          setState(() => range = _weekRange(picked));
          _load();
        }
        break;
      case RecapPeriod.month:
        final picked = await showDatePicker(
          context: context,
          initialDate: range?.start ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          setState(() => range = _monthRange(picked));
          _load();
        }
        break;
      case RecapPeriod.year:
        final picked = await showDatePicker(
          context: context,
          initialDate: range?.start ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          setState(() => range = _yearRange(picked.year));
          _load();
        }
        break;
      case RecapPeriod.custom:
        final picked = await showDateRangePicker(
          context: context,
          initialDateRange: range ?? _weekRange(DateTime.now()),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          setState(() => range = picked);
          _load();
        }
        break;
    }
  }

  Future<void> _load() async {
    if (range == null) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      // Récupère tous les bons filtrés (pagination)
      int page = 1;
      bool hasMore = true;
      int count = 0;
      double total = 0;
      final byDay = <DateTime, double>{};
      final all = <Map<String, dynamic>>[];
      while (hasMore) {
        final resp = await api.fetchBons(
          page: page,
          dateDebut: range!.start,
          dateFin: range!.end,
        );
        final bons = List<Map<String, dynamic>>.from(resp['bons']);
        all.addAll(bons);
        count += bons.length;
        total = (resp['montantTotal'] ?? total).toDouble();
        for (final b in bons) {
          final ds = (b['date'] ?? b['date_sortie'] ?? b['date_entree'] ?? '')
              .toString();
          DateTime? d;
          if (ds.isNotEmpty) d = DateTime.tryParse(ds);
          d ??= range!.start; // fallback
          final dayKey = DateTime(d.year, d.month, d.day);
          final m = (b['montant'] ?? b['quantite'] ?? 0).toString();
          final val =
              double.tryParse(m.replaceAll(' ', '').replaceAll('\u00A0', '')) ??
                  0.0;
          byDay.update(dayKey, (prev) => prev + val, ifAbsent: () => val);
        }
        hasMore = resp['hasMore'] == true;
        page++;
        if (page > 50) break; // garde-fou
      }

      // Agrégation par statut
      int cDec = 0, cAtt = 0, cAnn = 0;
      double tDec = 0, tAtt = 0, tAnn = 0;
      for (final b in all) {
        final status = _resolveBonStatus(b);
        final m = (b['montant'] ?? b['quantite'] ?? 0).toString();
        final val =
            double.tryParse(m.replaceAll(' ', '').replaceAll('\u00A0', '')) ??
                0.0;
        if (status == 'decaisse') {
          cDec++;
          tDec += val;
        } else if (status == 'annule') {
          cAnn++;
          tAnn += val;
        } else {
          cAtt++;
          tAtt += val;
        }
      }

      // Stats entrées/sorties pour le mois/année si possible
      double inTotal = 0, outTotal = 0;
      try {
        if (period == RecapPeriod.month) {
          final d = range!.start;
          final stats =
              await api.fetchSoldeEvolutionStats(annee: d.year, mois: d.month);
          inTotal = (stats['totalRechargement'] ?? 0).toDouble();
          outTotal = (stats['totalServi'] ?? 0).toDouble();
        } else if (period == RecapPeriod.year) {
          final y = range!.start.year;
          final stats = await api.fetchSoldeEvolutionStats(annee: y);
          inTotal = (stats['totalRechargement'] ?? 0).toDouble();
          outTotal = (stats['totalServi'] ?? 0).toDouble();
        }
      } catch (_) {}

      setState(() {
        bonsCount = count;
        bonsTotal = total;
        bonsParJour = byDay;
        _bonsList = all;
        nbDecaisse = cDec;
        nbAttente = cAtt;
        nbAnnule = cAnn;
        mtDecaisse = tDec;
        mtAttente = tAtt;
        mtAnnule = tAnn;
        totalRechargement = inTotal;
        totalServi = outTotal;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _periodTitle();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF17333F),
        title: const Text('Récapitulatif'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.ios_share, color: Colors.white),
            onSelected: (v) {
              switch (v) {
                case 'csv':
                  _exportCsv();
                  break;
                case 'excel':
                  _exportExcel();
                  break;
                case 'pdf':
                  _exportPdf();
                  break;
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'csv', child: Text('Exporter CSV')),
              PopupMenuItem(value: 'excel', child: Text('Exporter Excel')),
              PopupMenuItem(value: 'pdf', child: Text('Exporter PDF')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PeriodSelector(
              period: period,
              onChanged: (p) {
                setState(() => period = p);
                switch (p) {
                  case RecapPeriod.day:
                    range = DateTimeRange(
                        start: DateTime.now(), end: DateTime.now());
                    break;
                  case RecapPeriod.week:
                    range = _weekRange(DateTime.now());
                    break;
                  case RecapPeriod.month:
                    range = _monthRange(DateTime.now());
                    break;
                  case RecapPeriod.year:
                    range = _yearRange(DateTime.now().year);
                    break;
                  case RecapPeriod.custom:
                    range = _weekRange(DateTime.now());
                    break;
                }
                _load();
              },
              onPick: _pickRange,
              label: title,
            ),
            const SizedBox(height: 16),
            if (loading)
              const Center(child: CircularProgressIndicator())
            else if (error != null)
              Text('Erreur: $error',
                  style: const TextStyle(color: Colors.redAccent))
            else ...[
              _KpiRow(
                items: [
                  _Kpi('Bons générés', _short.format(bonsCount),
                      Icons.receipt_long, Colors.blueAccent),
                  _Kpi('Montant des bons', '${_money.format(bonsTotal)} F',
                      Icons.payments, Colors.orangeAccent),
                  _Kpi(
                      'Décaissés',
                      '${_short.format(nbDecaisse)} | ${_money.format(mtDecaisse)} F',
                      Icons.check_circle,
                      Colors.greenAccent),
                  _Kpi(
                      'En attente',
                      '${_short.format(nbAttente)} | ${_money.format(mtAttente)} F',
                      Icons.schedule,
                      Colors.amber),
                  _Kpi(
                      'Annulés',
                      '${_short.format(nbAnnule)} | ${_money.format(mtAnnule)} F',
                      Icons.cancel,
                      Colors.redAccent),
                ],
              ),
              const SizedBox(height: 16),
              _Card(
                title: 'Montant des bons par jour',
                child: _BonsBarChart(data: bonsParJour),
              ),
              const SizedBox(height: 16),
              if (totalRechargement > 0)
                _Card(
                  title: 'Répartition Entrées vs Sorties',
                  child: _InOutPie(
                    inTotal: totalRechargement,
                    outTotal: totalServi > 0 ? totalServi : bonsTotal,
                  ),
                ),
              const SizedBox(height: 16),
              _Card(
                title: 'Derniers bons de la période',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _statusChip('decaisse', 'Décaissé', Colors.green),
                        _statusChip('attente', 'En attente', Colors.amber),
                        _statusChip('annule', 'Annulé', Colors.redAccent),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () {
                            if (range == null) return;
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => HistoriqueBonsScreen(
                                  initialDateDebut: range!.start,
                                  initialDateFin: range!.end,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.open_in_new,
                              color: Colors.white70, size: 18),
                          label: const Text('Voir tout',
                              style: TextStyle(color: Colors.white70)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _LatestBonsTable(
                      bons: _filteredLatestBons(null),
                      onExportCsv: () => _exportCsvOf(
                          _filteredLatestBons(null), 'derniers_bons'),
                      onExportExcel: () => _exportExcelOf(
                          _filteredLatestBons(null), 'derniers_bons'),
                      onExportPdf: () => _exportPdfOf(
                          _filteredLatestBons(null), 'derniers_bons'),
                      resolveStatus: _resolveBonStatusRich,
                      onVoirRecu: _handleVoirRecu,
                      onShowInfo: _showMotifInfo,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _resolveBonStatus(Map<String, dynamic> bon) {
    final desactive = int.tryParse(bon['desactive']?.toString() ?? '0') ?? 0;
    final img = (bon['img_recu_station'] ?? '').toString().trim();
    final hasReceipt = img.isNotEmpty;
    if (desactive == 1) return 'annule';
    if (hasReceipt) return 'decaisse';
    return 'attente';
  }

  // Version enrichie (label/couleur/icône/url reçu)
  ({
    String label,
    Color color,
    IconData icon,
    bool hasReceipt,
    String? receiptUrl
  }) _resolveBonStatusRich(Map<String, dynamic> bon) {
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
      label: 'En attente',
      color: Colors.amber,
      icon: Icons.schedule,
      hasReceipt: false,
      receiptUrl: null,
    );
  }

  // Extrait la date d'un bon (fallback au start de la période)
  DateTime _dateOf(Map<String, dynamic> b) {
    final ds = (b['date'] ??
            b['date_sortie'] ??
            b['date_entree'] ??
            b['date_demande'] ??
            '')
        .toString();
    DateTime? d;
    if (ds.isNotEmpty) d = DateTime.tryParse(ds);
    d ??= range?.start ?? DateTime.now();
    return d;
  }

  // Filtrage par statut; n=null => renvoyer toute la liste filtrée
  List<Map<String, dynamic>> _filteredLatestBons([int? n]) {
    final list = [..._bonsList];
    list.sort((a, b) => _dateOf(b).compareTo(_dateOf(a)));
    final filtered = list
        .where((b) => _miniSelectedStatuses.contains(_resolveBonStatus(b)))
        .toList();
    if (n == null) return filtered;
    return filtered.take(n).toList();
  }

  Widget _statusChip(String key, String label, Color color) {
    final selected = _miniSelectedStatuses.contains(key);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (v) {
        setState(() {
          if (v) {
            _miniSelectedStatuses.add(key);
          } else {
            _miniSelectedStatuses.remove(key);
            if (_miniSelectedStatuses.isEmpty) {
              _miniSelectedStatuses.add(key); // garder au moins un
            }
          }
        });
      },
      backgroundColor: const Color(0xFF223C4A),
      selectedColor: color.withOpacity(0.25),
      checkmarkColor: color,
      labelStyle: const TextStyle(color: Colors.white70),
      side:
          BorderSide(color: selected ? color.withOpacity(0.6) : Colors.white10),
    );
  }

  void _showMotifInfo(String text) {
    final content = (text.isNotEmpty) ? text : 'Aucune information';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF17333F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title:
            const Text('Informations', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Text(content, style: const TextStyle(color: Colors.white70)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child:
                const Text('Fermer', style: TextStyle(color: Colors.white70)),
          )
        ],
      ),
    );
  }

  // Ouvre le reçu: Web -> navigateur, Mobile -> dialog avec aperçu image
  Future<void> _handleVoirRecu(String url) async {
    final uri = Uri.parse(url);
    if (kIsWeb) {
      if (!await launchUrl(uri, mode: LaunchMode.platformDefault)) {
        _toast("Impossible d'ouvrir le reçu");
      }
      return;
    }
    final cacheBust = DateTime.now().millisecondsSinceEpoch;
    final urlWithBust =
        url.contains('?') ? "$url&_=$cacheBust" : "$url?_=$cacheBust";
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF17333F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 360,
            height: 480,
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: const Color(0xFF223C4A),
                  child: Row(
                    children: [
                      const Text('Aperçu du reçu',
                          style: TextStyle(color: Colors.white70)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () =>
                            launchUrl(uri, mode: LaunchMode.platformDefault),
                        icon: const Icon(Icons.open_in_new,
                            color: Colors.lightBlueAccent, size: 18),
                        label: const Text('Ouvrir',
                            style: TextStyle(color: Colors.lightBlueAccent)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: InteractiveViewer(
                    child: Image.network(
                      urlWithBust,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Impossible de charger le reçu',
                              style: TextStyle(color: Colors.white54)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _exportCsv() async {
    await _exportCsvOf(_bonsList, 'recap_bons');
  }

  Future<void> _exportCsvOf(
      List<Map<String, dynamic>> list, String name) async {
    if (kIsWeb) {
      _toast('Export CSV non supporté sur Web');
      return;
    }
    try {
      final sb = StringBuffer();
      sb.writeln('Code;Montant;Bénéficiaire;Date;Statut');
      for (final b in list) {
        final code = (b['code_bon'] ?? '').toString();
        final montant = (b['montant'] ?? b['quantite'] ?? '').toString();
        final bene = (b['nom_beneficiaire'] ?? '').toString();
        final date = (b['date_demande'] ?? b['date'] ?? '').toString();
        final statut = _resolveBonStatus(b);
        sb.writeln('$code;$montant;$bene;$date;$statut');
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$name.csv');
      await file.writeAsString(sb.toString(), encoding: utf8);
      await OpenFile.open(file.path);
    } catch (e) {
      _toast('Erreur export CSV');
    }
  }

  Future<void> _exportExcel() async {
    await _exportExcelOf(_bonsList, 'recap_bons');
  }

  Future<void> _exportExcelOf(
      List<Map<String, dynamic>> list, String name) async {
    if (kIsWeb) {
      _toast('Export Excel non supporté sur Web');
      return;
    }
    try {
      final book = xls.Excel.createExcel();
      final sheet = book['Recap'];
      sheet.appendRow(['Code', 'Montant', 'Bénéficiaire', 'Date', 'Statut']);
      for (final b in list) {
        final code = (b['code_bon'] ?? '').toString();
        final montant = (b['montant'] ?? b['quantite'] ?? '').toString();
        final bene = (b['nom_beneficiaire'] ?? '').toString();
        final date = (b['date_demande'] ?? b['date'] ?? '').toString();
        final statut = _resolveBonStatus(b);
        sheet.appendRow([code, montant, bene, date, statut]);
      }
      final bytes = book.encode()!;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$name.xlsx');
      await file.writeAsBytes(bytes, flush: true);
      await OpenFile.open(file.path);
    } catch (e) {
      _toast('Erreur export Excel');
    }
  }

  Future<void> _exportPdf() async {
    await _exportPdfOf(_bonsList, 'recap_bons');
  }

  Future<void> _exportPdfOf(
      List<Map<String, dynamic>> list, String name) async {
    if (kIsWeb) {
      _toast('Export PDF non supporté sur Web');
      return;
    }
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (ctx) => [
            pw.Text('Récapitulatif des bons',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text(_periodTitle()),
            pw.SizedBox(height: 12),
            pw.Table.fromTextArray(
              headers: ['Code', 'Montant', 'Bénéficiaire', 'Date', 'Statut'],
              data: list
                  .map((b) => [
                        (b['code_bon'] ?? '').toString(),
                        (b['montant'] ?? b['quantite'] ?? '').toString(),
                        (b['nom_beneficiaire'] ?? '').toString(),
                        (b['date_demande'] ?? b['date'] ?? '').toString(),
                        _resolveBonStatus(b),
                      ])
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey300),
              cellPadding: const pw.EdgeInsets.all(4),
            ),
          ],
        ),
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$name.pdf');
      await file.writeAsBytes(await pdf.save(), flush: true);
      await OpenFile.open(file.path);
    } catch (e) {
      _toast('Erreur export PDF');
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _periodTitle() {
    if (range == null) return '';
    final deviceLocale = Localizations.maybeLocaleOf(context);
    final canonical = Intl.canonicalizedLocale(
        deviceLocale?.toString() ?? Intl.getCurrentLocale());
    final df = DateFormat('dd/MM/yyyy', canonical);
    switch (period) {
      case RecapPeriod.day:
        return df.format(range!.start);
      case RecapPeriod.week:
        return '${df.format(range!.start)} — ${df.format(range!.end)}';
      case RecapPeriod.month:
        try {
          return DateFormat('MMMM yyyy', canonical).format(range!.start);
        } catch (_) {
          // Fallback sûr si la locale n'est pas initialisée
          return DateFormat('MMMM yyyy').format(range!.start);
        }
      case RecapPeriod.year:
        return DateFormat('yyyy', canonical).format(range!.start);
      case RecapPeriod.custom:
        return '${df.format(range!.start)} — ${df.format(range!.end)}';
    }
  }
}

class _PeriodSelector extends StatelessWidget {
  final RecapPeriod period;
  final ValueChanged<RecapPeriod> onChanged;
  final VoidCallback onPick;
  final String label;

  const _PeriodSelector({
    required this.period,
    required this.onChanged,
    required this.onPick,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    Widget chip(RecapPeriod p, String text) => ChoiceChip(
          label: Text(text),
          selected: period == p,
          onSelected: (_) => onChanged(p),
        );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF223C4A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              chip(RecapPeriod.day, 'Jour'),
              chip(RecapPeriod.week, 'Semaine'),
              chip(RecapPeriod.month, 'Mois'),
              chip(RecapPeriod.year, 'Année'),
              chip(RecapPeriod.custom, 'Intervalle'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70)),
              TextButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.date_range, color: Colors.white70),
                label: const Text('Changer la période',
                    style: TextStyle(color: Colors.white70)),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _KpiRow extends StatelessWidget {
  final List<_Kpi> items;
  const _KpiRow({required this.items});
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _KpiCard(item: items[i]),
    );
  }
}

class _Kpi {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _Kpi(this.label, this.value, this.icon, this.color);
}

class _KpiCard extends StatelessWidget {
  final _Kpi item;
  const _KpiCard({required this.item});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF223C4A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: item.color.withOpacity(0.18),
            child: Icon(item.icon, color: item.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 2),
                Text(item.value,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF17333F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _BonsBarChart extends StatelessWidget {
  final Map<DateTime, double> data;
  const _BonsBarChart({required this.data});
  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Text('Aucune donnée',
          style: TextStyle(color: Colors.white54));
    }
    final entries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final df = DateFormat('dd/MM');
    final maxY =
        entries.map((e) => e.value).fold<double>(0, (p, v) => v > p ? v : p);
    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceBetween,
          maxY: (maxY * 1.2) > 0 ? (maxY * 1.2) : 1,
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i >= 0 && i < entries.length) {
                    final step = (entries.length / 6).ceil().clamp(1, 10);
                    if (i % step == 0) {
                      return Text(df.format(entries[i].key),
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 10));
                    }
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          barGroups: List.generate(entries.length, (i) {
            return BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                  toY: entries[i].value,
                  color: Colors.orangeAccent,
                  width: 10,
                  borderRadius: BorderRadius.circular(4)),
            ]);
          }),
        ),
      ),
    );
  }
}

class _InOutPie extends StatelessWidget {
  final double inTotal;
  final double outTotal;
  const _InOutPie({required this.inTotal, required this.outTotal});
  @override
  Widget build(BuildContext context) {
    final total = (inTotal + outTotal) <= 0 ? 1.0 : (inTotal + outTotal);
    final inPct = inTotal / total;
    final outPct = outTotal / total;
    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: [
            PieChartSectionData(
              color: Colors.greenAccent,
              value: inPct,
              title: 'Entrées\n${(inPct * 100).toStringAsFixed(0)}% ',
              titleStyle: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
            PieChartSectionData(
              color: Colors.redAccent,
              value: outPct,
              title: 'Sorties\n${(outPct * 100).toStringAsFixed(0)}% ',
              titleStyle: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _LatestBonsTable extends StatelessWidget {
  final List<Map<String, dynamic>> bons;
  final VoidCallback onExportCsv;
  final VoidCallback onExportExcel;
  final VoidCallback onExportPdf;
  final ({
    String label,
    Color color,
    IconData icon,
    bool hasReceipt,
    String? receiptUrl
  })
      Function(Map<String, dynamic>) resolveStatus;
  final Future<void> Function(String url) onVoirRecu;
  final void Function(String text)? onShowInfo;

  const _LatestBonsTable({
    required this.bons,
    required this.onExportCsv,
    required this.onExportExcel,
    required this.onExportPdf,
    required this.resolveStatus,
    required this.onVoirRecu,
    this.onShowInfo,
  });

  @override
  Widget build(BuildContext context) {
    if (bons.isEmpty) {
      return const Text('Aucun bon', style: TextStyle(color: Colors.white54));
    }
    final money = NumberFormat('#,##0', 'fr_FR');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('${bons.length} affichés',
                style: const TextStyle(color: Colors.white54)),
            const Spacer(),
            _MiniBtn(icon: Icons.table_view, label: 'CSV', onTap: onExportCsv),
            const SizedBox(width: 8),
            _MiniBtn(icon: Icons.grid_on, label: 'Excel', onTap: onExportExcel),
            const SizedBox(width: 8),
            _MiniBtn(
                icon: Icons.picture_as_pdf, label: 'PDF', onTap: onExportPdf),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF223C4A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _row(
                context,
                header: true,
                code: 'Code',
                montant: 'Montant',
                beneficiaire: 'Bénéficiaire',
                date: 'Date',
                statut: 'Statut',
                action: 'Reçu',
                infoHeader: 'Infos',
              ),
              const Divider(height: 1, color: Colors.white10),
              ...bons.map((b) {
                final st = resolveStatus(b);
                final infoText =
                    (b['motif'] ?? b['note'] ?? b['notes'] ?? '').toString();
                return Column(
                  children: [
                    _row(
                      context,
                      code: (b['code_bon'] ?? '').toString(),
                      montant:
                          '${money.format(double.tryParse((b['montant'] ?? b['quantite'] ?? '0').toString()) ?? 0)} F',
                      beneficiaire: (b['nom_beneficiaire'] ?? '').toString(),
                      date: (b['date_demande'] ?? b['date'] ?? '').toString(),
                      statutWidget: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: st.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: st.color.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(st.icon, size: 14, color: st.color),
                            const SizedBox(width: 6),
                            Text(st.label, style: TextStyle(color: st.color)),
                          ],
                        ),
                      ),
                      actionWidget: st.hasReceipt
                          ? InkWell(
                              onTap: () => onVoirRecu(st.receiptUrl!),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.image,
                                      size: 16, color: Colors.lightBlueAccent),
                                  SizedBox(width: 4),
                                  Text('Voir reçu',
                                      style: TextStyle(
                                          color: Colors.lightBlueAccent)),
                                ],
                              ),
                            )
                          : const Text('-',
                              style: TextStyle(color: Colors.white24)),
                      infoWidget:
                          _InfoIcon(text: infoText, onShowInfo: onShowInfo),
                    ),
                    const Divider(height: 1, color: Colors.white10),
                  ],
                );
              }).take(10),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(
    BuildContext ctx, {
    bool header = false,
    required String code,
    String? montant,
    String? beneficiaire,
    String? date,
    String? statut,
    String? action,
    Widget? statutWidget,
    Widget? actionWidget,
    String? infoHeader,
    Widget? infoWidget,
  }) {
    final styleHead =
        const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600);
    final styleCell = const TextStyle(color: Colors.white);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(code,
                style: header ? styleHead : styleCell,
                overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 2,
            child: header
                ? Text(montant ?? '', style: styleHead)
                : Text(montant ?? '',
                    style: styleCell, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 3,
            child: header
                ? Text(beneficiaire ?? '', style: styleHead)
                : Text(beneficiaire ?? '',
                    style: styleCell, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 2,
            child: header
                ? Text(date ?? '', style: styleHead)
                : Text(date ?? '',
                    style: styleCell, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 3,
            child: header
                ? Text(statut ?? '', style: styleHead)
                : (statutWidget ?? const SizedBox.shrink()),
          ),
          Expanded(
            flex: 2,
            child: header
                ? Text(action ?? '', style: styleHead)
                : Align(
                    alignment: Alignment.centerLeft,
                    child: actionWidget ?? const SizedBox.shrink()),
          ),
          Expanded(
            flex: 1,
            child: header
                ? Text(infoHeader ?? '', style: styleHead)
                : Align(
                    alignment: Alignment.centerLeft,
                    child: infoWidget ?? const SizedBox.shrink(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _InfoIcon extends StatelessWidget {
  final String text;
  final void Function(String text)? onShowInfo;
  const _InfoIcon({required this.text, this.onShowInfo});
  @override
  Widget build(BuildContext context) {
    final icon = Icon(Icons.info_outline, size: 18, color: Colors.white70);
    final label = text.isNotEmpty ? text : 'Aucune information';
    if (kIsWeb) {
      return Tooltip(
        message: label,
        child: icon,
      );
    }
    return GestureDetector(
      onLongPress: () => onShowInfo?.call(label),
      child: icon,
    );
  }
}

class _MiniBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MiniBtn(
      {required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: const Color(0xFF223C4A),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      icon: Icon(icon, color: Colors.white70, size: 16),
      label: Text(label, style: const TextStyle(color: Colors.white70)),
    );
  }
}
