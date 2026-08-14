class Task {
  Task({
    required this.id,
    required this.title,
    this.completed = false,
    this.priority = 'Medium',
    this.category = 'Study',
    this.dueAt,
    this.reminderAt,
    this.recurring = 'None',
  });

  final String id;
  String title;
  bool completed;
  String priority;
  String category;
  DateTime? dueAt;
  DateTime? reminderAt;
  String recurring;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'completed': completed,
        'priority': priority,
        'category': category,
        'dueAt': dueAt?.toIso8601String(),
        'reminderAt': reminderAt?.toIso8601String(),
        'recurring': recurring,
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        completed: json['completed'] as bool? ?? false,
        priority: json['priority'] as String? ?? 'Medium',
        category: json['category'] as String? ?? 'Study',
        dueAt: json['dueAt'] == null ? null : DateTime.tryParse(json['dueAt'] as String),
        reminderAt: json['reminderAt'] == null ? null : DateTime.tryParse(json['reminderAt'] as String),
        recurring: json['recurring'] as String? ?? 'None',
      );
}
