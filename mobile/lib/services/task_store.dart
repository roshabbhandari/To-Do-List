import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class TaskStore {
  static const _key = 'roshab_tasks_v2';

  Future<List<Task>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final data = jsonDecode(raw) as List<dynamic>;
    return data.map((item) => Task.fromJson(Map<String, dynamic>.from(item as Map))).toList();
  }

  Future<void> save(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(tasks.map((t) => t.toJson()).toList()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
