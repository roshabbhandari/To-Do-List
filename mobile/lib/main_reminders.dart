import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'models/task.dart';
import 'notification_service.dart';
import 'services/advanced_task_service.dart';
import 'services/task_template_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();
  runApp(const RoshabTasksAdvancedApp());
}

class RoshabTasksAdvancedApp extends StatelessWidget {
  const RoshabTasksAdvancedApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Roshab Tasks',
    theme: ThemeData(useMaterial3: true, brightness: Brightness.dark, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8B5CF6), brightness: Brightness.dark), scaffoldBackgroundColor: const Color(0xFF070B16)),
    home: const AdvancedTodoHome(),
  );
}

class AdvancedTodoHome extends StatefulWidget {
  const AdvancedTodoHome({super.key});
  @override
  State<AdvancedTodoHome> createState() => _AdvancedTodoHomeState();
}

class _AdvancedTodoHomeState extends State<AdvancedTodoHome> {
  static const uuid = Uuid();
  final tasks = <Task>[];
  final selected = <String>{};
  final search = TextEditingController();
  String filter = 'All';
  String sort = 'Due date';
  bool kanban = false;

  int notificationId(Task t, DateTime r) => t.id.hashCode ^ r.millisecondsSinceEpoch.hashCode;

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final saved = p.getStringList('advanced_tasks') ?? [];
    tasks..clear()..addAll(saved.map((x) => Task.fromJson(Map<String, dynamic>.from(jsonDecode(x) as Map))));
    for (final t in tasks) for (final r in t.reminders) {
      await NotificationService.instance.scheduleReminder(id: notificationId(t, r), title: t.title, body: t.description.isEmpty ? 'Roshab Tasks reminder' : t.description, when: r);
    }
    if (mounted) setState(() {});
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList('advanced_tasks', tasks.map((t) => jsonEncode(t.toJson())).toList());
  }

  List<Task> get visible {
    var list = AdvancedTaskService.smartFilter(tasks, filter);
    final q = search.text.trim().toLowerCase();
    if (q.isNotEmpty) list = list.where((t) => t.title.toLowerCase().contains(q) || t.description.toLowerCase().contains(q) || t.tags.any((x) => x.toLowerCase().contains(q))).toList();
    return AdvancedTaskService.sort(list, sort);
  }

  Future<DateTime?> pickDateTime() async {
    final d = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 3650)), initialDate: DateTime.now());
    if (d == null || !mounted) return null;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t == null) return null;
    final value = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    return value.isAfter(DateTime.now()) ? value : null;
  }

  Future<void> editTask({Task? seed}) async {
    final base = seed ?? Task(id: uuid.v4(), title: '');
    final title = TextEditingController(text: base.title);
    final desc = TextEditingController(text: base.description);
    final tags = TextEditingController(text: base.tags.join(', '));
    var priority = base.priority;
    var category = base.category;
    var repeat = base.recurring;
    var due = base.dueAt;
    var minutes = base.estimatedMinutes;
    var subs = [...base.subtasks];
    var reminders = [...base.reminders];

    await showModalBottomSheet<void>(context: context, isScrollControlled: true, backgroundColor: const Color(0xFF111827), builder: (_) => StatefulBuilder(builder: (ctx, setSheet) => Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 18),
      child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(seed == null ? 'Create task' : 'Edit task', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        TextField(controller: title, autofocus: seed == null, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        TextField(controller: desc, maxLines: 3, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: DropdownButtonFormField(value: priority, decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()), items: const ['Low','Medium','High','Urgent'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setSheet(() => priority = v!))),
          const SizedBox(width: 8),
          Expanded(child: DropdownButtonFormField(value: category, decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()), items: const ['Study','Personal','Work','Project','Shopping','Health'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setSheet(() => category = v!))),
        ]),
        const SizedBox(height: 10),
        TextField(controller: tags, decoration: const InputDecoration(labelText: 'Tags, comma separated', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: DropdownButtonFormField(value: repeat, decoration: const InputDecoration(labelText: 'Repeat', border: OutlineInputBorder()), items: const ['None','Daily','Weekly','Monthly','Weekdays'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setSheet(() => repeat = v!))),
          const SizedBox(width: 8),
          Expanded(child: TextField(keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Minutes', hintText: '$minutes', border: const OutlineInputBorder()), onChanged: (v) => minutes = int.tryParse(v) ?? minutes)),
        ]),
        const SizedBox(height: 10),
        OutlinedButton.icon(onPressed: () async { final x = await pickDateTime(); if (x != null) setSheet(() => due = x); }, icon: const Icon(Icons.event), label: Text(due == null ? 'Set due date' : DateFormat('EEE, MMM d • HH:mm').format(due!))),
        const SizedBox(height: 8),
        const Text('Subtasks', style: TextStyle(fontWeight: FontWeight.w800)),
        ...subs.map((s) => ListTile(dense: true, leading: Checkbox(value: s.completed, onChanged: (v) => setSheet(() => s.completed = v ?? false)), title: Text(s.title))),
        TextButton.icon(onPressed: () { final c = TextEditingController(); showDialog<void>(context: context, builder: (_) => AlertDialog(title: const Text('New subtask'), content: TextField(controller: c, autofocus: true), actions: [TextButton(onPressed: () { if (c.text.trim().isNotEmpty) setSheet(() => subs.add(Subtask(id: uuid.v4(), title: c.text.trim()))); Navigator.pop(context); }, child: const Text('Add'))]); }, icon: const Icon(Icons.add_task), label: const Text('Add subtask')),
        const Text('Reminders', style: TextStyle(fontWeight: FontWeight.w800)),
        Wrap(spacing: 6, children: reminders.map((r) => InputChip(label: Text(DateFormat('MMM d HH:mm').format(r)), onDeleted: () => setSheet(() => reminders.remove(r)))).toList() + [ActionChip(label: const Text('+ reminder'), onPressed: () async { final x = await pickDateTime(); if (x != null) setSheet(() => reminders.add(x)); })]),
        const SizedBox(height: 14),
        FilledButton.icon(onPressed: () async {
          if (title.text.trim().isEmpty) return;
          final updated = Task(id: base.id, title: title.text.trim(), description: desc.text.trim(), priority: priority, category: category, tags: tags.text.split(',').map((x) => x.trim()).where((x) => x.isNotEmpty).toList(), dueAt: due, reminders: reminders, recurring: repeat, estimatedMinutes: minutes, favorite: base.favorite, archived: base.archived, subtasks: subs);
          final i = tasks.indexWhere((t) => t.id == base.id);
          if (i >= 0) tasks[i] = updated; else tasks.add(updated);
          for (final r in reminders) await NotificationService.instance.scheduleReminder(id: notificationId(updated, r), title: updated.title, body: updated.description.isEmpty ? 'Roshab Tasks reminder' : updated.description, when: r);
          await save();
          if (ctx.mounted) Navigator.pop(ctx);
          setState(() {});
        }, icon: const Icon(Icons.save), label: const Text('Save task')),
      ]),
    )));
  }

  Future<void> deleteSelected() async {
    for (final id in selected) {
      final t = tasks.firstWhere((x) => x.id == id);
      for (final r in t.reminders) await NotificationService.instance.cancelReminder(notificationId(t, r));
    }
    tasks.removeWhere((t) => selected.contains(t.id));
    selected.clear();
    await save();
    setState(() {});
  }

  void toggle(Task t) async { t.completed = !t.completed; await save(); setState(() {}); }

  @override
  Widget build(BuildContext context) {
    final s = AdvancedTaskService.statistics(tasks);
    return Scaffold(
      appBar: AppBar(title: const Text('Roshab Tasks', style: TextStyle(fontWeight: FontWeight.w900)), actions: [IconButton(onPressed: () => showSearch(context: context, delegate: TaskSearch(tasks)), icon: const Icon(Icons.search)), PopupMenuButton<String>(onSelected: (v) => setState(() => sort = v), itemBuilder: (_) => const [PopupMenuItem(value: 'Due date', child: Text('Due date')),PopupMenuItem(value: 'Priority', child: Text('Priority')),PopupMenuItem(value: 'Title', child: Text('Title')),PopupMenuItem(value: 'Duration', child: Text('Duration'))])]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF4C1D95), Color(0xFF1E1B4B)]), borderRadius: BorderRadius.circular(24)), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Advanced task manager', style: TextStyle(color: Colors.white70)), const SizedBox(height: 5), const Text('Plan everything. Miss nothing.', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)), const SizedBox(height: 10), Text('${s['open']} open • ${s['overdue']} overdue • ${s['today']} today', style: const TextStyle(color: Colors.white60))]), IconButton(onPressed: () => setState(() => kanban = !kanban), icon: Icon(kanban ? Icons.view_list : Icons.view_kanban, color: const Color(0xFFD8B4FE)))])),
        const SizedBox(height: 12),
        TextField(controller: search, onChanged: (_) => setState(() {}), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search tasks, descriptions or tags', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['All','Today','Upcoming','Overdue','Completed','Recurring','Favorites','Archived'].map((x) => Padding(padding: const EdgeInsets.only(right: 7), child: ChoiceChip(label: Text(x), selected: filter == x, onSelected: (_) => setState(() => filter = x))).toList())),
        if (selected.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [Text('${selected.length} selected'), const Spacer(), TextButton(onPressed: () async { for (final id in selected) tasks.firstWhere((t) => t.id == id).completed = true; selected.clear(); await save(); setState(() {}); }, child: const Text('Complete')), TextButton(onPressed: deleteSelected, child: const Text('Delete'))])),
        const SizedBox(height: 8),
        if (kanban) _kanban(visible) else ...visible.map(_card),
        const SizedBox(height: 16),
        const Text('Quick templates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ...TaskTemplateService.templates().map((t) => Card(child: ListTile(leading: const Icon(Icons.auto_awesome, color: Color(0xFFC4B5FD)), title: Text(t.title), subtitle: Text('${t.subtasks.length} subtasks • ${t.estimatedMinutes} min • ${t.recurring}'), trailing: IconButton(onPressed: () => editTask(seed: t), icon: const Icon(Icons.add)))),
        const SizedBox(height: 16),
        Center(child: Text('Developed by Roshab Bhandari', style: const TextStyle(color: Colors.white38))),
      ]),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => editTask(), icon: const Icon(Icons.add), label: const Text('Task')),
    );
  }

  Widget _kanban(List<Task> list) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: _column('Open', list.where((t) => !t.completed).toList())), const SizedBox(width: 10), Expanded(child: _column('Done', list.where((t) => t.completed).toList()))]);
  Widget _column(String title, List<Task> items) => Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(18)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 8), ...items.map((t) => Card(child: ListTile(dense: true, title: Text(t.title), trailing: IconButton(onPressed: () => toggle(t), icon: const Icon(Icons.check)))))]));

  Widget _card(Task t) => Card(color: const Color(0xFF111827), margin: const EdgeInsets.only(bottom: 10), child: ExpansionTile(leading: Checkbox(value: selected.contains(t.id), onChanged: (_) => setState(() => selected.contains(t.id) ? selected.remove(t.id) : selected.add(t.id))), title: Text(t.title, style: TextStyle(fontWeight: FontWeight.w700, decoration: t.completed ? TextDecoration.lineThrough : null)), subtitle: Text('${t.priority} • ${t.category}${t.dueAt == null ? '' : ' • ${DateFormat('MMM d HH:mm').format(t.dueAt!)}'}', style: const TextStyle(color: Colors.white54)), trailing: IconButton(onPressed: () => toggle(t), icon: Icon(t.completed ? Icons.undo : Icons.check_circle_outline, color: const Color(0xFFC4B5FD))), children: [Padding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (t.description.isNotEmpty) Text(t.description), if (t.tags.isNotEmpty) Wrap(spacing: 5, children: t.tags.map((x) => Chip(label: Text(x))).toList()), const SizedBox(height: 8), Text('Subtasks: ${t.subtasks.where((x) => x.completed).length}/${t.subtasks.length} • Reminders: ${t.reminders.length}'), Row(children: [TextButton.icon(onPressed: () => editTask(seed: t), icon: const Icon(Icons.edit), label: const Text('Edit')), TextButton.icon(onPressed: () async { tasks.add(AdvancedTaskService.duplicate(t, uuid.v4())); await save(); setState(() {}); }, icon: const Icon(Icons.copy), label: const Text('Duplicate')), TextButton.icon(onPressed: () async { t.favorite = !t.favorite; await save(); setState(() {}); }, icon: Icon(t.favorite ? Icons.star : Icons.star_border), label: const Text('Favorite'))])]))]);
}

class TaskSearch extends SearchDelegate<String> {
  TaskSearch(this.tasks);
  final List<Task> tasks;
  @override List<Widget>? buildActions(BuildContext context) => [IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear))];
  @override Widget? buildLeading(BuildContext context) => IconButton(onPressed: () => close(context, ''), icon: const Icon(Icons.arrow_back));
  @override Widget buildResults(BuildContext context) => results();
  @override Widget buildSuggestions(BuildContext context) => results();
  Widget results() => ListView(children: tasks.where((t) => t.title.toLowerCase().contains(query.toLowerCase()) || t.tags.any((x) => x.toLowerCase().contains(query.toLowerCase()))).map((t) => ListTile(title: Text(t.title), subtitle: Text(t.category))).toList());
}