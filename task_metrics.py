from datetime import datetime


def completion_rate(tasks):
    total = len(tasks)
    completed = sum(1 for task in tasks if task.get("completed"))
    return round(completed / total * 100, 2) if total else 0.0


def average_completion_age(tasks, now=None):
    now = now or datetime.now()
    ages = []
    for task in tasks:
        if not task.get("completed") or not task.get("created_at"):
            continue
        try:
            created = datetime.fromisoformat(task["created_at"])
        except (TypeError, ValueError):
            continue
        ages.append(max(0.0, (now - created).total_seconds() / 86400))
    return round(sum(ages) / len(ages), 2) if ages else 0.0
