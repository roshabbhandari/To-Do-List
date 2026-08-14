import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'models/task.dart';
import 'services/notification_service.dart';
import 'services/task_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  runApp(const RoshabTasksApp());
}

class RoshabTasksApp extends StatelessWidget {
  const RoshabTasksApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Roshab Tasks',
    theme: ThemeData(useMaterial3: true, brightness: Brightness.dark, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8B5CF6), brightness: Brightness.dark), scaffoldBackgroundColor: const Color(0xFF070B16)),
    home: const TaskHome(),
  );
}

class TaskHome extends StatefulWidget {
  const TaskHome({super.key});
  @override
  State<TaskHome> createState() => _TaskHomeState();
}

class _TaskHomeState extends State<TaskHome> {
  final store = TaskStore();
  final search = TextEditingController();
  final uuid = const Uuid();
  final tasks = <Task>[];
  final selected = <String>{};
  int tab = 0;
  String filter = 'All';
  String sort = 'Due date';
  bool kanban = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    tasks.addAll(await store.load());
    for (final task in tasks) {
      for (final reminder in task.reminders) {
        await NotificationService.instance.schedule(id: _nid(task, reminder), title: task.title, body: task.description.isEmpty ? 'Roshab Tasks reminder' : task.description, when: reminder, recurring: task.recurring);
      }
    }
    if (mounted) setState(() {});
  }

  int _nid(Task task, DateTime date) => task.id.hashCode ^ date.millisecondsSinceEpoch.hashCode;

  Future<void> _save() => store.save(tasks);

  List<Task> get visible {
    final now = DateTime.now();
    var list = tasks.where((t) {
      switch (filter) {
        case 'Today': return (t.dueAt != null && _sameDay(t.dueAt!, now)) || t.nextReminder != null && _sameDay(t.nextReminder!, now);
        case 'Upcoming': return !t.completed && ((t.dueAt?.isAfter(now) ?? false) || (t.nextReminder?.isAfter(now) ?? false));
        case 'Overdue': return !t.completed && t.dueAt != null && t.dueAt!.isBefore(now);
        case 'Completed': return t.completed;
        case 'Recurring': return t.recurring != 'None';
        case 'Favorites': return t.favorite && !t.archived;
        case 'Archived': return t.archived;
        default: return !t.archived;
      }
    }).toList();
    final q = search.text.trim().toLowerCase();
    if (q.isNotEmpty) list = list.where((t) => t.title.toLowerCase().contains(q) || t.description.toLowerCase().contains(q) || t.tags.any((x) => x.toLowerCase().contains(q))).toList();
    int p(String x) => {'Urgent': 0, 'High': 1, 'Medium': 2, 'Low': 3}[x] ?? 4;
    list.sort((a, b) {
      if (sort == 'Priority') return p(a.priority).compareTo(p(b.priority));
      if (sort == 'Title') return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      if (sort == 'Duration') return a.estimatedMinutes.compareTo(b.estimatedMinutes);
      return (a.dueAt ?? DateTime(9999)).compareTo(b.dueAt ?? DateTime(9999));
    });
    return list;
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  Future<DateTime?> _pickDateTime() async {
    final d = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 3650)), initialDate: DateTime.now());
    if (d == null || !mounted) return null;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t == null) return null;
    final value = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    return value.isAfter(DateTime.now()) ? value : null;
  }

  Future<void> _editTask({Task? source}) async {
    final base = source ?? Task(id: uuid.v4(), title: '');
    final title = TextEditingController(text: base.title);
    final desc = TextEditingController(text: base.description);
    final tags = TextEditingController(text: base.tags.join(', '));
    var priority = base.priority;
    var category = base.category;
    var repeat = base.recurring;
    var due = base.dueAt;
    var minutes = base.estimatedMinutes;
    var reminders = [...base.reminders];
    var subs = [...base.subtasks];

    await showModalBottomSheet<void>(context: context, isScrollControlled: true, backgroundColor: const Color(0xFF111827), builder: (sheet) => StatefulBuilder(builder: (ctx, setSheet) => Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 18),
      child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(source == null ? 'Create advanced task' : 'Edit task', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        TextField(controller: title, autofocus: source == null, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        TextField(controller: desc, maxLines: 3, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(initialValue: priority, decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()), items: const ['Low','Medium','High','Urgent'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setSheet(() => priority = v ?? priority))),
          const SizedBox(width: 8),
          Expanded(child: DropdownButtonFormField<String>(initialValue: category, decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()), items: const ['Study','Personal','Work','Project','Shopping','Health'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setSheet(() => category = v ?? category))),
        ]),
        const SizedBox(height: 10),
        TextField(controller: tags, decoration: const InputDecoration(labelText: 'Tags, comma separated', border: OutlineInputBorder())),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(initialValue: repeat, decoration: const InputDecoration(labelText: 'Repeat', border: OutlineInputBorder()), items: const ['None','Daily','Weekly'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setSheet(() => repeat = v ?? repeat))),
          const SizedBox(width: 8),
          Expanded(child: TextField(keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Minutes', hintText: '$minutes', border: const OutlineInputBorder()), onChanged: (v) => minutes = int.tryParse(v) ?? minutes)),
        ]),
        const SizedBox(height: 10),
        OutlinedButton.icon(onPressed: () async { final x = await _pickDateTime(); if (x != null) setSheet(() => due = x); }, icon: const Icon(Icons.event), label: Text(due == null ? 'Set due date' : DateFormat('EEE, MMM d • HH:mm').format(due!))),
        const SizedBox(height: 10),
        Row(children: [const Text('Reminders', style: TextStyle(fontWeight: FontWeight.w800)), const Spacer(), TextButton.icon(onPressed: () async { final x = await _pickDateTime(); if (x != null) setSheet(() => reminders.add(x)); }, icon: const Icon(Icons.alarm_add), label: const Text('Add'))]),
        Wrap(spacing: 6, runSpacing: 6, children: reminders.map((r) => InputChip(label: Text(DateFormat('MMM d HH:mm').format(r)), onDeleted: () => setSheet(() => reminders.remove(r)))).toList()),
        const SizedBox(height: 10),
        Row(children: [const Text('Subtasks', style: TextStyle(fontWeight: FontWeight.w800)), const Spacer(), TextButton.icon(onPressed: () async { final c = TextEditingController(); await showDialog<void>(context: context, builder: (_) => AlertDialog(title: const Text('New subtask'), content: TextField(controller: c, autofocus: true), actions: [TextButton(onPressed: () { if (c.text.trim().isNotEmpty) setSheet(() => subs.add(Subtask(id: uuid.v4(), title: c.text.trim()))); Navigator.pop(context); }, child: const Text('Add'))])); }, icon: const Icon(Icons.add_task), label: const Text('Add'))]),
        ...subs.map((s) => CheckboxListTile(value: s.completed, onChanged: (v) => setSheet(() => s.completed = v ?? false), title: Text(s.title))),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: () async {
          final value = title.text.trim();
          if (value.isEmpty) return;
          final updated = Task(id: base.id, title: value, description: desc.text.trim(), priority: priority, category: category, tags: tags.text.split(',').map((x) => x.trim()).where((x) => x.isNotEmpty).toList(), dueAt: due, reminders: reminders, recurring: repeat, estimatedMinutes: minutes, favorite: base.favorite, archived: base.archived, subtasks: subs);
          final i = tasks.indexWhere((t) => t.id == base.id);
          if (i >= 0) tasks[i] = updated; else tasks.add(updated);
          for (final r in reminders) await NotificationService.instance.schedule(id: _nid(updated, r), title: updated.title, body: updated.description.isEmpty ? 'Roshab Tasks reminder' : updated.description, when: r, recurring: repeat);
          await _save();
          if (sheet.mounted) Navigator.pop(sheet);
          if (mounted) setState(() {});
        }, icon: const Icon(Icons.save), label: const Text('Save task')),
      ]),
    )));
  }

  Future<void> _toggle(Task task) async { task.completed = !task.completed; await _save(); setState(() {}); }
  Future<void> _deleteSelected() async { tasks.removeWhere((t) => selected.contains(t.id)); selected.clear(); await _save(); setState(() {}); }

  @override
  Widget build(BuildContext context) {
    final list = visible;
    final done = tasks.where((t) => t.completed).length;
    final pages = [_dashboard(done), _tasks(list), _calendar(), _stats(done), _profile()];
    return Scaffold(
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab = v), destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.checklist_outlined), selectedIcon: Icon(Icons.checklist), label: 'Tasks'),
        NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Calendar'),
        NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Stats'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
      ]),
      floatingActionButton: tab == 1 ? FloatingActionButton.extended(onPressed: _editTask, icon: const Icon(Icons.add), label: const Text('Task')) : null,
    );
  }

  Widget _dashboard(int done) => ListView(padding: const EdgeInsets.all(20), children: [
    const Text('Good day 👋', style: TextStyle(color: Colors.white70)),
    const SizedBox(height: 4), const Text('Roshab Tasks', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
    const SizedBox(height: 4), const Text('Plan. Focus. Finish.', style: TextStyle(color: Colors.white54)),
    const SizedBox(height: 20),
    _panel(Icons.auto_awesome, 'Advanced task manager', const Text('Subtasks, recurring tasks, multiple alarms, smart filters, search and Kanban view.', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
    Row(children: [Expanded(child: _metric('Tasks', '${tasks.length}', Icons.task_alt)), const SizedBox(width: 10), Expanded(child: _metric('Done', '$done', Icons.check_circle_outline))]),
    const SizedBox(height: 10),
    _panel(Icons.notifications_active, 'Reminders', Text('${tasks.fold<int>(0, (sum, t) => sum + t.reminders.length)} scheduled reminders across your tasks.')),
  ]);

  Widget _tasks(List<Task> list) => ListView(padding: const EdgeInsets.all(20), children: [
    Row(children: [const Expanded(child: Text('My Tasks', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900))), IconButton(onPressed: () => setState(() => kanban = !kanban), icon: Icon(kanban ? Icons.view_list : Icons.view_kanban))]),
    TextField(controller: search, onChanged: (_) => setState(() {}), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search tasks, descriptions or tags', border: OutlineInputBorder())),
    const SizedBox(height: 10),
    SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['All','Today','Upcoming','Overdue','Completed','Recurring','Favorites','Archived'].map((x) => Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(label: Text(x), selected: filter == x, onSelected: (_) => setState(() => filter = x))).toList())),
    const SizedBox(height: 10),
    Row(children: [Expanded(child: DropdownButtonFormField<String>(initialValue: sort, items: const ['Due date','Priority','Title','Duration'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setState(() => sort = v ?? sort))), const SizedBox(width: 8), if (selected.isNotEmpty) FilledButton(onPressed: _deleteSelected, child: Text('Delete ${selected.length}'))]),
    const SizedBox(height: 10),
    if (list.isEmpty) _panel(Icons.inbox_outlined, 'No tasks', const Text('Create a task to get started.')) else if (kanban) _kanban(list) else ...list.map(_taskCard),
  ]);

  Widget _taskCard(Task t) => Card(color: const Color(0xFF111827), margin: const EdgeInsets.only(bottom: 10), child: ExpansionTile(
    leading: Checkbox(value: selected.contains(t.id), onChanged: (_) => setState(() => selected.contains(t.id) ? selected.remove(t.id) : selected.add(t.id))),
    title: Text(t.title, style: TextStyle(fontWeight: FontWeight.w700, decoration: t.completed ? TextDecoration.lineThrough : null)),
    subtitle: Text('${t.priority} • ${t.category}${t.dueAt == null ? '' : ' • ${DateFormat('MMM d HH:mm').format(t.dueAt!)}'}', style: const TextStyle(color: Colors.white54)),
    trailing: IconButton(onPressed: () => _toggle(t), icon: Icon(t.completed ? Icons.undo : Icons.check_circle_outline, color: const Color(0xFFC4B5FD))),
    children: [Padding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (t.description.isNotEmpty) Text(t.description),
      if (t.tags.isNotEmpty) Wrap(spacing: 4, children: t.tags.map((x) => Chip(label: Text(x))).toList()),
      const SizedBox(height: 6),
      Text('Subtasks: ${t.subtasks.where((s) => s.completed).length}/${t.subtasks.length} • Reminders: ${t.reminders.length}'),
      Row(children: [TextButton.icon(onPressed: () => _editTask(source: t), icon: const Icon(Icons.edit), label: const Text('Edit')), TextButton.icon(onPressed: () async { tasks.add(Task(id: uuid.v4(), title: '${t.title} (copy)', description: t.description, priority: t.priority, category: t.category, tags: [...t.tags], dueAt: t.dueAt, reminders: [...t.reminders], recurring: t.recurring, estimatedMinutes: t.estimatedMinutes, subtasks: t.subtasks.map((s) => Subtask(id: uuid.v4(), title: s.title)).toList())); await _save(); setState(() {}); }, icon: const Icon(Icons.copy), label: const Text('Duplicate')), TextButton.icon(onPressed: () async { t.favorite = !t.favorite; await _save(); setState(() {}); }, icon: Icon(t.favorite ? Icons.star : Icons.star_border), label: const Text('Favorite'))]),
    ]))],
  ));

  Widget _kanban(List<Task> list) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: _column('Open', list.where((t) => !t.completed).toList())), const SizedBox(width: 10), Expanded(child: _column('Done', list.where((t) => t.completed).toList()))]);
  Widget _column(String title, List<Task> items) => Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(18)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 8), ...items.map((t) => Card(child: ListTile(dense: true, title: Text(t.title), onTap: () => _toggle(t))))]));

  Widget _calendar() { final dated = tasks.where((t) => t.dueAt != null || t.nextReminder != null).toList()..sort((a,b) => (a.nextReminder ?? a.dueAt ?? DateTime.now()).compareTo(b.nextReminder ?? b.dueAt ?? DateTime.now())); return ListView(padding: const EdgeInsets.all(20), children: [const Text('Calendar', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)), const SizedBox(height: 8), const Text('Deadlines and reminders', style: TextStyle(color: Colors.white54)), const SizedBox(height: 16), if (dated.isEmpty) _panel(Icons.event_busy, 'No scheduled items', const Text('Tasks with dates and reminders appear here.')) else ...dated.map((t) => Card(color: const Color(0xFF111827), child: ListTile(leading: const Icon(Icons.event, color: Color(0xFFC4B5FD)), title: Text(t.title), subtitle: Text(t.nextReminder == null ? DateFormat('EEE, MMM d • HH:mm').format(t.dueAt!) : DateFormat('EEE, MMM d • HH:mm').format(t.nextReminder!))))]); }

  Widget _stats(int done) => ListView(padding: const EdgeInsets.all(20), children: [const Text('Productivity', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)), const SizedBox(height: 12), _metric('Completion', tasks.isEmpty ? '0%' : '${(done / tasks.length * 100).round()}%', Icons.insights), const SizedBox(height: 10), _metric('Open', '${tasks.length - done}', Icons.pending_actions), const SizedBox(height: 10), _metric('Recurring', '${tasks.where((t) => t.recurring != 'None').length}', Icons.repeat), const SizedBox(height: 10), _metric('Subtasks', '${tasks.fold<int>(0, (sum, t) => sum + t.subtasks.length)}', Icons.account_tree) ]);

  Widget _profile() => ListView(padding: const EdgeInsets.all(20), children: [const Text('Roshab Tasks', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)), const SizedBox(height: 16), _panel(Icons.person, 'Developer', const Column(children: [CircleAvatar(radius: 40, backgroundColor: Color(0xFF24183C), child: Icon(Icons.person, size: 42, color: Color(0xFFD8B4FE)),), SizedBox(height: 10), Text('Developed by Roshab Bhandari', style: TextStyle(color: Colors.white54))])), const SizedBox(height: 10), _panel(Icons.notifications_active, 'Phone notifications', const Text('Scheduled one-time, daily and weekly task reminders are supported.')), const SizedBox(height: 10), _panel(Icons.lock_outline, 'Offline first', const Text('Tasks are stored locally on the device and remain available without internet.'))]);

  Widget _panel(IconData icon, String title, Widget child) => Container(padding: const EdgeInsets.all(18), margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white10)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: const Color(0xFFC4B5FD)), const SizedBox(width: 10), Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))]), const SizedBox(height: 10), child]));
  Widget _metric(String title, String value, IconData icon) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)), child: Row(children: [Icon(icon, color: const Color(0xFFC4B5FD)), const SizedBox(width: 10), Text(title, style: const TextStyle(color: Colors.white54)), const Spacer(), Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900))]));
}
