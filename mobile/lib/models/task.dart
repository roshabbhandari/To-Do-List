class Task {
  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.completed = false,
    this.priority = 'Medium',
    this.category = 'Study',
    this.tags = const [],
    this.dueAt,
    this.startAt,
    this.reminders = const [],
    this.recurring = 'None',
    this.estimatedMinutes = 0,
    this.favorite = false,
    this.archived = false,
    this.subtasks = const [],
  });

  final String id;
  String title;
  String description;
  bool completed;
  String priority;
  String category;
  List<String> tags;
  DateTime? dueAt;
  DateTime? startAt;
  List<DateTime> reminders;
  String recurring;
  int estimatedMinutes;
  bool favorite;
  bool archived;
  List<Subtask> subtasks;

  DateTime? get nextReminder => reminders.where((r) => r.isAfter(DateTime.now())).fold<DateTime?>(null, (best, r) => best == null || r.isBefore(best) ? r : best);

  double get progress {
    if (subtasks.isEmpty) return completed ? 1 : 0;
    return subtasks.where((s) => s.completed).length / subtasks.length;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'completed': completed,
        'priority': priority,
        'category': category,
        'tags': tags,
        'dueAt': dueAt?.toIso8601String(),
        'startAt': startAt?.toIso8601String(),
        'reminders': reminders.map((r) => r.toIso8601String()).toList(),
        'recurring': recurring,
        'estimatedMinutes': estimatedMinutes,
        'favorite': favorite,
        'archived': archived,
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        completed: json['completed'] as bool? ?? false,
        priority: json['priority'] as String? ?? 'Medium',
        category: json['category'] as String? ?? 'Study',
        tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        dueAt: json['dueAt'] == null ? null : DateTime.tryParse(json['dueAt'] as String),
        startAt: json['startAt'] == null ? null : DateTime.tryParse(json['startAt'] as String),
        reminders: (json['reminders'] as List?)?.map((e) => DateTime.tryParse(e.toString())).whereType<DateTime>().toList() ?? const [],
        recurring: json['recurring'] as String? ?? 'None',
        estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 0,
        favorite: json['favorite'] as bool? ?? false,
        archived: json['archived'] as bool? ?? false,
        subtasks: (json['subtasks'] as List?)
                ?.map((e) => Subtask.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
      );
}

class Subtask {
  Subtask({required this.id, required this.title, this.completed = false});

  final String id;
  String title;
  bool completed;

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'completed': completed};

  factory Subtask.fromJson(Map<String, dynamic> json) => Subtask(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        completed: json['completed'] as bool? ?? false,
      );
}