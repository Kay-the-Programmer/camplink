import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  static const _key = 'product_search_history';
  static const _max = 8;

  Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  Future<void> add(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    list.remove(q);
    list.insert(0, q);
    await prefs.setStringList(_key, list.take(_max).toList());
  }

  Future<void> remove(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    list.remove(query);
    await prefs.setStringList(_key, list);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
