from __future__ import annotations

from datetime import datetime
from typing import Iterable, Mapping


def estimate_minutes(task: Mapping) -> int:
    priority = str(task.get("priority", "Medium")).lower()
    title = str(task.get("title", ""))
    base = {"high": 60, "medium": 40, "low": 25}.get(priority, 40)
    complexity = min(max(len(title) // 35, 0), 3) * 10
    return base + complexity


def estimate_batch_minutes(tasks: Iterable[Mapping]) -> int:
    return sum(estimate_minutes(task) for task in tasks)


def due_soon(task: Mapping, now: datetime | None = None, days: int = 2) -> bool:
    due = str(task.get("due_date", "")).strip()
    if not due:
        return False
    try:
        target = datetime.strptime(due, "%Y-%m-%d")
    except ValueError:
        return False
    now = now or datetime.now()
    return 0 <= (target.date() - now.date()).days <= days
