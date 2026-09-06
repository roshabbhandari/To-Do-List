from __future__ import annotations

from .deadline_risk import deadline_risk


def task_health(task: dict) -> int:
    """Return a simple 0-100 health score for a task."""
    if task.get("completed"):
        return 100
    score = 60
    if task.get("favorite"):
        score += 5
    score -= {"high": 20, "medium": 5, "low": 0}.get(str(task.get("priority", "Medium")).lower(), 5)
    score -= {"high": 35, "medium": 15, "low": 0}.get(deadline_risk(task), 0)
    if not str(task.get("title", "")).strip():
        score -= 20
    return max(0, min(100, score))
