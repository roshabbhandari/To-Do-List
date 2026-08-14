import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class BackupService {
  Future<File> createTaskBackup(List<Task> tasks) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/roshab_tasks_backup.json');
    await file.writeAsString(jsonEncode(_payload(tasks)));
    return file;
  }

  Future<File> createAutomaticBackup(List<Task> tasks) async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/RoshabTasks/backups');
    if (!await dir.exists()) await dir.create(recursive: true);
    final name = 'backup_${DateFormat('yyyyMMdd').format(DateTime.now())}.json';
    final file = File('${dir.path}/$name');
    await file.writeAsString(jsonEncode(_payload(tasks)));
    final files = await dir.list().where((e) => e is File && e.path.endsWith('.json')).cast<File>().toList();
    files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    for (final old in files.skip(7)) {
      await old.delete();
    }
    return file;
  }

  Future<void> shareTaskBackup(List<Task> tasks) async {
    final file = await createTaskBackup(tasks);
    await Share.shareXFiles([XFile(file.path)], text: 'Roshab Tasks backup');
  }

  Map<String, dynamic> _payload(List<Task> tasks) => {
        'app': 'Roshab Tasks',
        'version': 2,
        'createdAt': DateTime.now().toIso8601String(),
        'tasks': tasks.map((t) => t.toJson()).toList(),
      };
}
