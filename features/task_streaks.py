from datetime import date, timedelta


def completion_streak(completed_dates, today=None):
    today = today or date.today()
    days = {d if isinstance(d, date) else date.fromisoformat(str(d)) for d in completed_dates}
    streak = 0
    cursor = today
    while cursor in days:
        streak += 1
        cursor -= timedelta(days=1)
    return streak


def longest_streak(completed_dates):
    days = sorted({d if isinstance(d, date) else date.fromisoformat(str(d)) for d in completed_dates})
    if not days:
        return 0
    best = current = 1
    for previous, current_day in zip(days, days[1:]):
        if current_day - previous == timedelta(days=1):
            current += 1
        else:
            current = 1
        best = max(best, current)
    return best
