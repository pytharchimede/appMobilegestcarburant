import 'dart:convert';
import 'package:hive/hive.dart';

class CacheService {
  static const String _historyBox = 'history_cache_box';
  static const String _statsKey = 'stats_all';
  static const String _rowsKey = 'rows_all';
  static const String _tsKey = 'timestamp';
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
}
