from __future__ import annotations

from typing import Iterable


def remaining_budget(tasks: Iterable[dict], minutes: int) -> list[dict]:
    """Return pending tasks that fit within a daily time budget."""
    if minutes < 0:
        raise ValueError("minutes must be non-negative")

    result: list[dict] = []
    used = 0
    for task in tasks:
        if task.get("completed"):
            continue
        estimate = max(0, int(task.get("estimate_minutes", 0) or 0))
        if used + estimate > minutes:
            continue
        result.append(task)
        used += estimate
    return result
