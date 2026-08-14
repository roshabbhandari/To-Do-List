import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/task.dart';
import 'services/backup_service.dart';
import 'services/notification_service.dart';
import 'services/student_tools.dart';
import 'services/task_store.dart';

void main() => runApp(const RoshabTasksMobile());

class RoshabTasksMobile extends StatefulWidget {
  const RoshabTasksMobile({super.key});
  @override
  State<RoshabTasksMobile> createState() => _RoshabTasksMobileState();
}

class _RoshabTasksMobileState extends State<RoshabTasksMobile> {
  final store = TaskStore();
  final backup = BackupService();
  final tasks = <Task>[];
  int tab = 0;
  bool ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await NotificationService.instance.init();
    tasks.addAll(await store.load());
    await backup.createAutomaticBackup(tasks);
    if (mounted) setState(() => ready = true);
  }

  Future<void> _persist() => store.save(tasks);

  Future<void> _addTask() async {
    final title = TextEditingController();
    DateTime? reminder;
    String repeat = 'None';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111827),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Create task', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            TextField(controller: title, autofocus: true, decoration: const InputDecoration(labelText: 'Task title', border: OutlineInputBorder(), prefixIcon: Icon(Icons.task_alt))),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 3650)), initialDate: DateTime.now());
                  if (date == null || !context.mounted) return;
                  final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (time == null) return;
                  setSheet(() => reminder = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                },
                icon: const Icon(Icons.alarm_add_outlined),
                label: Text(reminder == null ? 'Set alarm' : DateFormat('MMM d, HH:mm').format(reminder!)),
              )),
              const SizedBox(width: 8),
              Expanded(child: DropdownButtonFormField<String>(value: repeat, decoration: const InputDecoration(labelText: 'Repeat', border: OutlineInputBorder()), items: const ['None', 'Daily', 'Weekly'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setSheet(() => repeat = v ?? 'None'))),
            ]),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: () async {
              final value = title.text.trim();
              if (value.isEmpty) return;
              final task = Task(id: DateTime.now().microsecondsSinceEpoch.toString(), title: value, reminderAt: reminder, recurring: repeat);
              tasks.add(task);
              await _persist();
              await backup.createAutomaticBackup(tasks);
              if (reminder != null) await NotificationService.instance.schedule(id: task.id.hashCode, title: value, body: 'Roshab Tasks reminder', when: reminder!, recurring: repeat);
              if (sheetContext.mounted) Navigator.pop(sheetContext);
              if (mounted) setState(() {});
            }, icon: const Icon(Icons.save), label: const Text('Save task')),
          ]),
        ),
      ),
    );
  }

  Future<void> _toggle(Task task) async {
    task.completed = !task.completed;
    if (task.completed) await NotificationService.instance.cancel(task.id.hashCode);
    await _persist();
    await backup.createAutomaticBackup(tasks);
    setState(() {});
  }

  Future<void> _delete(Task task) async {
    tasks.removeWhere((t) => t.id == task.id);
    await NotificationService.instance.cancel(task.id.hashCode);
    await _persist();
    await backup.createAutomaticBackup(tasks);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Roshab Tasks',
      theme: ThemeData(brightness: Brightness.dark, useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8B5CF6), brightness: Brightness.dark), scaffoldBackgroundColor: const Color(0xFF070B16)),
      home: ready ? _home() : const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }

  Widget _home() {
    final pages = [_dashboard(), _taskPage(), _studentPage(), _calendarPage(), _statsPage(), _profilePage()];
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

  Widget _dashboard() {
    final completed = tasks.where((t) => t.completed).length;
    return ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Good day 👋', style: TextStyle(color: Colors.white70)),
      const SizedBox(height: 4), const Text('Roshab Tasks', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
      const SizedBox(height: 4), const Text('Plan. Focus. Finish.', style: TextStyle(color: Colors.white54)),
      const SizedBox(height: 20),
      _panel(Icons.auto_awesome, 'Today\'s focus', const Text('Keep your most important task visible and use an alarm when you need a nudge.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
      Row(children: [Expanded(child: _metric('Tasks', '${tasks.length}', Icons.task_alt)), const SizedBox(width: 10), Expanded(child: _metric('Done', '$completed', Icons.check_circle_outline))]),
      const SizedBox(height: 10),
      Row(children: [Expanded(child: _action('Student Hub', Icons.school, () => setState(() => tab = 2))), const SizedBox(width: 10), Expanded(child: _action('Calendar', Icons.calendar_month, () => setState(() => tab = 3)))]),
    ]);
  }

  Widget _taskPage() => ListView(padding: const EdgeInsets.all(20), children: [
    const Text('My Tasks', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
    const SizedBox(height: 10),
    if (tasks.isEmpty) _empty('No tasks yet', 'Create a task and set an alarm or recurring reminder.')
    else ...tasks.map((task) => Dismissible(key: ValueKey(task.id), direction: DismissDirection.endToStart, onDismissed: (_) => _delete(task), background: Container(color: Colors.redAccent, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete)), child: Card(color: const Color(0xFF111827), margin: const EdgeInsets.only(bottom: 10), child: ListTile(leading: Checkbox(value: task.completed, onChanged: (_) => _toggle(task)), title: Text(task.title, style: TextStyle(decoration: task.completed ? TextDecoration.lineThrough : null, fontWeight: FontWeight.w700)), subtitle: Text(task.reminderAt == null ? '${task.priority} • ${task.category}' : '${DateFormat('MMM d, HH:mm').format(task.reminderAt!)} • ${task.recurring}', style: const TextStyle(color: Colors.white54)), trailing: Icon(task.reminderAt == null ? Icons.alarm_add_outlined : Icons.alarm_on, color: const Color(0xFFC4B5FD))))))
  ]);

  Widget _calendarPage() {
    final dated = tasks.where((t) => t.dueAt != null || t.reminderAt != null).toList()..sort((a,b) => (a.reminderAt ?? a.dueAt ?? DateTime.now()).compareTo(b.reminderAt ?? b.dueAt ?? DateTime.now()));
    return ListView(padding: const EdgeInsets.all(20), children: [const Text('Calendar', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)), const SizedBox(height: 6), const Text('Deadlines and reminders', style: TextStyle(color: Colors.white54)), const SizedBox(height: 16), if (dated.isEmpty) _empty('Calendar is clear', 'Tasks with dates will appear here.') else ...dated.map((t) => Card(color: const Color(0xFF111827), child: ListTile(leading: const Icon(Icons.event, color: Color(0xFFC4B5FD)), title: Text(t.title), subtitle: Text(t.reminderAt == null ? DateFormat('EEE, MMM d').format(t.dueAt!) : DateFormat('EEE, MMM d • HH:mm').format(t.reminderAt!))))]);
  }

  Widget _studentPage() => ListView(padding: const EdgeInsets.all(20), children: [
    const Text('Student Hub', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
    const SizedBox(height: 6), const Text('Study tools, exams, grades, attendance and notes.', style: TextStyle(color: Colors.white54)), const SizedBox(height: 16),
    _calculatorCard('GPA Calculator', Icons.calculate, 'Grade points', (value) => StudentTools.gpa([value], [1])),
    _attendanceCard(), _examCard(), _notesCard(), _timetableCard(), _backupCard(),
  ]);

  Widget _calculatorCard(String title, IconData icon, String label, double Function(double) calc) { final c = TextEditingController(); double result = 0; return StatefulBuilder(builder: (context,setCard)=>_panel(icon,title,Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[TextField(controller:c,keyboardType:TextInputType.number,decoration:InputDecoration(labelText:label,border:const OutlineInputBorder())),const SizedBox(height:8),FilledButton(onPressed:(){setCard(()=>result=calc(double.tryParse(c.text)??0));},child:const Text('Calculate')),if(result>0)Padding(padding:const EdgeInsets.only(top:8),child:Text(result.toStringAsFixed(2),style:const TextStyle(fontSize:22,fontWeight:FontWeight.w900)))]))); }
  Widget _attendanceCard(){final a=TextEditingController();final t=TextEditingController();double value=0;return StatefulBuilder(builder:(context,setCard)=>_panel(Icons.percent,'Attendance',Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Row(children:[Expanded(child:TextField(controller:a,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Attended',border:OutlineInputBorder()))),const SizedBox(width:8),Expanded(child:TextField(controller:t,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Total',border:OutlineInputBorder())))]),const SizedBox(height:8),FilledButton(onPressed:(){setCard(()=>value=StudentTools.attendance(int.tryParse(a.text)??0,int.tryParse(t.text)??0));},child:const Text('Calculate')),if(value>0)Padding(padding:const EdgeInsets.only(top:8),child:Text('${value.toStringAsFixed(1)}%',style:const TextStyle(fontSize:22,fontWeight:FontWeight.w900)))])));}
  Widget _examCard()=>_panel(Icons.event_available,'Exam Countdown',Text('${StudentTools.countdown(DateTime.now().add(const Duration(days:7))).inDays} days to your sample exam',style:const TextStyle(fontSize:19,fontWeight:FontWeight.w800)));
  Widget _notesCard(){final c=TextEditingController();return _panel(Icons.note_alt,'Study Notes',Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[TextField(controller:c,maxLines:4,decoration:const InputDecoration(hintText:'Write a note...',border:OutlineInputBorder())),const SizedBox(height:8),FilledButton(onPressed:()async{final p=await SharedPreferences.getInstance();await p.setString('latest_note',c.text);if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Note saved locally')));},child:const Text('Save note'))]));}
  Widget _timetableCard()=>_panel(Icons.calendar_month,'Weekly Timetable',const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Mon • Mathematics • 10:00',style:TextStyle(fontWeight:FontWeight.w700)),SizedBox(height:7),Text('Tue • Programming • 11:00'),SizedBox(height:7),Text('Wed • Physics • 09:00'),SizedBox(height:7),Text('Thu • Database • 12:00'),SizedBox(height:7),Text('Fri • Project • 10:30')]));
  Widget _backupCard()=>_panel(Icons.backup_outlined,'Backup',FilledButton.icon(onPressed:()=>backup.shareTaskBackup(tasks),icon:const Icon(Icons.ios_share),label:const Text('Create and share backup'));

  Widget _statsPage(){final done=tasks.where((t)=>t.completed).length;final open=tasks.length-done;return ListView(padding:const EdgeInsets.all(20),children:[const Text('Productivity',style:TextStyle(fontSize:30,fontWeight:FontWeight.w900)),const SizedBox(height:8),const Text('Task completion overview',style:TextStyle(color:Colors.white54)),const SizedBox(height:18),Container(height:270,padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:const Color(0xFF111827),borderRadius:BorderRadius.circular(24)),child:PieChart(PieChartData(centerSpaceRadius:52,sections:[PieChartSectionData(value:(done==0?1:done).toDouble(),title:'Done',radius:78,color:const Color(0xFF22C55E)),PieChartSectionData(value:(open==0?1:open).toDouble(),title:'Open',radius:78,color:const Color(0xFF7C3AED))]))),const SizedBox(height:12),_metric('Completion',tasks.isEmpty?'0%':'${(done/tasks.length*100).round()}%',Icons.insights)]);}

  Widget _profilePage()=>ListView(padding:const EdgeInsets.all(20),children:[const Text('Roshab Tasks',style:TextStyle(fontSize:30,fontWeight:FontWeight.w900)),const SizedBox(height:18),_panel(Icons.person,'Developer',const Column(children:[CircleAvatar(radius:40,backgroundColor:Color(0xFF24183C),child:Icon(Icons.person,size:42,color:Color(0xFFD8B4FE))),SizedBox(height:10),Text('Developed by Roshab Bhandari',style:TextStyle(color:Colors.white54))])),const SizedBox(height:10),_panel(Icons.notifications_active,'Phone notifications',const Text('Scheduled alarms, daily reminders and weekly reminders are supported on the mobile release.')),const SizedBox(height:10),_panel(Icons.cloud_sync_outlined,'Cloud sync',const Text('JWT account and task-sync API is included in sync-server. Configure the server URL and credentials before enabling remote sync.'))]);

  Widget _panel(IconData icon,String title,Widget child)=>Container(margin:const EdgeInsets.only(bottom:12),padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:const Color(0xFF111827),borderRadius:BorderRadius.circular(22),border:Border.all(color:Colors.white10)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Icon(icon,color:const Color(0xFFC4B5FD)),const SizedBox(width:10),Text(title,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w800))]),const SizedBox(height:12),child]));
  Widget _metric(String title,String value,IconData icon)=>Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:const Color(0xFF111827),borderRadius:BorderRadius.circular(20),border:Border.all(color:Colors.white10)),child:Row(children:[Icon(icon,color:const Color(0xFFC4B5FD)),const SizedBox(width:10),Text('$title: ',style:const TextStyle(color:Colors.white54)),Text(value,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:20))]));
  Widget _action(String title,IconData icon,VoidCallback tap)=>InkWell(onTap:tap,borderRadius:BorderRadius.circular(20),child:Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:const Color(0xFF111827),borderRadius:BorderRadius.circular(20),border:Border.all(color:Colors.white10)),child:Row(children:[Icon(icon,color:const Color(0xFFC4B5FD)),const SizedBox(width:10),Text(title,style:const TextStyle(fontWeight:FontWeight.w800))])));
  Widget _empty(String title,String subtitle)=>_panel(Icons.inbox_outlined,title,Text(subtitle,style:const TextStyle(color:Colors.white54)));
}
