import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'models/task.dart';
import 'services/notification_service.dart';
import 'services/task_store.dart';

const ink = Color(0xFF090B12);
const surface = Color(0xFF11131B);
const purple = Color(0xFF8B5CF6);
const cyan = Color(0xFF22D3EE);
const pink = Color(0xFFEC4899);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  runApp(const RoshUPApp());
}

class RoshUPApp extends StatelessWidget {
  const RoshUPApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'RoshUP',
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: ink,
          colorScheme: ColorScheme.fromSeed(seedColor: purple, brightness: Brightness.dark),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Colors.white10)),
          ),
          cardTheme: const CardThemeData(color: surface, elevation: 0),
        ),
        home: const RoshUPHome(),
      );
}

class RoshUPHome extends StatefulWidget {
  const RoshUPHome({super.key});

  @override
  State<RoshUPHome> createState() => _RoshUPHomeState();
}

class _RoshUPHomeState extends State<RoshUPHome> {
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
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    tasks.addAll(await store.load());
    for (final task in tasks) {
      for (final reminder in task.reminders) {
        await NotificationService.instance.schedule(
          id: _nid(task, reminder),
          title: task.title,
          body: task.description.isEmpty ? 'RoshUP reminder' : task.description,
          when: reminder,
          recurring: task.recurring,
        );
      }
    }
    if (mounted) setState(() {});
  }

  int _nid(Task task, DateTime date) => task.id.hashCode ^ date.millisecondsSinceEpoch.hashCode;

  Future<void> _save() => store.save(tasks);

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  List<Task> get visible {
    final now = DateTime.now();
    var list = tasks.where((t) {
      switch (filter) {
        case 'Today':
          return (t.dueAt != null && _sameDay(t.dueAt!, now)) || (t.nextReminder != null && _sameDay(t.nextReminder!, now));
        case 'Upcoming':
          return !t.completed && ((t.dueAt?.isAfter(now) ?? false) || (t.nextReminder?.isAfter(now) ?? false));
        case 'Overdue':
          return !t.completed && t.dueAt != null && t.dueAt!.isBefore(now);
        case 'Completed':
          return t.completed;
        case 'Recurring':
          return t.recurring != 'None';
        case 'Favorites':
          return t.favorite && !t.archived;
        case 'Archived':
          return t.archived;
        default:
          return !t.archived;
      }
    }).toList();
    final q = search.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((t) => t.title.toLowerCase().contains(q) || t.description.toLowerCase().contains(q) || t.tags.any((x) => x.toLowerCase().contains(q))).toList();
    }
    int priority(String x) => {'Urgent': 0, 'High': 1, 'Medium': 2, 'Low': 3}[x] ?? 4;
    list.sort((a, b) {
      switch (sort) {
        case 'Priority': return priority(a.priority).compareTo(priority(b.priority));
        case 'Title': return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case 'Duration': return a.estimatedMinutes.compareTo(b.estimatedMinutes);
        default: return (a.dueAt ?? DateTime(9999)).compareTo(b.dueAt ?? DateTime(9999));
      }
    });
    return list;
  }

  Future<DateTime?> _pickDateTime() async {
    final date = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 3650)), initialDate: DateTime.now());
    if (date == null || !mounted) return null;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return null;
    final value = DateTime(date.year, date.month, date.day, time.hour, time.minute);
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

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D0F18),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(ctx).viewInsets.bottom + 18),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(source == null ? 'Create a RoshUP task' : 'Edit task', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              TextField(controller: title, autofocus: source == null, decoration: const InputDecoration(labelText: 'Task title', prefixIcon: Icon(Icons.bolt))),
              const SizedBox(height: 10),
              TextField(controller: desc, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: DropdownButtonFormField<String>(initialValue: priority, decoration: const InputDecoration(labelText: 'Priority'), items: const ['Low', 'Medium', 'High', 'Urgent'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setSheet(() => priority = v ?? priority))),
                const SizedBox(width: 8),
                Expanded(child: DropdownButtonFormField<String>(initialValue: category, decoration: const InputDecoration(labelText: 'Category'), items: const ['Study', 'Personal', 'Work', 'Project', 'Shopping', 'Health'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setSheet(() => category = v ?? category))),
              ]),
              const SizedBox(height: 10),
              TextField(controller: tags, decoration: const InputDecoration(labelText: 'Tags, comma separated')),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: DropdownButtonFormField<String>(initialValue: repeat, decoration: const InputDecoration(labelText: 'Repeat'), items: const ['None', 'Daily', 'Weekly'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setSheet(() => repeat = v ?? repeat))),
                const SizedBox(width: 8),
                Expanded(child: TextField(keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Minutes', hintText: '$minutes'), onChanged: (v) => minutes = int.tryParse(v) ?? minutes)),
              ]),
              const SizedBox(height: 10),
              OutlinedButton.icon(onPressed: () async { final x = await _pickDateTime(); if (x != null) setSheet(() => due = x); }, icon: const Icon(Icons.event), label: Text(due == null ? 'Set due date' : DateFormat('EEE, MMM d • HH:mm').format(due!))),
              const SizedBox(height: 10),
              Row(children: [const Text('Smart reminders', style: TextStyle(fontWeight: FontWeight.w800)), const Spacer(), TextButton.icon(onPressed: () async { final x = await _pickDateTime(); if (x != null) setSheet(() => reminders.add(x)); }, icon: const Icon(Icons.notifications_active), label: const Text('Add'))]),
              Wrap(spacing: 6, runSpacing: 6, children: reminders.map((r) => InputChip(label: Text(DateFormat('MMM d HH:mm').format(r)), onDeleted: () => setSheet(() => reminders.remove(r)))).toList()),
              const SizedBox(height: 10),
              Row(children: [const Text('Subtasks', style: TextStyle(fontWeight: FontWeight.w800)), const Spacer(), TextButton.icon(onPressed: () async { final controller = TextEditingController(); await showDialog<void>(context: ctx, builder: (_) => AlertDialog(title: const Text('New subtask'), content: TextField(controller: controller, autofocus: true), actions: [TextButton(onPressed: () { if (controller.text.trim().isNotEmpty) setSheet(() => subs.add(Subtask(id: uuid.v4(), title: controller.text.trim()))); Navigator.pop(ctx); }, child: const Text('Add'))])); }, icon: const Icon(Icons.add_task), label: const Text('Add'))]),
              ...subs.map((sub) => CheckboxListTile(value: sub.completed, onChanged: (v) => setSheet(() => sub.completed = v ?? false), title: Text(sub.title))),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () async {
                  final value = title.text.trim();
                  if (value.isEmpty) return;
                  final updated = Task(id: base.id, title: value, description: desc.text.trim(), priority: priority, category: category, tags: tags.text.split(',').map((x) => x.trim()).where((x) => x.isNotEmpty).toList(), dueAt: due, reminders: reminders, recurring: repeat, estimatedMinutes: minutes, favorite: base.favorite, archived: base.archived, subtasks: subs);
                  final index = tasks.indexWhere((t) => t.id == base.id);
                  if (index >= 0) {
                    tasks[index] = updated;
                  } else {
                    tasks.add(updated);
                  }
                  for (final reminder in reminders) {
                    await NotificationService.instance.schedule(id: _nid(updated, reminder), title: updated.title, body: updated.description.isEmpty ? 'RoshUP reminder' : updated.description, when: reminder, recurring: repeat);
                  }
                  await _save();
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) setState(() {});
                },
                icon: const Icon(Icons.rocket_launch),
                label: const Text('Save to RoshUP'),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _toggle(Task task) async {
    task.completed = !task.completed;
    await _save();
    if (mounted) setState(() {});
  }

  Future<void> _deleteSelected() async {
    tasks.removeWhere((t) => selected.contains(t.id));
    selected.clear();
    await _save();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final list = visible;
    final done = tasks.where((t) => t.completed).length;
    final pages = [_dashboard(done), _tasks(list), _calendar(), _stats(done), _profile()];
    return Scaffold(
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (index) => setState(() => tab = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.check_circle_outline), selectedIcon: Icon(Icons.check_circle), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Plan'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Stats'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'You'),
        ],
      ),
      floatingActionButton: tab == 1 ? FloatingActionButton.extended(onPressed: _editTask, icon: const Icon(Icons.add), label: const Text('New task')) : null,
    );
  }

  Widget _brandHeader() => Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(gradient: const LinearGradient(colors: [purple, cyan]), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.bolt, color: Colors.white, size: 28)),
        const SizedBox(width: 12),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('RoshUP', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)), Text('Plan higher. Finish faster.', style: TextStyle(color: Colors.white54))]),
      ]);

  Widget _dashboard(int done) => ListView(padding: const EdgeInsets.all(20), children: [
        _brandHeader(),
        const SizedBox(height: 22),
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF32146B), Color(0xFF102B36), Color(0xFF34133F)]), borderRadius: BorderRadius.circular(28)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('YOUR DAY, UPGRADED', style: TextStyle(letterSpacing: 2, color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text(done == tasks.length && tasks.isNotEmpty ? 'Everything is cleared.' : '${tasks.length - done} tasks still moving.', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)), const SizedBox(height: 10), const Text('RoshUP keeps deadlines, alarms and subtasks in one fast workspace.', style: TextStyle(color: Colors.white70))]),
        const SizedBox(height: 14),
        Row(children: [Expanded(child: _metric('Tasks', '${tasks.length}', Icons.flash_on)), const SizedBox(width: 10), Expanded(child: _metric('Done', '$done', Icons.check_circle))]),
        const SizedBox(height: 12),
        _panel(Icons.notifications_active, 'Live reminders', Text('${tasks.fold<int>(0, (sum, t) => sum + t.reminders.length)} scheduled reminder${tasks.fold<int>(0, (sum, t) => sum + t.reminders.length) == 1 ? '' : 's'}', style: const TextStyle(fontWeight: FontWeight.w700))),
        _panel(Icons.auto_awesome, 'Why RoshUP?', const Text('Advanced tasks, recurring schedules, multiple reminders, smart filters, search and Kanban—all designed as one focused To-Do experience.')),
      ]);

  Widget _tasks(List<Task> list) => ListView(padding: const EdgeInsets.all(20), children: [
        Row(children: [const Expanded(child: Text('Tasks', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),), IconButton(onPressed: () => setState(() => kanban = !kanban), icon: Icon(kanban ? Icons.view_list : Icons.view_kanban))]),
        const SizedBox(height: 4),
        const Text('Capture it. Schedule it. RoshUP it.', style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 14),
        TextField(controller: search, onChanged: (_) => setState(() {}), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search everything in your tasks')),
        const SizedBox(height: 10),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['All', 'Today', 'Upcoming', 'Overdue', 'Completed', 'Recurring', 'Favorites', 'Archived'].map((x) => Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(label: Text(x), selected: filter == x, onSelected: (_) => setState(() => filter = x))).toList())),
        const SizedBox(height: 10),
        Row(children: [Expanded(child: DropdownButtonFormField<String>(initialValue: sort, items: const ['Due date', 'Priority', 'Title', 'Duration'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setState(() => sort = v ?? sort))), const SizedBox(width: 8), if (selected.isNotEmpty) FilledButton.tonalIcon(onPressed: _deleteSelected, icon: const Icon(Icons.delete_outline), label: Text('${selected.length} delete'))]),
        const SizedBox(height: 12),
        if (list.isEmpty) _panel(Icons.inbox_outlined, 'Nothing here yet', const Text('Tap New task and give your day a little RoshUP.')) else if (kanban) _kanban(list) else ...list.map(_taskCard),
      ]);

  Widget _taskCard(Task task) => Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: task.priority == 'Urgent' ? pink.withOpacity(.65) : Colors.white10)), child: ExpansionTile(
        leading: Checkbox(value: selected.contains(task.id), onChanged: (_) => setState(() => selected.contains(task.id) ? selected.remove(task.id) : selected.add(task.id))),
        title: Text(task.title, style: TextStyle(fontWeight: FontWeight.w800, decoration: task.completed ? TextDecoration.lineThrough : null)),
        subtitle: Text('${task.priority} • ${task.category}${task.dueAt == null ? '' : ' • ${DateFormat('MMM d HH:mm').format(task.dueAt!)}'}', style: const TextStyle(color: Colors.white54)),
        trailing: IconButton(onPressed: () => _toggle(task), icon: Icon(task.completed ? Icons.undo : Icons.done_all, color: cyan)),
        children: [Padding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (task.description.isNotEmpty) Text(task.description),
          if (task.tags.isNotEmpty) Wrap(spacing: 4, children: task.tags.map((tag) => Chip(label: Text(tag))).toList()),
          const SizedBox(height: 8),
          Text('Subtasks ${task.subtasks.where((s) => s.completed).length}/${task.subtasks.length} • ${task.reminders.length} reminder${task.reminders.length == 1 ? '' : 's'}'),
          Row(children: [TextButton.icon(onPressed: () => _editTask(source: task), icon: const Icon(Icons.edit), label: const Text('Edit')), TextButton.icon(onPressed: () async { tasks.add(Task(id: uuid.v4(), title: '${task.title} copy', description: task.description, priority: task.priority, category: task.category, tags: [...task.tags], dueAt: task.dueAt, reminders: [...task.reminders], recurring: task.recurring, estimatedMinutes: task.estimatedMinutes, subtasks: task.subtasks.map((s) => Subtask(id: uuid.v4(), title: s.title)).toList())); await _save(); setState(() {}); }, icon: const Icon(Icons.copy), label: const Text('Duplicate')), IconButton(onPressed: () async { task.favorite = !task.favorite; await _save(); setState(() {}); }, icon: Icon(task.favorite ? Icons.star : Icons.star_border, color: const Color(0xFFFBBF24)))])
        ]))],
      ));

  Widget _kanban(List<Task> items) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: _column('UP NEXT', items.where((x) => !x.completed).toList())), const SizedBox(width: 10), Expanded(child: _column('DONE', items.where((x) => x.completed).toList()))]);

  Widget _column(String title, List<Task> items) => Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF0F1119), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 12, letterSpacing: 1.5, color: Colors.white54, fontWeight: FontWeight.w800)), const SizedBox(height: 8), ...items.map((x) => Card(child: ListTile(dense: true, title: Text(x.title), onTap: () => _toggle(x))))]);

  Widget _calendar() { final dated = tasks.where((t) => t.dueAt != null || t.nextReminder != null).toList()..sort((a, b) => (a.nextReminder ?? a.dueAt ?? DateTime.now()).compareTo(b.nextReminder ?? b.dueAt ?? DateTime.now())); return ListView(padding: const EdgeInsets.all(20), children: [const Text('Plan', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)), const SizedBox(height: 4), const Text('Deadlines and reminder rhythm', style: TextStyle(color: Colors.white54)), const SizedBox(height: 16), if (dated.isEmpty) _panel(Icons.event_busy, 'Calendar is clear', const Text('Add a due date or alarm to see it here.')) else ...dated.map((task) => Card(child: ListTile(leading: const Icon(Icons.event, color: cyan), title: Text(task.title), subtitle: Text(DateFormat('EEE, MMM d • HH:mm').format(task.nextReminder ?? task.dueAt!))))]); }

  Widget _stats(int done) => ListView(padding: const EdgeInsets.all(20), children: [const Text('Stats', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)), const SizedBox(height: 4), const Text('Momentum, not clutter.', style: TextStyle(color: Colors.white54)), const SizedBox(height: 16), _metric('Completion', tasks.isEmpty ? '0%' : '${(done / tasks.length * 100).round()}%', Icons.insights), const SizedBox(height: 10), _metric('Open', '${tasks.length - done}', Icons.pending_actions), const SizedBox(height: 10), _metric('Recurring', '${tasks.where((t) => t.recurring != 'None').length}', Icons.repeat), const SizedBox(height: 10), _metric('Subtasks', '${tasks.fold<int>(0, (sum, t) => sum + t.subtasks.length)}', Icons.account_tree)]);

  Widget _profile() => ListView(padding: const EdgeInsets.all(20), children: [const Text('RoshUP', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)), const SizedBox(height: 14), _panel(Icons.bolt, 'RoshUP identity', const Text('RoshUP is your fast, focused task workspace by Roshab Bhandari.')), _panel(Icons.notifications_active, 'Phone reminders', const Text('Use one-time, daily and weekly task notifications to stay on schedule.')), _panel(Icons.offline_bolt, 'Offline first', const Text('Tasks stay on the device and keep working without an internet connection.')), const SizedBox(height: 12), const Center(child: Text('Developed by Roshab Bhandari', style: TextStyle(color: Colors.white38)))]);

  Widget _panel(IconData icon, String title, Widget child) => Container(padding: const EdgeInsets.all(18), margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white10)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: cyan), const SizedBox(width: 10), Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))]), const SizedBox(height: 10), child]));

  Widget _metric(String title, String value, IconData icon) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)), child: Row(children: [Icon(icon, color: purple), const SizedBox(width: 10), Text(title, style: const TextStyle(color: Colors.white54)), const Spacer(), Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900))]));
}
