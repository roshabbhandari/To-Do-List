import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../services/backup_service.dart';
import '../services/notification_service.dart';
import '../services/student_tools.dart';
import '../services/task_store.dart';

class ReleaseApp extends StatefulWidget {
  const ReleaseApp({super.key});
  @override
  State<ReleaseApp> createState() => _ReleaseAppState();
}

class _ReleaseAppState extends State<ReleaseApp> {
  final store = TaskStore();
  final backup = BackupService();
  List<Task> tasks = [];
  int tab = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await NotificationService.instance.init();
    final saved = await store.load();
    if (!mounted) return;
    setState(() { tasks = saved; loading = false; });
  }

  Future<void> _save() => store.save(tasks);

  Future<void> _addTask() async {
    final title = TextEditingController();
    DateTime? reminder;
    String recurring = 'None';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111827),
      builder: (_) => StatefulBuilder(builder: (context, setSheet) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('New task', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            TextField(controller: title, autofocus: true, decoration: const InputDecoration(labelText: 'Task title', prefixIcon: Icon(Icons.task_alt), border: OutlineInputBorder())),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: FilledButton.icon(
                onPressed: () async {
                  final value = title.text.trim();
                  if (value.isEmpty) return;
                  final task = Task(id: DateTime.now().microsecondsSinceEpoch.toString(), title: value, reminderAt: reminder, recurring: recurring);
                  tasks.add(task);
                  await _save();
                  if (reminder != null) await NotificationService.instance.schedule(id: task.id.hashCode, title: value, body: 'Roshab Tasks reminder', when: reminder!, recurring: recurring);
                  if (context.mounted) Navigator.pop(context);
                  setState(() {});
                },
                icon: const Icon(Icons.add), label: const Text('Save task'))),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 3650)), initialDate: DateTime.now());
                  if (picked == null || !context.mounted) return;
                  final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (time == null) return;
                  reminder = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
                  setSheet(() {});
                },
                icon: const Icon(Icons.alarm_add_outlined), label: Text(reminder == null ? 'Alarm' : DateFormat('MMM d, HH:mm').format(reminder!))),
            ]),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(value: recurring, decoration: const InputDecoration(labelText: 'Repeat', border: OutlineInputBorder()), items: const ['None','Daily','Weekly'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (value) => setSheet(() => recurring = value ?? 'None')),
          ]),
        );
      }),
    );
  }

  Future<void> _toggle(Task task) async {
    task.completed = !task.completed;
    if (task.completed) await NotificationService.instance.cancel(task.id.hashCode);
    await _save();
    setState(() {});
  }

  Future<void> _delete(Task task) async {
    tasks.removeWhere((t) => t.id == task.id);
    await NotificationService.instance.cancel(task.id.hashCode);
    await _save();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Roshab Tasks',
      theme: ThemeData(useMaterial3: true, brightness: Brightness.dark, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8B5CF6), brightness: Brightness.dark), scaffoldBackgroundColor: const Color(0xFF070B16)),
      home: loading ? const Scaffold(body: Center(child: CircularProgressIndicator())) : _shell(),
    );
  }

  Widget _shell() {
    final pages = [_home(), _tasks(), _student(), _calendar(), _analytics(), _profile()];
    return Scaffold(
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (i) => setState(() => tab = i), destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.checklist_outlined), selectedIcon: Icon(Icons.checklist), label: 'Tasks'),
        NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: 'Student'),
        NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Calendar'),
        NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Stats'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
      ]),
      floatingActionButton: tab == 1 ? FloatingActionButton.extended(onPressed: _addTask, icon: const Icon(Icons.add), label: const Text('Task')) : null,
    );
  }

  Widget _home() => ListView(padding: const EdgeInsets.all(20), children: [
    const Text('Good day 👋', style: TextStyle(color: Colors.white70)),
    const SizedBox(height: 4), const Text('Roshab Tasks', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
    const SizedBox(height: 4), const Text('Plan. Focus. Finish.', style: TextStyle(color: Colors.white54)),
    const SizedBox(height: 20), _hero(), const SizedBox(height: 14),
    Row(children: [Expanded(child: _metric('Tasks', '${tasks.length}', Icons.task_alt)), const SizedBox(width: 12), Expanded(child: _metric('Done', '${tasks.where((t) => t.completed).length}', Icons.check_circle_outline))]),
    const SizedBox(height: 14), Row(children: [Expanded(child: _action('Student Hub', Icons.school, () => setState(() => tab = 2))), const SizedBox(width: 12), Expanded(child: _action('Calendar', Icons.calendar_month, () => setState(() => tab = 3)))]),
  ]);

  Widget _hero() => Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF4C1D95), Color(0xFF1E1B4B)]), borderRadius: BorderRadius.circular(28)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Today's focus", style: TextStyle(color: Colors.white70)), SizedBox(height: 8), Text('Stay focused on what matters.', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)), SizedBox(height: 8), Text('Tasks, alarms, study tools and progress in one place.', style: TextStyle(color: Colors.white60))]));

  Widget _metric(String title, String value, IconData icon) => Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white10)), child: Row(children: [Icon(icon, color: const Color(0xFFC4B5FD)), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white54)), Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900))])]));
  Widget _action(String title, IconData icon, VoidCallback onTap) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(22), child: Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white10)), child: Row(children: [Icon(icon, color: const Color(0xFFA78BFA)), const SizedBox(width: 10), Text(title, style: const TextStyle(fontWeight: FontWeight.w700))])));

  Widget _tasks() => ListView(padding: const EdgeInsets.all(20), children: [const Text('My Tasks', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)), const SizedBox(height: 12), if (tasks.isEmpty) _empty('No tasks yet', 'Add your first task and optionally schedule an alarm.') else ...tasks.map((task) => Dismissible(key: ValueKey(task.id), direction: DismissDirection.endToStart, onDismissed: (_) => _delete(task), background: Container(color: Colors.redAccent, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete)), child: Card(color: const Color(0xFF111827), margin: const EdgeInsets.only(bottom: 10), child: ListTile(leading: Checkbox(value: task.completed, onChanged: (_) => _toggle(task)), title: Text(task.title, style: TextStyle(decoration: task.completed ? TextDecoration.lineThrough : null)), subtitle: Text(task.reminderAt == null ? '${task.priority} • ${task.category}' : '${DateFormat('MMM d, HH:mm').format(task.reminderAt!)} • ${task.recurring}', style: const TextStyle(color: Colors.white54)), trailing: Icon(task.reminderAt == null ? Icons.alarm_add_outlined : Icons.alarm_on, color: const Color(0xFFC4B5FD)))))]);

  Widget _calendar() => ListView(padding: const EdgeInsets.all(20), children: [const Text('Calendar', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)), const SizedBox(height: 8), const Text('Upcoming tasks and reminders', style: TextStyle(color: Colors.white54)), const SizedBox(height: 16), ..._calendarGroups()]);
  List<Widget> _calendarGroups() {
    final scheduled = tasks.where((t) => t.dueAt != null || t.reminderAt != null).toList()..sort((a,b) => (a.reminderAt ?? a.dueAt ?? DateTime.now()).compareTo(b.reminderAt ?? b.dueAt ?? DateTime.now()));
    if (scheduled.isEmpty) return [_empty('Calendar is clear', 'Tasks with dates and alarms will appear here.')];
    return scheduled.map((t) => Card(color: const Color(0xFF111827), child: ListTile(leading: const Icon(Icons.event, color: Color(0xFFC4B5FD)), title: Text(t.title), subtitle: Text(t.reminderAt == null ? DateFormat('EEE, MMM d • due').format(t.dueAt!) : DateFormat('EEE, MMM d • HH:mm').format(t.reminderAt!)))).toList();
  }

  Widget _student() => ListView(padding: const EdgeInsets.all(20), children: [const Text('Student Hub', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)), const SizedBox(height: 8), const Text('Tools for grades, attendance, exams, notes and classes.', style: TextStyle(color: Colors.white54)), const SizedBox(height: 18), _gpaCard(), _attendanceCard(), _examCard(), _notesCard(), _timetableCard()]);

  Widget _gpaCard() { final grade = TextEditingController(); final credit = TextEditingController(); double result = 0; return StatefulBuilder(builder: (context,setCard) => _panel('GPA Calculator', Icons.calculate, Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Row(children: [Expanded(child: TextField(controller: grade, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Grade points', border: OutlineInputBorder()))), const SizedBox(width: 8), Expanded(child: TextField(controller: credit, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Credits', border: OutlineInputBorder())))]), const SizedBox(height: 10), FilledButton(onPressed: () { final g = double.tryParse(grade.text) ?? 0; final c = double.tryParse(credit.text) ?? 0; setCard(() => result = StudentTools.gpa([g], [c])); }, child: const Text('Calculate')), if (result > 0) Padding(padding: const EdgeInsets.only(top: 10), child: Text('GPA: ${result.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)))])));
  }
  Widget _attendanceCard() { final a=TextEditingController(); final t=TextEditingController(); double result=0; return StatefulBuilder(builder:(context,setCard)=>_panel('Attendance',Icons.percent,Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Row(children:[Expanded(child:TextField(controller:a,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Attended',border:OutlineInputBorder()))),const SizedBox(width:8),Expanded(child:TextField(controller:t,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Total',border:OutlineInputBorder()))) ]),const SizedBox(height:10),FilledButton(onPressed:(){setCard(()=>result=StudentTools.attendance(int.tryParse(a.text)??0,int.tryParse(t.text)??0));},child:const Text('Calculate')),if(result>0)Padding(padding:const EdgeInsets.only(top:10),child:Text('${result.toStringAsFixed(1)}% attendance',style:const TextStyle(fontSize:20,fontWeight:FontWeight.w700)))])));
  }
  Widget _examCard(){final date=DateTime.now().add(const Duration(days:7));return _panel('Exam Countdown',Icons.event_available,Text('${StudentTools.countdown(date).inDays} days until your demo exam',style:const TextStyle(fontSize:20,fontWeight:FontWeight.w700)));}
  Widget _notesCard(){final note=TextEditingController();return _panel('Study Notes',Icons.note_alt,Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[TextField(controller:note,maxLines:4,decoration:const InputDecoration(hintText:'Write a quick note...',border:OutlineInputBorder())),const SizedBox(height:8),FilledButton(onPressed:() async {final prefs=await __prefs();await prefs.setString('latest_note',note.text);},child:const Text('Save note'))]));}
  Widget _timetableCard()=>_panel('Weekly Timetable',Icons.calendar_month,const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Mon  •  Mathematics  •  10:00',style:TextStyle(fontWeight:FontWeight.w700)),SizedBox(height:8),Text('Tue  •  Programming  •  11:00'),SizedBox(height:8),Text('Wed  •  Physics  •  09:00'),SizedBox(height:8),Text('Thu  •  Database  •  12:00'),SizedBox(height:8),Text('Fri  •  Project  •  10:30')]));
  Future<dynamic> __prefs()=>__getPrefs();
  Future<dynamic> __getPrefs() async { return await (await _prefsInstance()); }
  Future<dynamic> _prefsInstance() async { return await SharedPreferences.getInstance(); }

  Widget _analytics() { final completed=tasks.where((t)=>t.completed).length; final pending=tasks.length-completed; return ListView(padding:const EdgeInsets.all(20),children:[const Text('Productivity',style:TextStyle(fontSize:30,fontWeight:FontWeight.w900)),const SizedBox(height:8),const Text('Your task completion at a glance.',style:TextStyle(color:Colors.white54)),const SizedBox(height:18),Container(height:260,padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:const Color(0xFF111827),borderRadius:BorderRadius.circular(24)),child:PieChart(PieChartData(centerSpaceRadius:50,sections:[PieChartSectionData(value:(completed==0?1:completed).toDouble(),title:'Done',radius:70,color:const Color(0xFF22C55E)),PieChartSectionData(value:(pending==0?1:pending).toDouble(),title:'Open',radius:70,color:const Color(0xFF7C3AED))]))),const SizedBox(height:16),_metric('Completion',tasks.isEmpty?'0%':'${(completed/tasks.length*100).round()}%',Icons.insights)]); }

  Widget _profile() => ListView(padding:const EdgeInsets.all(20),children:[const Text('Profile',style:TextStyle(fontSize:30,fontWeight:FontWeight.w900)),const SizedBox(height:18),_panel('Roshab Tasks',Icons.person,const Column(children:[CircleAvatar(radius:38,backgroundColor:Color(0xFF24183C),child:Icon(Icons.person,size:40,color:Color(0xFFD8B4FE))),SizedBox(height:10),Text('Developed by Roshab Bhandari',style:TextStyle(color:Colors.white54))])),const SizedBox(height:12),FilledButton.icon(onPressed:()=>backup.shareTaskBackup(tasks),icon:const Icon(Icons.backup_outlined),label:const Text('Create & share backup')),const SizedBox(height:8),OutlinedButton.icon(onPressed:()=>showDialog(context:context,builder:(_)=>AlertDialog(title:const Text('Cloud Sync'),content:const Text('Cloud sync is ready for a private HTTPS/Firebase backend. Add your credentials/secrets in the release environment before enabling remote storage.'),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('OK'))])),icon:const Icon(Icons.cloud_sync_outlined),label:const Text('Cloud sync settings'))]);

  Widget _panel(String title, IconData icon, Widget child)=>Container(margin:const EdgeInsets.only(bottom:12),padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:const Color(0xFF111827),borderRadius:BorderRadius.circular(22),border:Border.all(color:Colors.white10)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Icon(icon,color:const Color(0xFFC4B5FD)),const SizedBox(width:10),Text(title,style:const TextStyle(fontSize:19,fontWeight:FontWeight.w800))]),const SizedBox(height:14),child]));
  Widget _empty(String title,String subtitle)=>Container(padding:const EdgeInsets.all(28),decoration:BoxDecoration(color:const Color(0xFF111827),borderRadius:BorderRadius.circular(24),border:Border.all(color:Colors.white10)),child:Column(children:[const Icon(Icons.inbox_outlined,size:48,color:Colors.white30),const SizedBox(height:10),Text(title,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w800)),const SizedBox(height:4),Text(subtitle,textAlign:TextAlign.center,style:const TextStyle(color:Colors.white54))]));
}
