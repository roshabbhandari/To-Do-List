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
  Widget build(BuildContext context) {
    return MaterialApp(
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
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Colors.white10),
          ),
        ),
        cardTheme: const CardThemeData(color: surface, elevation: 0),
      ),
      home: const RoshUPHome(),
    );
  }
}

class RoshUPHome extends StatefulWidget {
  const RoshUPHome({super.key});

  @override
  State<RoshUPHome> createState() => _RoshUPHomeState();
}

class _RoshUPHomeState extends State<RoshUPHome> {
  final _store = TaskStore();
  final _search = TextEditingController();
  final _uuid = const Uuid();
  final _tasks = <Task>[];
  final _selected = <String>{};

  int _tab = 0;
  String _filter = 'All';
  String _sort = 'Due date';
  bool _kanban = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    _tasks
      ..clear()
      ..addAll(await _store.load());
    for (final task in _tasks) {
      for (final reminder in task.reminders) {
        await NotificationService.instance.schedule(
          id: _notificationId(task, reminder),
          title: task.title,
          body: task.description.isEmpty ? 'RoshUP reminder' : task.description,
          when: reminder,
          recurring: task.recurring,
        );
      }
    }
    if (mounted) setState(() {});
  }

  int _notificationId(Task task, DateTime reminder) {
    return task.id.hashCode ^ reminder.millisecondsSinceEpoch.hashCode;
  }

  Future<void> _saveTasks() => _store.save(_tasks);

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<Task> get _visibleTasks {
    final now = DateTime.now();
    var result = _tasks.where((task) {
      switch (_filter) {
        case 'Today':
          return (task.dueAt != null && _sameDay(task.dueAt!, now)) ||
              (task.nextReminder != null && _sameDay(task.nextReminder!, now));
        case 'Upcoming':
          return !task.completed &&
              ((task.dueAt?.isAfter(now) ?? false) ||
                  (task.nextReminder?.isAfter(now) ?? false));
        case 'Overdue':
          return !task.completed && task.dueAt != null && task.dueAt!.isBefore(now);
        case 'Completed':
          return task.completed;
        case 'Recurring':
          return task.recurring != 'None';
        case 'Favorites':
          return task.favorite && !task.archived;
        case 'Archived':
          return task.archived;
        default:
          return !task.archived;
      }
    }).toList();

    final query = _search.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((task) {
        return task.title.toLowerCase().contains(query) ||
            task.description.toLowerCase().contains(query) ||
            task.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    int priorityValue(String value) {
      switch (value) {
        case 'Urgent':
          return 0;
        case 'High':
          return 1;
        case 'Medium':
          return 2;
        default:
          return 3;
      }
    }

    result.sort((a, b) {
      switch (_sort) {
        case 'Priority':
          return priorityValue(a.priority).compareTo(priorityValue(b.priority));
        case 'Title':
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case 'Duration':
          return a.estimatedMinutes.compareTo(b.estimatedMinutes);
        default:
          return (a.dueAt ?? DateTime(9999)).compareTo(b.dueAt ?? DateTime(9999));
      }
    });
    return result;
  }

  Future<DateTime?> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: DateTime.now(),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return null;
    final value = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    return value.isAfter(DateTime.now()) ? value : null;
  }

  Future<void> _editTask({Task? source}) async {
    final base = source ?? Task(id: _uuid.v4(), title: '');
    final title = TextEditingController(text: base.title);
    final description = TextEditingController(text: base.description);
    final tags = TextEditingController(text: base.tags.join(', '));

    var priority = base.priority;
    var category = base.category;
    var repeat = base.recurring;
    var dueAt = base.dueAt;
    var minutes = base.estimatedMinutes;
    var reminders = [...base.reminders];
    var subtasks = [...base.subtasks];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D0F18),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheet) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                18,
                18,
                MediaQuery.of(context).viewInsets.bottom + 18,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      source == null ? 'Create a RoshUP task' : 'Edit task',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: title,
                      autofocus: source == null,
                      decoration: const InputDecoration(
                        labelText: 'Task title',
                        prefixIcon: Icon(Icons.bolt),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: description,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: priority,
                            decoration: const InputDecoration(labelText: 'Priority'),
                            items: const ['Low', 'Medium', 'High', 'Urgent']
                                .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                                .toList(),
                            onChanged: (value) => setSheet(() => priority = value ?? priority),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: category,
                            decoration: const InputDecoration(labelText: 'Category'),
                            items: const ['Study', 'Personal', 'Work', 'Project', 'Shopping', 'Health']
                                .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                                .toList(),
                            onChanged: (value) => setSheet(() => category = value ?? category),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: tags,
                      decoration: const InputDecoration(labelText: 'Tags, comma separated'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: repeat,
                            decoration: const InputDecoration(labelText: 'Repeat'),
                            items: const ['None', 'Daily', 'Weekly']
                                .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                                .toList(),
                            onChanged: (value) => setSheet(() => repeat = value ?? repeat),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(labelText: 'Minutes', hintText: '$minutes'),
                            onChanged: (value) => minutes = int.tryParse(value) ?? minutes,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final value = await _pickDateTime();
                        if (value != null) setSheet(() => dueAt = value);
                      },
                      icon: const Icon(Icons.event),
                      label: Text(
                        dueAt == null
                            ? 'Set due date'
                            : DateFormat('EEE, MMM d • HH:mm').format(dueAt!),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('Smart reminders', style: TextStyle(fontWeight: FontWeight.w800)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () async {
                            final value = await _pickDateTime();
                            if (value != null) setSheet(() => reminders.add(value));
                          },
                          icon: const Icon(Icons.notifications_active),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: reminders
                          .map(
                            (reminder) => InputChip(
                              label: Text(DateFormat('MMM d HH:mm').format(reminder)),
                              onDeleted: () => setSheet(() => reminders.remove(reminder)),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('Subtasks', style: TextStyle(fontWeight: FontWeight.w800)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () async {
                            final controller = TextEditingController();
                            await showDialog<void>(
                              context: context,
                              builder: (dialogContext) {
                                return AlertDialog(
                                  title: const Text('New subtask'),
                                  content: TextField(controller: controller, autofocus: true),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        final value = controller.text.trim();
                                        if (value.isNotEmpty) {
                                          setSheet(() => subtasks.add(Subtask(id: _uuid.v4(), title: value)));
                                        }
                                        Navigator.pop(dialogContext);
                                      },
                                      child: const Text('Add'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          icon: const Icon(Icons.add_task),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    ...subtasks.map(
                      (subtask) => CheckboxListTile(
                        value: subtask.completed,
                        onChanged: (value) => setSheet(() => subtask.completed = value ?? false),
                        title: Text(subtask.title),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () async {
                        final value = title.text.trim();
                        if (value.isEmpty) return;

                        final updated = Task(
                          id: base.id,
                          title: value,
                          description: description.text.trim(),
                          priority: priority,
                          category: category,
                          tags: tags.text
                              .split(',')
                              .map((value) => value.trim())
                              .where((value) => value.isNotEmpty)
                              .toList(),
                          dueAt: dueAt,
                          reminders: reminders,
                          recurring: repeat,
                          estimatedMinutes: minutes,
                          favorite: base.favorite,
                          archived: base.archived,
                          subtasks: subtasks,
                        );

                        final index = _tasks.indexWhere((task) => task.id == base.id);
                        if (index >= 0) {
                          _tasks[index] = updated;
                        } else {
                          _tasks.add(updated);
                        }

                        for (final reminder in reminders) {
                          await NotificationService.instance.schedule(
                            id: _notificationId(updated, reminder),
                            title: updated.title,
                            body: updated.description.isEmpty ? 'RoshUP reminder' : updated.description,
                            when: reminder,
                            recurring: repeat,
                          );
                        }

                        await _saveTasks();
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                        if (mounted) setState(() {});
                      },
                      icon: const Icon(Icons.rocket_launch),
                      label: const Text('Save to RoshUP'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _toggle(Task task) async {
    task.completed = !task.completed;
    await _saveTasks();
    if (mounted) setState(() {});
  }

  Future<void> _deleteSelected() async {
    _tasks.removeWhere((task) => _selected.contains(task.id));
    _selected.clear();
    await _saveTasks();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleTasks;
    final done = _tasks.where((task) => task.completed).length;
    final pages = [
      _homePage(done),
      _tasksPage(visible),
      _planPage(),
      _statsPage(done),
      _profilePage(),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.check_circle_outline), selectedIcon: Icon(Icons.check_circle), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Plan'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Stats'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'You'),
        ],
      ),
      floatingActionButton: _tab == 1
          ? FloatingActionButton.extended(
              onPressed: _editTask,
              icon: const Icon(Icons.add),
              label: const Text('New task'),
            )
          : null,
    );
  }

  Widget _brandHeader() {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [purple, cyan]),
            borderRadius: BorderRadius.circular(17),
          ),
          child: const Icon(Icons.bolt, color: Colors.white, size: 29),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('RoshUP', style: TextStyle(fontSize: 29, fontWeight: FontWeight.w900)),
            Text('Plan higher. Finish faster.', style: TextStyle(color: Colors.white54)),
          ],
        ),
      ],
    );
  }

  Widget _homePage(int done) {
    final reminderCount = _tasks.fold<int>(0, (sum, task) => sum + task.reminders.length);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _brandHeader(),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF32146B), Color(0xFF102B36), Color(0xFF34133F)],
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'YOUR DAY, UPGRADED',
                style: TextStyle(letterSpacing: 2, color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                done == _tasks.length && _tasks.isNotEmpty
                    ? 'Everything is cleared.'
                    : '${_tasks.length - done} tasks still moving.',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              const Text(
                'RoshUP keeps deadlines, alarms and subtasks in one fast workspace.',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _metric('Tasks', '${_tasks.length}', Icons.flash_on)),
            const SizedBox(width: 10),
            Expanded(child: _metric('Done', '$done', Icons.check_circle)),
          ],
        ),
        const SizedBox(height: 12),
        _panel(
          Icons.notifications_active,
          'Live reminders',
          Text('$reminderCount scheduled reminder${reminderCount == 1 ? '' : 's'}'),
        ),
        _panel(
          Icons.auto_awesome,
          'Why RoshUP?',
          const Text(
            'Advanced tasks, recurring schedules, multiple reminders, smart filters, search and Kanban in one focused To-Do experience.',
          ),
        ),
      ],
    );
  }

  Widget _tasksPage(List<Task> tasks) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Tasks', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
            ),
            IconButton(
              onPressed: () => setState(() => _kanban = !_kanban),
              icon: Icon(_kanban ? Icons.view_list : Icons.view_kanban),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text('Capture it. Schedule it. RoshUP it.', style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 14),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search tasks, descriptions or tags',
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['All', 'Today', 'Upcoming', 'Overdue', 'Completed', 'Recurring', 'Favorites', 'Archived']
                .map(
                  (value) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(value),
                      selected: _filter == value,
                      onSelected: (_) => setState(() => _filter = value),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _sort,
          items: const ['Due date', 'Priority', 'Title', 'Duration']
              .map((value) => DropdownMenuItem(value: value, child: Text('Sort: $value')))
              .toList(),
          onChanged: (value) => setState(() => _sort = value ?? _sort),
        ),
        if (_selected.isNotEmpty) ...[
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            onPressed: _deleteSelected,
            icon: const Icon(Icons.delete_outline),
            label: Text('Delete ${_selected.length} selected'),
          ),
        ],
        const SizedBox(height: 12),
        if (tasks.isEmpty)
          _panel(
            Icons.inbox_outlined,
            'Nothing here yet',
            const Text('Tap New task and give your day a little RoshUP.'),
          )
        else if (_kanban)
          _kanbanView(tasks)
        else
          ...tasks.map(_taskCard),
      ],
    );
  }

  Widget _taskCard(Task task) {
    final accent = task.priority == 'Urgent' ? pink : cyan;
    final subtaskDone = task.subtasks.where((subtask) => subtask.completed).length;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: accent.withValues(alpha: 0.3)),
      ),
      child: ExpansionTile(
        leading: Checkbox(
          value: _selected.contains(task.id),
          onChanged: (_) {
            setState(() {
              if (_selected.contains(task.id)) {
                _selected.remove(task.id);
              } else {
                _selected.add(task.id);
              }
            });
          },
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            decoration: task.completed ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          '${task.priority} • ${task.category}${task.dueAt == null ? '' : ' • ${DateFormat('MMM d HH:mm').format(task.dueAt!)}'}',
          style: const TextStyle(color: Colors.white54),
        ),
        trailing: IconButton(
          onPressed: () => _toggle(task),
          icon: Icon(task.completed ? Icons.undo : Icons.done_all, color: accent),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task.description.isNotEmpty) Text(task.description),
                if (task.tags.isNotEmpty)
                  Wrap(
                    spacing: 4,
                    children: task.tags.map((tag) => Chip(label: Text(tag))).toList(),
                  ),
                const SizedBox(height: 8),
                Text('Subtasks $subtaskDone/${task.subtasks.length} • ${task.reminders.length} reminder${task.reminders.length == 1 ? '' : 's'}'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _editTask(source: task),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        _tasks.add(
                          Task(
                            id: _uuid.v4(),
                            title: '${task.title} copy',
                            description: task.description,
                            priority: task.priority,
                            category: task.category,
                            tags: [...task.tags],
                            dueAt: task.dueAt,
                            reminders: [...task.reminders],
                            recurring: task.recurring,
                            estimatedMinutes: task.estimatedMinutes,
                            subtasks: task.subtasks
                                .map((subtask) => Subtask(id: _uuid.v4(), title: subtask.title))
                                .toList(),
                          ),
                        );
                        await _saveTasks();
                        if (mounted) setState(() {});
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Duplicate'),
                    ),
                    IconButton(
                      onPressed: () async {
                        task.favorite = !task.favorite;
                        await _saveTasks();
                        if (mounted) setState(() {});
                      },
                      icon: Icon(
                        task.favorite ? Icons.star : Icons.star_border,
                        color: const Color(0xFFFBBF24),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kanbanView(List<Task> tasks) {
    final open = tasks.where((task) => !task.completed).toList();
    final done = tasks.where((task) => task.completed).toList();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _kanbanColumn('UP NEXT', open)),
        const SizedBox(width: 10),
        Expanded(child: _kanbanColumn('DONE', done)),
      ],
    );
  }

  Widget _kanbanColumn(String title, List<Task> tasks) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1119),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(letterSpacing: 1.4, color: Colors.white54, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ...tasks.map(
            (task) => Card(
              child: ListTile(
                dense: true,
                title: Text(task.title),
                onTap: () => _toggle(task),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _planPage() {
    final dated = _tasks.where((task) => task.dueAt != null || task.nextReminder != null).toList();
    dated.sort(
      (a, b) => (a.nextReminder ?? a.dueAt ?? DateTime.now())
          .compareTo(b.nextReminder ?? b.dueAt ?? DateTime.now()),
    );

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Plan', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        const Text('Deadlines and reminder rhythm', style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 16),
        if (dated.isEmpty)
          _panel(Icons.event_busy, 'Calendar is clear', const Text('Add a due date or alarm to see it here.'))
        else
          ...dated.map(
            (task) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.event, color: cyan),
                title: Text(task.title),
                subtitle: Text(
                  DateFormat('EEE, MMM d • HH:mm').format(task.nextReminder ?? task.dueAt!),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _statsPage(int done) {
    final completion = _tasks.isEmpty ? 0 : ((done / _tasks.length) * 100).round();
    final recurring = _tasks.where((task) => task.recurring != 'None').length;
    final subtasks = _tasks.fold<int>(0, (sum, task) => sum + task.subtasks.length);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Stats', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        const Text('Momentum, not clutter.', style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 16),
        _metric('Completion', '$completion%', Icons.insights),
        const SizedBox(height: 10),
        _metric('Open', '${_tasks.length - done}', Icons.pending_actions),
        const SizedBox(height: 10),
        _metric('Recurring', '$recurring', Icons.repeat),
        const SizedBox(height: 10),
        _metric('Subtasks', '$subtasks', Icons.account_tree),
      ],
    );
  }

  Widget _profilePage() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('RoshUP', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),
        _panel(
          Icons.bolt,
          'RoshUP identity',
          const Text('RoshUP is your fast, focused task workspace by Roshab Bhandari.'),
        ),
        _panel(
          Icons.notifications_active,
          'Phone reminders',
          const Text('One-time, daily and weekly task notifications keep your schedule moving.'),
        ),
        _panel(
          Icons.offline_bolt,
          'Offline first',
          const Text('Tasks stay on the device and remain available without internet.'),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text('Developed by Roshab Bhandari', style: TextStyle(color: Colors.white38)),
        ),
      ],
    );
  }

  Widget _panel(IconData icon, String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: cyan),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _metric(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: purple),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(color: Colors.white54)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
