from datetime import date, timedelta


def due_this_week(tasks, start=None):
    start = start or date.today()
    end = start + timedelta(days=6)
    result = []
    for task in tasks:
        raw = str(task.get("due_date") or "")[:10]
        try:
            due = date.fromisoformat(raw)
        except ValueError:
            continue
        if not task.get("completed") and start <= due <= end:
            result.append(task)
    return result
