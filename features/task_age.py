from datetime import datetime


def task_age_days(task, now=None):
    now = now or datetime.now()
    value = task.get("created_at")
    if not value:
        return 0
    try:
        created = datetime.fromisoformat(str(value).replace("Z", "+00:00"))
        if created.tzinfo and now.tzinfo is None:
            now = now.astimezone(created.tzinfo)
        return max(0, (now - created).days)
    except ValueError:
        return 0
