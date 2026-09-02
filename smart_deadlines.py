from datetime import date, timedelta

_PRIORITY_DAYS = {"high": 2, "medium": 5, "low": 7}


def suggest_deadline(priority="Medium", effort_hours=1, start=None):
    if effort_hours < 0:
        raise ValueError("effort_hours must be non-negative")
    start = start or date.today()
    if not isinstance(start, date):
        raise TypeError("start must be a date")
    key = str(priority).strip().lower()
    if key not in _PRIORITY_DAYS:
        key = "medium"
    effort_days = max(0, int(effort_hours + 7) // 8)
    return start + timedelta(days=_PRIORITY_DAYS[key] + effort_days)


def urgency_label(due_date, today=None):
    if not due_date:
        return "none"
    today = today or date.today()
    if not isinstance(due_date, date) or not isinstance(today, date):
        raise TypeError("due_date and today must be dates")
    days = (due_date - today).days
    if days < 0:
        return "overdue"
    if days == 0:
        return "today"
    if days <= 2:
        return "soon"
    if days <= 7:
        return "upcoming"
    return "later"
