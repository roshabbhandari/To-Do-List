from .task_deadline import days_until_due


def deadline_risk(task, today=None):
    if task.get("completed"):
        return "done"
    days = days_until_due(task, today)
    if days is None:
        return "unknown"
    if days < 0:
        return "critical"
    if days == 0:
        return "high"
    if days <= 2:
        return "medium"
    return "low"
