from __future__ import annotations

from datetime import date
from typing import Iterable, Mapping


def build_daily_digest(tasks: Iterable[Mapping], day: date | None = None) -> dict:
    day = day or date.today()
    due_today = []
    overdue = []
    for task in tasks:
        if task.get("completed"):
            continue
        due = str(task.get("due_date", "")).strip()
        if not due:
            continue
        try:
            target = date.fromisoformat(due)
        except ValueError:
            continue
        if target == day:
            due_today.append(task)
        elif target < day:
            overdue.append(task)
    return {
        "date": day.isoformat(),
        "due_today": due_today,
        "overdue": overdue,
        "action_count": len(due_today) + len(overdue),
    }
