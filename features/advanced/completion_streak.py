from __future__ import annotations

from datetime import date, timedelta


def streak_days(completion_dates: list[str]) -> int:
    """Return the current consecutive completion-day streak."""
    dates = set()
    for value in completion_dates:
        try:
            dates.add(date.fromisoformat(str(value)))
        except ValueError:
            continue
    if not dates:
        return 0
    cursor = date.today()
    if cursor not in dates:
        cursor -= timedelta(days=1)
    streak = 0
    while cursor in dates:
        streak += 1
        cursor -= timedelta(days=1)
    return streak
