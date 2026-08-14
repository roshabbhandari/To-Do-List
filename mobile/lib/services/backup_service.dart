import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/task.dart';

class BackupService {
  Future<File> createTaskBackup(List<Task> tasks) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/roshab_tasks_backup.json');
    await file.writeAsString(jsonEncode({
      'app': 'Roshab Tasks',
      'version': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'tasks': tasks.map((t) => t.toJson()).toList(),
    }));
    return file;
  }

  Future<void> shareTaskBackup(List<Task> tasks) async {
    final file = await createTaskBackup(tasks);
    await Share.shareXFiles([XFile(file.path)], text: 'Roshab Tasks backup');
  }
}
