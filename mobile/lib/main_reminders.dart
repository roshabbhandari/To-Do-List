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
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8B5CF6), brightness: Brightness.dark),
          scaffoldBackgroundColor: const Color(0xFF070B16),
        ),
        home: const AdvancedTodoHome(),
      );
}

// The advanced task manager implementation continues below; this commit only fixes
// its imports so JSON persistence and SharedPreferences storage compile correctly.