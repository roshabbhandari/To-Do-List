import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';

class SyncService {
  static const _endpointKey = 'sync_endpoint';
  static const _tokenKey = 'sync_token';
  final _uuid = const Uuid();

  Future<void> configure({required String endpoint, required String token}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_endpointKey, endpoint.trim().replaceAll(RegExp(r'/+$'), ''));
    await prefs.setString(_tokenKey, token.trim());
  }

  Future<bool> isConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString(_endpointKey) ?? '').isNotEmpty && (prefs.getString(_tokenKey) ?? '').isNotEmpty;
  }

  Future<String> register({required String email, required String password}) async {
    final endpoint = await _endpoint();
    final response = await http.post(Uri.parse('$endpoint/auth/register'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': email, 'password': password}));
    if (response.statusCode >= 400) throw Exception('Registration failed: ${response.body}');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['token'] as String?;
    if (token == null) throw Exception('Server did not return a token');
    await _setToken(token);
    return token;
  }

  Future<String> login({required String email, required String password}) async {
    final endpoint = await _endpoint();
    final response = await http.post(Uri.parse('$endpoint/auth/login'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': email, 'password': password}));
    if (response.statusCode >= 400) throw Exception('Login failed: ${response.body}');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['token'] as String?;
    if (token == null) throw Exception('Server did not return a token');
    await _setToken(token);
    return token;
  }

  Future<List<Task>> downloadTasks() async {
    final response = await http.get(Uri.parse('${await _endpoint()}/tasks'), headers: _headers());
    if (response.statusCode >= 400) throw Exception('Sync download failed: ${response.body}');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => Task.fromJson(Map<String, dynamic>.from(item as Map))).toList();
  }

  Future<void> uploadTasks(List<Task> tasks) async {
    final response = await http.put(Uri.parse('${await _endpoint()}/tasks'), headers: {..._headers(), 'Content-Type': 'application/json'}, body: jsonEncode({'tasks': tasks.map((t) => t.toJson()).toList()}));
    if (response.statusCode >= 400) throw Exception('Sync upload failed: ${response.body}');
  }

  Map<String, String> _headers() => {'Authorization': 'Bearer ${_cachedToken ?? ''}'};
  String? _cachedToken;

  Future<void> _setToken(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String> _endpoint() async {
    final prefs = await SharedPreferences.getInstance();
    final endpoint = prefs.getString(_endpointKey);
    if (endpoint == null || endpoint.isEmpty) throw Exception('Configure sync endpoint first');
    if (_cachedToken == null) _cachedToken = prefs.getString(_tokenKey);
    return endpoint;
  }

  Future<String> exportPayload(List<Task> tasks) async => jsonEncode({'clientId': await _clientId(), 'updatedAt': DateTime.now().toUtc().toIso8601String(), 'tasks': tasks.map((t) => t.toJson()).toList()});

  Future<String> _clientId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString('sync_client_id');
    if (existing != null) return existing;
    final id = _uuid.v4();
    await prefs.setString('sync_client_id', id);
    return id;
  }
}
