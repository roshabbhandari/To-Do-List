from datetime import date


def due_today(tasks, today=None):
    value = (today or date.today()).isoformat()
    return [task for task in tasks if not task.get("completed") and str(task.get("due_date", ""))[:10] == value]
