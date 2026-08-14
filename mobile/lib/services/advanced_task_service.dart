import '../models/task.dart';

class AdvancedTaskService {
  static DateTime? nextRecurringDate(Task task, {DateTime? from}) {
    final base = task.dueAt ?? task.nextReminder;
    if (base == null || task.recurring == 'None') return null;
    final start = from ?? DateTime.now();
    var next = base;
    while (!next.isAfter(start)) {
      switch (task.recurring) {
        case 'Daily':
          next = next.add(const Duration(days: 1));
          break;
        case 'Weekly':
          next = next.add(const Duration(days: 7));
          break;
        case 'Monthly':
          final month = next.month == 12 ? 1 : next.month + 1;
          final year = next.month == 12 ? next.year + 1 : next.year;
          final day = next.day.clamp(1, DateTime(year, month + 1, 0).day);
          next = DateTime(year, month, day, next.hour, next.minute);
          break;
        case 'Weekdays':
          do {
            next = next.add(const Duration(days: 1));
          } while (next.weekday == DateTime.saturday || next.weekday == DateTime.sunday);
          break;
        default:
          return null;
      }
    }
    return next;
  }

  static List<Task> smartFilter(List<Task> tasks, String filter) {
    final now = DateTime.now();
    switch (filter) {
      case 'Today':
        return tasks.where((t) => _sameDay(t.dueAt, now) || _sameDay(t.nextReminder, now)).toList();
      case 'Upcoming':
        return tasks.where((t) => (t.dueAt?.isAfter(now) ?? false) || (t.nextReminder?.isAfter(now) ?? false)).toList();
      case 'Overdue':
        return tasks.where((t) => !t.completed && t.dueAt != null && t.dueAt!.isBefore(now)).toList();
      case 'Favorites':
        return tasks.where((t) => t.favorite && !t.archived).toList();
      case 'Archived':
        return tasks.where((t) => t.archived).toList();
      case 'Completed':
        return tasks.where((t) => t.completed).toList();
      case 'Recurring':
        return tasks.where((t) => t.recurring != 'None').toList();
      default:
        return tasks.where((t) => !t.archived).toList();
    }
  }

  static List<Task> sort(List<Task> tasks, String mode) {
    final copy = [...tasks];
    int priority(String p) => switch (p) {
          'Urgent' => 0,
          'High' => 1,
          'Medium' => 2,
          _ => 3,
        };
    copy.sort((a, b) {
      switch (mode) {
        case 'Priority':
          return priority(a.priority).compareTo(priority(b.priority));
        case 'Due date':
          return (a.dueAt ?? DateTime(9999)).compareTo(b.dueAt ?? DateTime(9999));
        case 'Title':
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case 'Duration':
          return a.estimatedMinutes.compareTo(b.estimatedMinutes);
        default:
          return a.completed == b.completed ? 0 : (a.completed ? 1 : -1);
      }
    });
    return copy;
  }

  static Task duplicate(Task source, String id) => Task(
        id: id,
        title: '${source.title} (copy)',
        description: source.description,
        priority: source.priority,
        category: source.category,
        tags: [...source.tags],
        dueAt: source.dueAt,
        startAt: source.startAt,
        reminders: [...source.reminders],
        recurring: source.recurring,
        estimatedMinutes: source.estimatedMinutes,
        favorite: source.favorite,
        subtasks: source.subtasks
            .map((s) => Subtask(id: '${s.id}-$id', title: s.title, completed: false))
            .toList(),
      );

  static Map<String, int> statistics(List<Task> tasks) {
    final now = DateTime.now();
    final completed = tasks.where((t) => t.completed).length;
    final overdue = tasks.where((t) => !t.completed && t.dueAt != null && t.dueAt!.isBefore(now)).length;
    final dueToday = tasks.where((t) => _sameDay(t.dueAt, now)).length;
    final recurring = tasks.where((t) => t.recurring != 'None').length;
    final subtasks = tasks.fold<int>(0, (sum, t) => sum + t.subtasks.length);
    final subtasksDone = tasks.fold<int>(0, (sum, t) => sum + t.subtasks.where((s) => s.completed).length);
    return {
      'total': tasks.length,
      'completed': completed,
      'open': tasks.length - completed,
      'overdue': overdue,
      'today': dueToday,
      'recurring': recurring,
      'subtasks': subtasks,
      'subtasksDone': subtasksDone,
    };
  }

  static bool _sameDay(DateTime? a, DateTime b) => a != null && a.year == b.year && a.month == b.month && a.day == b.day;
}