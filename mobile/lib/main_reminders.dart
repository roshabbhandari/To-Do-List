import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8B5CF6), brightness: Brightness.dark),
          scaffoldBackgroundColor: const Color(0xFF070B16),
        ),
        home: const AdvancedTodoHome(),
      );
}

class AdvancedTodoHome extends StatefulWidget {
  const AdvancedTodoHome({super.key});
  @override
  State<AdvancedTodoHome> createState() => _AdvancedTodoHomeState();
}

class _AdvancedTodoHomeState extends State<AdvancedTodoHome> {
  static const _uuid = Uuid();
  final List<Task> tasks = [];
  final selected = <String>{};
  final search = TextEditingController();
  String filter = 'All';
  String sort = 'Due date';
  bool kanban = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final saved = await _storeLoad();
    tasks
      ..clear()
      ..addAll(saved);
    for (final task in tasks) {
      for (final reminder in task.reminders) {
        await NotificationService.instance.scheduleReminder(
          id: _notificationId(task.id, reminder),
          title: task.title,
          body: task.description.isEmpty ? 'Roshab Tasks reminder' : task.description,
          when: reminder,
        );
      }
    }
    if (mounted) setState(() {});
  }

  Future<List<Task>> _storeLoad() async {
    final store = await SharedPreferencesAdapter.load();
    return store;
  }

  Future<void> _save() => SharedPreferencesAdapter.save(tasks);

  int _notificationId(String taskId, DateTime time) => taskId.hashCode ^ time.millisecondsSinceEpoch.hashCode;

  List<Task> get visibleTasks {
    var result = AdvancedTaskService.smartFilter(tasks, filter);
    final query = search.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((t) => t.title.toLowerCase().contains(query) || t.description.toLowerCase().contains(query) || t.tags.any((x) => x.toLowerCase().contains(query))).toList();
    }
    return AdvancedTaskService.sort(result, sort);
  }

  Future<void> _addTask({Task? template}) async {
    final task = template ?? Task(id: _uuid.v4(), title: '');
    final title = TextEditingController(text: task.title);
    final description = TextEditingController(text: task.description);
    String priority = task.priority;
    String category = task.category;
    String recurring = task.recurring;
    int duration = task.estimatedMinutes;
    final tags = TextEditingController(text: task.tags.join(', '));
    final subtasks = [...task.subtasks];
    DateTime? dueAt = task.dueAt;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111827),
      builder: (_) => StatefulBuilder(builder: (context, setSheet) {
        return Padding(
          padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 18),
          child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(template == null ? 'Create advanced task' : 'Use task template', style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            TextField(controller: title, autofocus: template == null, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: DropdownButtonFormField<String>(value: priority, decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()), items: const ['Low','Medium','High','Urgent'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setSheet(() => priority = v ?? 'Medium'))),
              const SizedBox(width: 8),
              Expanded(child: DropdownButtonFormField<String>(value: category, decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()), items: const ['Study','Personal','Work','Project','Shopping','Health'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setSheet(() => category = v ?? 'Study'))),
            ]),
            const SizedBox(height: 10),
            TextField(controller: tags, decoration: const InputDecoration(labelText: 'Tags (comma separated)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: DropdownButtonFormField<String>(value: recurring, decoration: const InputDecoration(labelText: 'Repeat', border: OutlineInputBorder()), items: const ['None','Daily','Weekly','Monthly','Weekdays'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setSheet(() => recurring = v ?? 'None'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Minutes', hintText: duration.toString(), border: const OutlineInputBorder()), onChanged: (v) => duration = int.tryParse(v) ?? duration)),
            ]),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 3650)), initialDate: dueAt ?? DateTime.now());
                if (picked == null || !context.mounted) return;
                final time = await showTimePicker(context: context, initialTime: dueAt == null ? TimeOfDay.now() : TimeOfDay.fromDateTime(dueAt!));
                if (time == null) return;
                setSheet(() => dueAt = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute));
              },
              icon: const Icon(Icons.event),
              label: Text(dueAt == null ? 'Set due date & time' : DateFormat('EEE, MMM d • HH:mm').format(dueAt!)),
            ),
            const SizedBox(height: 8),
            _sectionLabel('Subtasks'),
            ...subtasks.asMap().entries.map((entry) => ListTile(dense: true, title: Text(entry.value.title), leading: Checkbox(value: entry.value.completed, onChanged: (v) => setSheet(() => entry.value.completed = v ?? false)), trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => setSheet(() => subtasks.removeAt(entry.key))))),
            TextButton.icon(onPressed: () { final c = TextEditingController(); showDialog<void>(context: context, builder: (_) => AlertDialog(title: const Text('Add subtask'), content: TextField(controller: c, autofocus: true), actions: [TextButton(onPressed: () { if (c.text.trim().isNotEmpty) { setSheet(() => subtasks.add(Subtask(id: _uuid.v4(), title: c.text.trim()))); } Navigator.pop(context); }, child: const Text('Add'))]); }, icon: const Icon(Icons.add_task), label: const Text('Add subtask')),
            const SizedBox(height: 8),
            _sectionLabel('Multiple reminders'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              ...task.reminders.map((r) => InputChip(label: Text(DateFormat('MMM d • HH:mm').format(r)), onDeleted: () => setSheet(() => task.reminders.remove(r)))),
              ActionChip(label: const Text('+ Add reminder'), avatar: const Icon(Icons.alarm_add, size: 18), onPressed: () async { final r = await _pickFutureDateTime(); if (r != null) setSheet(() => task.reminders.add(r)); }),
            ]),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: () async {
              final value = title.text.trim();
              if (value.isEmpty) return;
              final updated = Task(id: task.id, title: value, description: description.text.trim(), priority: priority, category: category, tags: tags.text.split(',').map((x) => x.trim()).where((x) => x.isNotEmpty).toList(), dueAt: dueAt, reminders: [...task.reminders], recurring: recurring, estimatedMinutes: duration, favorite: task.favorite, archived: task.archived, subtasks: [...subtasks]);
              final index = tasks.indexWhere((t) => t.id == task.id);
              if (index >= 0) { tasks[index] = updated; } else { tasks.add(updated); }
              for (final r in updated.reminders) { await NotificationService.instance.scheduleReminder(id: _notificationId(updated.id, r), title: updated.title, body: updated.description.isEmpty ? 'Roshab Tasks reminder' : updated.description, when: r); }
              await _save();
              if (context.mounted) Navigator.pop(context);
              setState(() {});
            }, icon: const Icon(Icons.save), label: const Text('Save advanced task')),
          ]),
        );
      }),
    );
  }

  Future<DateTime?> _pickFutureDateTime() async {
    final date = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 3650)), initialDate: DateTime.now());
    if (date == null || !mounted) return null;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return null;
    final result = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    return result.isAfter(DateTime.now()) ? result : null;
  }

  Future<void> _toggleDone(Task task) async { task.completed = !task.completed; await _save(); setState(() {}); }

  Future<void> _deleteSelected() async {
    for (final id in selected) {
      final task = tasks.firstWhere((t) => t.id == id);
      for (final r in task.reminders) await NotificationService.instance.cancelReminder(_notificationId(task.id, r));
    }
    tasks.removeWhere((t) => selected.contains(t.id));
    selected.clear();
    await _save();
    setState(() {});
  }

  Future<void> _insertTemplate(Task template) async => _addTask(template: TaskTemplateService.templates().firstWhere((t) => t.title == template.title));

  @override
  Widget build(BuildContext context) {
    final stats = AdvancedTaskService.statistics(tasks);
    final visible = visibleTasks;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Roshab Tasks', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(onPressed: () => showSearch(context: context, delegate: _TaskSearchDelegate(tasks)), icon: const Icon(Icons.search)),
          PopupMenuButton<String>(onSelected: (v) => setState(() => sort = v), itemBuilder: (_) => const [PopupMenuItem(value: 'Due date', child: Text('Sort by due date')), PopupMenuItem(value: 'Priority', child: Text('Sort by priority')), PopupMenuItem(value: 'Title', child: Text('Sort by title')), PopupMenuItem(value: 'Duration', child: Text('Sort by duration'))]),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF4C1D95), Color(0xFF1E1B4B)]), borderRadius: BorderRadius.circular(24)), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Advanced task manager', style: TextStyle(color: Colors.white70)), const SizedBox(height: 6), const Text('Plan everything. Miss nothing.', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)), const SizedBox(height: 12), Text('${stats['open']} open • ${stats['overdue']} overdue • ${stats['today']} today', style: const TextStyle(color: Colors.white60))]), IconButton(onPressed: () => setState(() => kanban = !kanban), icon: Icon(kanban ? Icons.view_list : Icons.view_kanban, color: const Color(0xFFD8B4FE))) ])),
        const SizedBox(height: 12),
        TextField(controller: search, onChanged: (_) => setState(() {}), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search title, description or tags', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['All','Today','Upcoming','Overdue','Completed','Recurring','Favorites','Archived'].map((v) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(v), selected: filter == v, onSelected: (_) => setState(() => filter = v))).toList())),
        const SizedBox(height: 12),
        if (selected.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: const Color(0xFF17112A), borderRadius: BorderRadius.circular(16)), child: Row(children: [Text('${selected.length} selected'), const Spacer(), TextButton(onPressed: () async { for (final id in selected) { final t = tasks.firstWhere((x) => x.id == id); t.completed = true; } selected.clear(); await _save(); setState(() {}); }, child: const Text('Complete')), TextButton(onPressed: _deleteSelected, child: const Text('Delete'))])),
        const SizedBox(height: 8),
        if (kanban) _kanban(visible) else ...visible.map(_taskCard),
        const SizedBox(height: 18),
        _sectionLabel('Quick templates'),
        ...TaskTemplateService.templates().map((t) => Card(color: const Color(0xFF111827), child: ListTile(leading: const Icon(Icons.auto_awesome, color: Color(0xFFC4B5FD)), title: Text(t.title), subtitle: Text('${t.subtasks.length} subtasks • ${t.estimatedMinutes} min'), trailing: IconButton(onPressed: () => _insertTemplate(t), icon: const Icon(Icons.add))))),
        const SizedBox(height: 14),
        Center(child: Text('Developed by Roshab Bhandari', style: const TextStyle(color: Colors.white38))),
      ]),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _addTask(), icon: const Icon(Icons.add), label: const Text('Task')),
    );
  }

  Widget _kanban(List<Task> list) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: _kanbanColumn('Open', list.where((t) => !t.completed).toList())),
      const SizedBox(width: 10),
      Expanded(child: _kanbanColumn('Done', list.where((t) => t.completed).toList())),
    ]);
  }

  Widget _kanbanColumn(String title, List<Task> list) => Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(18)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 8), ...list.map((t) => Card(color: const Color(0xFF111827), child: Padding(padding: const EdgeInsets.all(10), child: Text(t.title))))]));

  Widget _taskCard(Task task) => Card(color: const Color(0xFF111827), margin: const EdgeInsets.only(bottom: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: task.priority == 'Urgent' ? Colors.redAccent.withOpacity(.7) : Colors.white10)), child: ExpansionTile(
        leading: Checkbox(value: selected.contains(task.id), onChanged: (_) => setState(() => selected.contains(task.id) ? selected.remove(task.id) : selected.add(task.id))),
        title: Text(task.title, style: TextStyle(fontWeight: FontWeight.w700, decoration: task.completed ? TextDecoration.lineThrough : null)),
        subtitle: Text('${task.priority} • ${task.category}${task.dueAt == null ? '' : ' • ${DateFormat('MMM d HH:mm').format(task.dueAt!)}'}', style: const TextStyle(color: Colors.white54)),
        trailing: IconButton(onPressed: () => _toggleDone(task), icon: Icon(task.completed ? Icons.undo : Icons.check_circle_outline, color: const Color(0xFFC4B5FD))),
        children: [Padding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (task.description.isNotEmpty) Text(task.description), if (task.tags.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Wrap(spacing: 6, children: task.tags.map((t) => Chip(label: Text(t))).toList())), if (task.subtasks.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('${(task.progress * 100).round()}% subtasks complete')), if (task.reminders.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('${task.reminders.length} reminder(s) scheduled', style: const TextStyle(color: Colors.white54))), Row(children: [TextButton.icon(onPressed: () => _addTask(template: task), icon: const Icon(Icons.edit), label: const Text('Edit')), TextButton.icon(onPressed: () async { final copy = AdvancedTaskService.duplicate(task, _uuid.v4()); tasks.add(copy); await _save(); setState(() {}); }, icon: const Icon(Icons.copy), label: const Text('Duplicate')), TextButton.icon(onPressed: () => setState(() => task.favorite = !task.favorite), icon: Icon(task.favorite ? Icons.star : Icons.star_border), label: const Text('Favorite'))])])));

  Widget _sectionLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)));
}

class _TaskSearchDelegate extends SearchDelegate<String> {
  _TaskSearchDelegate(this.tasks);
  final List<Task> tasks;
  @override
  List<Widget>? buildActions(BuildContext context) => [IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear))];
  @override
  Widget? buildLeading(BuildContext context) => IconButton(onPressed: () => close(context, ''), icon: const Icon(Icons.arrow_back));
  @override
  Widget buildResults(BuildContext context) => _results();
  @override
  Widget buildSuggestions(BuildContext context) => _results();
  Widget _results() => ListView(children: tasks.where((t) => t.title.toLowerCase().contains(query.toLowerCase()) || t.tags.any((x) => x.toLowerCase().contains(query.toLowerCase()))).map((t) => ListTile(title: Text(t.title), subtitle: Text(t.category))).toList());
}

class SharedPreferencesAdapter {
  static Future<List<Task>> load() async {
    final prefs = await SharedPreferencesAdapterImpl.instance;
    return (prefs.getStringList('advanced_tasks') ?? []).map((x) => Task.fromJson(Map<String, dynamic>.from(jsonDecode(x) as Map))).toList();
  }
  static Future<void> save(List<Task> tasks) async {
    final prefs = await SharedPreferencesAdapterImpl.instance;
    await prefs.setStringList('advanced_tasks', tasks.map((t) => jsonEncode(t.toJson())).toList());
  }
}

class SharedPreferencesAdapterImpl {
  static Future<SharedPreferences> get instance async => await SharedPreferences.getInstance();
}
