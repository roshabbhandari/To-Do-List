from .task_deadline import days_until_due


def overdue_tasks(tasks, today=None):
    return [
        task for task in tasks
        if not task.get("completed") and (days_until_due(task, today) is not None)
        and days_until_due(task, today) < 0
    ]
