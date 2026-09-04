from __future__ import annotations

from datetime import date
from typing import Iterable, Mapping


def task_health(tasks: Iterable[Mapping], today: date | None = None) -> dict:
    today = today or date.today()
    total = completed = overdue = due_today = high_pending = 0
    for task in tasks:
        total += 1
        if task.get("completed"):
            completed += 1
            continue
        if str(task.get("priority", "")).casefold() == "high":
            high_pending += 1
        due = str(task.get("due_date", "")).strip()
        if due:
            try:
                target = date.fromisoformat(due)
            except ValueError:
                continue
            overdue += target < today
            due_today += target == today
    return {
        "total": total,
        "completed": completed,
        "pending": total - completed,
        "overdue": int(overdue),
        "due_today": int(due_today),
        "high_pending": high_pending,
    }
