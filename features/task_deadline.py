from datetime import date, datetime


def days_until_due(task, today=None):
    today = today or date.today()
    raw = task.get("due_date")
    if not raw:
        return None
    try:
        due = datetime.strptime(str(raw)[:10], "%Y-%m-%d").date()
        return (due - today).days
    except ValueError:
        return None
