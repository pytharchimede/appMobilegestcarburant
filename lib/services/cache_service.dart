import 'dart:convert';
import 'package:hive/hive.dart';

class CacheService {
  static const String _historyBox = 'history_cache_box';
  static const String _statsKey = 'stats_all';
  static const String _rowsKey = 'rows_all';
  static const String _tsKey = 'timestamp';
  // Clés additionnelles pour cache des bons
  static const String _bonsPrefix = 'bons_page_';
  static const String _bonsMetaKey =
      'bons_meta'; // stocker infos (pages mises en cache)
  static const Duration defaultTtl = Duration(hours: 1);

  static Future<void> init() async {
    if (!Hive.isBoxOpen(_historyBox)) {
      await Hive.openBox(_historyBox);
    }
  }

  static Future<void> saveFullHistory(
      List<Map<String, dynamic>> rows, Map<String, dynamic> stats) async {
    final box = Hive.box(_historyBox);
    box.put(_rowsKey, jsonEncode(rows));
    box.put(_statsKey, jsonEncode(stats));
    box.put(_tsKey, DateTime.now().toIso8601String());
  }

  static Future<(List<Map<String, dynamic>>?, Map<String, dynamic>?)>
      loadFullHistory({Duration? ttl}) async {
    final box = Hive.box(_historyBox);
    if (!box.containsKey(_tsKey)) return (null, null);
    final tsStr = box.get(_tsKey) as String?;
    if (tsStr == null) return (null, null);
    final ts = DateTime.tryParse(tsStr);
    if (ts == null) return (null, null);
    final life = ttl ?? defaultTtl;
    if (DateTime.now().difference(ts) > life) return (null, null);
    try {
      final rowsJson = box.get(_rowsKey) as String?;
      final statsJson = box.get(_statsKey) as String?;
      if (rowsJson == null || statsJson == null) return (null, null);
      final rows = List<Map<String, dynamic>>.from(jsonDecode(rowsJson));
      final stats = Map<String, dynamic>.from(jsonDecode(statsJson));
      return (rows, stats);
    } catch (_) {
      return (null, null);
    }
  }

  static Future<void> clear() async {
    final box = Hive.box(_historyBox);
    await box.clear();
  }

  // ================== BONS (historique paginé) ==================
  static Future<void> saveBonsPage(int page, List<Map<String, dynamic>> bons,
      {double? montantTotal, bool? hasMore}) async {
    final box = Hive.box(_historyBox);
    box.put('${_bonsPrefix}$page', jsonEncode(bons));
    Map<String, dynamic> meta = {};
    if (box.containsKey(_bonsMetaKey)) {
      try {
        meta = jsonDecode(box.get(_bonsMetaKey)) as Map<String, dynamic>;
      } catch (_) {}
    }
    meta['updated_at'] = DateTime.now().toIso8601String();
    final mt = (montantTotal ?? meta['montantTotal']) ?? 0;
    if (montantTotal != null) meta['montantTotal'] = mt;
    if (hasMore != null) meta['hasMore_$page'] = hasMore;
    // marquer page comme présente
    final pages = (meta['pages'] as List?)?.cast<int>() ?? <int>[];
    if (!pages.contains(page)) pages.add(page);
    meta['pages'] = pages;
    box.put(_bonsMetaKey, jsonEncode(meta));
  }

  static Future<(List<Map<String, dynamic>>?, Map<String, dynamic>?)>
      loadBonsPage(int page, {Duration? ttl}) async {
    final box = Hive.box(_historyBox);
    if (!box.containsKey(_bonsMetaKey)) return (null, null);
    final metaRaw = box.get(_bonsMetaKey) as String?;
    if (metaRaw == null) return (null, null);
    Map<String, dynamic>? meta;
    try {
      meta = jsonDecode(metaRaw) as Map<String, dynamic>;
    } catch (_) {
      return (null, null);
    }
    final tsStr = meta['updated_at']?.toString();
    final ts = tsStr != null ? DateTime.tryParse(tsStr) : null;
    final life = ttl ?? defaultTtl;
    if (ts == null || DateTime.now().difference(ts) > life) return (null, null);
    final key = '${_bonsPrefix}$page';
    if (!box.containsKey(key)) return (null, null);
    try {
      final jsonStr = box.get(key) as String?;
      if (jsonStr == null) return (null, null);
      final list = List<Map<String, dynamic>>.from(jsonDecode(jsonStr));
      return (list, meta);
    } catch (_) {
      return (null, null);
    }
  }

  // Chargement d'une page de bons en ignorant le TTL (fallback en cas d'échec réseau / JSON)
  static Future<(List<Map<String, dynamic>>?, Map<String, dynamic>?)>
      loadBonsPageStale(int page) async {
    final box = Hive.box(_historyBox);
    if (!box.containsKey(_bonsMetaKey)) return (null, null);
    final metaRaw = box.get(_bonsMetaKey) as String?;
    if (metaRaw == null) return (null, null);
    Map<String, dynamic>? meta;
    try {
      meta = jsonDecode(metaRaw) as Map<String, dynamic>;
    } catch (_) {
      return (null, null);
    }
    final key = '${_bonsPrefix}$page';
    if (!box.containsKey(key)) return (null, null);
    try {
      final jsonStr = box.get(key) as String?;
      if (jsonStr == null) return (null, null);
      final list = List<Map<String, dynamic>>.from(jsonDecode(jsonStr));
      return (list, meta);
    } catch (_) {
      return (null, null);
    }
  }

  static Future<void> clearBonsCache() async {
    final box = Hive.box(_historyBox);
    final keysToRemove = box.keys
        .where((k) => k.toString().startsWith(_bonsPrefix) || k == _bonsMetaKey)
        .toList();
    for (final k in keysToRemove) {
      box.delete(k);
    }
  }
}
