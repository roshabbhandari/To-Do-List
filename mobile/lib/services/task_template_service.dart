import 'package:uuid/uuid.dart';
import '../models/task.dart';

class TaskTemplateService {
  static const uuid = Uuid();

  static List<Task> templates() => [
        Task(
          id: uuid.v4(),
          title: 'Study session',
          description: 'Plan a focused study block with clear subtasks.',
          category: 'Study',
          priority: 'High',
          estimatedMinutes: 50,
          tags: const ['study', 'focus'],
          subtasks: [
            Subtask(id: uuid.v4(), title: 'Choose topic'),
            Subtask(id: uuid.v4(), title: 'Prepare materials'),
            Subtask(id: uuid.v4(), title: 'Complete focus session'),
          ],
        ),
        Task(
          id: uuid.v4(),
          title: 'Project task',
          description: 'Break a project task into small deliverables.',
          category: 'Project',
          priority: 'Urgent',
          estimatedMinutes: 90,
          tags: const ['project'],
          subtasks: [
            Subtask(id: uuid.v4(), title: 'Define outcome'),
            Subtask(id: uuid.v4(), title: 'Implement'),
            Subtask(id: uuid.v4(), title: 'Test'),
            Subtask(id: uuid.v4(), title: 'Review'),
          ],
        ),
        Task(
          id: uuid.v4(),
          title: 'Daily planning',
          description: 'Prepare tomorrow before ending the day.',
          category: 'Personal',
          priority: 'Medium',
          estimatedMinutes: 10,
          recurring: 'Daily',
          tags: const ['planning'],
        ),
      ];
}