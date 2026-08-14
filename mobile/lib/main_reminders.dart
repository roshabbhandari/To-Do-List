import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();
  runApp(const ReminderApp());
}

class ReminderApp extends StatelessWidget {
  const ReminderApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Roshab Tasks',
        theme: ThemeData(
          brightness: Brightness.dark,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8B5CF6), brightness: Brightness.dark),
          scaffoldBackgroundColor: const Color(0xFF070B16),
        ),
        home: const ReminderHome(),
      );
}

class ReminderHome extends StatefulWidget {
  const ReminderHome({super.key});
  @override
  State<ReminderHome> createState() => _ReminderHomeState();
}

class _ReminderHomeState extends State<ReminderHome> {
  final title = TextEditingController();
  final Map<int, Map<String, dynamic>> tasks = {};
  int nextId = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    for (final row in prefs.getStringList('release_tasks') ?? []) {
      final p = row.split('|');
      if (p.length < 4) continue;
      final id = int.tryParse(p[0]) ?? nextId++;
      tasks[id] = {'title': p[1], 'done': p[2] == '1', 'reminder': DateTime.tryParse(p[3])};
      nextId = id >= nextId ? id + 1 : nextId;
    }
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('release_tasks', tasks.entries.map((e) => '${e.key}|${e.value['title']}|${e.value['done'] ? 1 : 0}|${e.value['reminder']?.toIso8601String() ?? ''}').toList());
  }

  Future<DateTime?> _pickDateTime() async {
    final date = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 3650)), initialDate: DateTime.now());
    if (date == null || !mounted) return null;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return null;
    final value = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (!value.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose a future time.')));
      return null;
    }
    return value;
  }

  Future<void> _add({DateTime? reminder}) async {
    final text = title.text.trim();
    if (text.isEmpty) return;
    final id = nextId++;
    tasks[id] = {'title': text, 'done': false, 'reminder': reminder};
    if (reminder != null) await NotificationService.instance.scheduleReminder(id: id, title: 'Roshab Tasks', body: text, when: reminder);
    title.clear();
    await _save();
    setState(() {});
  }

  Future<void> _delete(int id) async {
    tasks.remove(id);
    await NotificationService.instance.cancelReminder(id);
    await _save();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Roshab Tasks'), actions: [IconButton(onPressed: () => _add(reminder: DateTime.now().add(const Duration(seconds: 30))), icon: const Icon(Icons.notifications_active))]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF4C1D95), Color(0xFF1E1B4B)]), borderRadius: BorderRadius.circular(24)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Student productivity', style: TextStyle(color: Colors.white70)), SizedBox(height: 6), Text('Tasks + phone alarms', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)), SizedBox(height: 8), Text('Reminders can fire while the app is in the background.', style: TextStyle(color: Colors.white60))])),
        const SizedBox(height: 16),
        TextField(controller: title, decoration: InputDecoration(labelText: 'New task', suffixIcon: IconButton(onPressed: () async { final d = await _pickDateTime(); if (d != null) await _add(reminder: d); }, icon: const Icon(Icons.alarm_add)), border: const OutlineInputBorder()), onSubmitted: (_) => _add()),
        const SizedBox(height: 16),
        ...tasks.entries.map((e) {
          final t = e.value;
          final reminder = t['reminder'] as DateTime?;
          return Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(
            leading: Checkbox(value: t['done'], onChanged: (_) async { setState(() => t['done'] = !(t['done'] as bool)); await _save(); }),
            title: Text(t['title'], style: TextStyle(decoration: t['done'] == true ? TextDecoration.lineThrough : null)),
            subtitle: Text(reminder == null ? 'No reminder' : '⏰ ${reminder.toLocal()}'),
            trailing: IconButton(onPressed: () => _delete(e.key), icon: const Icon(Icons.delete_outline)),
          ));
        }),
        const SizedBox(height: 18),
        const Text('Developed by Roshab Bhandari', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
      ]),
    );
  }
}
