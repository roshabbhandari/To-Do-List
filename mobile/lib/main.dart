import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const RoshabTasksApp());
}

class RoshabTasksApp extends StatelessWidget {
  const RoshabTasksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Roshab Tasks',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF070B16),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5CF6),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<String> tasks = [];
  final TextEditingController controller = TextEditingController();
  int currentIndex = 0;
  int completed = 0;

  Future<void> addTask() async {
    final title = controller.text.trim();
    if (title.isEmpty) return;
    setState(() {
      tasks.add(title);
      controller.clear();
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('tasks', tasks);
  }

  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('tasks') ?? [];
    if (!mounted) return;
    setState(() => tasks
      ..clear()
      ..addAll(saved));
  }

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: currentIndex,
          children: [
            _dashboard(context),
            _tasksPage(context),
            _studentHub(context),
            _profilePage(context),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => setState(() => currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.checklist_outlined), selectedIcon: Icon(Icons.checklist), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: 'Student'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      floatingActionButton: currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => _showAddTask(context),
              icon: const Icon(Icons.add),
              label: const Text('Add task'),
            )
          : null,
    );
  }

  Widget _dashboard(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Good day 👋', style: TextStyle(color: Colors.white70, fontSize: 15)),
                  SizedBox(height: 4),
                  Text('Roshab Tasks', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Text('Plan. Focus. Finish.', style: TextStyle(color: Colors.white54)),
                ],
              ),
            ),
            CircleAvatar(
              radius: 27,
              backgroundColor: Color(0xFF1D1534),
              child: Icon(Icons.person, color: Color(0xFFC4B5FD)),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _heroCard(),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _statCard('Tasks', '${tasks.length}', Icons.task_alt)),
            const SizedBox(width: 12),
            Expanded(child: _statCard('Done', '$completed', Icons.check_circle_outline)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _quickCard('Pomodoro', Icons.timer_outlined, () => setState(() => currentIndex = 2))),
            const SizedBox(width: 12),
            Expanded(child: _quickCard('Alarm', Icons.alarm_outlined, () => _showReminderInfo(context))),
          ],
        ),
        const SizedBox(height: 22),
        const Text('Student tools', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        _toolTile(Icons.calculate_outlined, 'GPA Calculator', 'Track your grades quickly'),
        _toolTile(Icons.percent_outlined, 'Attendance', 'See your attendance percentage'),
        _toolTile(Icons.event_outlined, 'Exam Countdown', 'Never lose track of an exam'),
        _toolTile(Icons.calendar_month_outlined, 'Timetable', 'Keep classes in one place'),
      ],
    );
  }

  Widget _heroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF4C1D95), Color(0xFF1E1B4B)]),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Today\'s focus', style: TextStyle(color: Colors.white70)),
                SizedBox(height: 8),
                Text('Make progress on one important thing.', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700)),
                SizedBox(height: 12),
                Text('Your tasks, reminders and study tools stay together.', style: TextStyle(color: Colors.white60)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.auto_awesome, size: 34, color: Color(0xFFD8B4FE)),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white10)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: const Color(0xFFC4B5FD))),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white54)), const SizedBox(height: 3), Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))]),
        ],
      ),
    );
  }

  Widget _quickCard(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white10)),
        child: Row(children: [Icon(icon, color: const Color(0xFFA78BFA)), const SizedBox(width: 10), Text(title, style: const TextStyle(fontWeight: FontWeight.w700))]),
      ),
    );
  }

  Widget _toolTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white10)),
      child: Row(
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFF1D1534), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: const Color(0xFFC4B5FD))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12))])),
          const Icon(Icons.chevron_right, color: Colors.white38),
        ],
      ),
    );
  }

  Widget _tasksPage(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('My Tasks', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text('${tasks.length} saved tasks', style: const TextStyle(color: Colors.white54)),
        const SizedBox(height: 20),
        if (tasks.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white10)),
            child: const Column(children: [Icon(Icons.inbox_outlined, size: 54, color: Colors.white30), SizedBox(height: 12), Text('No tasks yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)), SizedBox(height: 6), Text('Tap Add task to create your first one.', style: TextStyle(color: Colors.white54))]),
          )
        else
          ...tasks.asMap().entries.map((entry) {
            final index = entry.key;
            final task = entry.value;
            return Dismissible(
              key: ValueKey('$task-$index'),
              background: Container(color: Colors.redAccent, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete)),
              direction: DismissDirection.endToStart,
              onDismissed: (_) async {
                setState(() => tasks.removeAt(index));
                final prefs = await SharedPreferences.getInstance();
                await prefs.setStringList('tasks', tasks);
              },
              child: Card(
                color: const Color(0xFF111827),
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Colors.white10)),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFF24183C), child: Icon(Icons.task_alt, color: Color(0xFFC4B5FD))),
                  title: Text(task),
                  subtitle: const Text('No reminder set', style: TextStyle(color: Colors.white54)),
                  trailing: IconButton(icon: const Icon(Icons.alarm_add_outlined), onPressed: () => _showReminderInfo(context)),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _studentHub(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Student Hub', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Tools for study, planning and focus.', style: TextStyle(color: Colors.white54)),
        const SizedBox(height: 22),
        _studentAction(context, Icons.timer_outlined, 'Pomodoro Focus', '25-minute focus sessions', () => _showPomodoro(context)),
        _studentAction(context, Icons.calculate_outlined, 'GPA Calculator', 'Calculate and save GPA', () => _showSimpleTool(context, 'GPA Calculator')),
        _studentAction(context, Icons.percent_outlined, 'Attendance', 'Track classes attended', () => _showSimpleTool(context, 'Attendance Calculator')),
        _studentAction(context, Icons.event_available_outlined, 'Exam Countdown', 'Plan around important dates', () => _showSimpleTool(context, 'Exam Countdown')),
        _studentAction(context, Icons.calendar_month_outlined, 'Timetable', 'Organize your weekly classes', () => _showSimpleTool(context, 'Weekly Timetable')),
        _studentAction(context, Icons.note_alt_outlined, 'Study Notes', 'Keep quick notes offline', () => _showSimpleTool(context, 'Study Notes')),
      ],
    );
  }

  Widget _studentAction(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      color: const Color(0xFF111827),
      margin: const EdgeInsets.only(bottom: 11),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white10)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(width: 46, height: 46, decoration: BoxDecoration(color: const Color(0xFF1D1534), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: const Color(0xFFC4B5FD))),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Padding(padding: const EdgeInsets.only(top: 3), child: Text(subtitle, style: const TextStyle(color: Colors.white54))),
        trailing: const Icon(Icons.chevron_right, color: Colors.white38),
        onTap: onTap,
      ),
    );
  }

  Widget _profilePage(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Profile', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(26), border: Border.all(color: Colors.white10)),
          child: const Column(children: [CircleAvatar(radius: 42, backgroundColor: Color(0xFF24183C), child: Icon(Icons.person, size: 44, color: Color(0xFFD8B4FE))), SizedBox(height: 12), Text('Roshab Tasks', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)), SizedBox(height: 4), Text('Developed by Roshab Bhandari', style: TextStyle(color: Colors.white54))]),
        ),
        const SizedBox(height: 16),
        _toolTile(Icons.notifications_active_outlined, 'Notifications', 'Phone reminders will be added in the mobile reminder module'),
        _toolTile(Icons.dark_mode_outlined, 'Dark theme', 'Enabled by default for a focused UI'),
        _toolTile(Icons.offline_bolt_outlined, 'Offline first', 'Tasks are kept locally on the device'),
      ],
    );
  }

  Future<void> _showAddTask(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111827),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('New task', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'Task title', border: OutlineInputBorder(), prefixIcon: Icon(Icons.task_alt))),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: FilledButton.icon(onPressed: () { addTask(); Navigator.pop(context); }, icon: const Icon(Icons.add), label: const Text('Save task'))), const SizedBox(width: 10), OutlinedButton.icon(onPressed: () { Navigator.pop(context); _showReminderInfo(context); }, icon: const Icon(Icons.alarm_add), label: const Text('Reminder'))]),
        ]),
      ),
    );
  }

  void _showReminderInfo(BuildContext context) {
    showDialog<void>(context: context, builder: (_) => AlertDialog(title: const Text('Phone reminders'), content: const Text('The mobile reminder module is designed for scheduled notifications and alarms. This starter build keeps the task UI and storage ready for the notification package.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))]));
  }

  void _showPomodoro(BuildContext context) {
    int seconds = 25 * 60;
    showDialog<void>(context: context, builder: (_) => StatefulBuilder(builder: (context, setState) { final mins = (seconds ~/ 60).toString().padLeft(2, '0'); final secs = (seconds % 60).toString().padLeft(2, '0'); return AlertDialog(title: const Text('Pomodoro Focus'), content: Column(mainAxisSize: MainAxisSize.min, children: [Text('$mins:$secs', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900)), const SizedBox(height: 12), FilledButton(onPressed: () { if (seconds > 0) setState(() => seconds--); }, child: const Text('Focus tick'))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]); }));
  }

  void _showSimpleTool(BuildContext context, String title) {
    showDialog<void>(context: context, builder: (_) => AlertDialog(title: Text(title), content: Text('$title is part of the Student Hub and is ready for the next feature module.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]));
  }
}
