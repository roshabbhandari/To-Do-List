import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';

/// Optional cloud-sync adapter. Configure an HTTPS backend endpoint and token
/// through the app's settings before enabling it. No credentials are hard-coded.
class SyncService {
  static const _endpointKey = 'sync_endpoint';
  static const _tokenKey = 'sync_token';
  final _uuid = const Uuid();

  Future<void> configure({required String endpoint, required String token}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_endpointKey, endpoint.trim());
    await prefs.setString(_tokenKey, token.trim());
  }

  Future<bool> isConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString(_endpointKey) ?? '').isNotEmpty &&
        (prefs.getString(_tokenKey) ?? '').isNotEmpty;
  }

  Future<String> exportPayload(List<Task> tasks) async {
    return jsonEncode({
      'clientId': await _clientId(),
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'tasks': tasks.map((t) => t.toJson()).toList(),
    });
  }

  Future<String> _clientId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString('sync_client_id');
    if (existing != null) return existing;
    final id = _uuid.v4();
    await prefs.setString('sync_client_id', id);
    return id;
  }
}
