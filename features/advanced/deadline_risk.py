from __future__ import annotations

from datetime import date


def deadline_risk(task: dict, today: date | None = None) -> str:
    """Classify pending task deadline risk as low, medium, or high."""
    if task.get("completed"):
        return "none"
    today = today or date.today()
    raw = str(task.get("due_date", "")).strip()
    if not raw:
        return "low"
    try:
        days = (date.fromisoformat(raw) - today).days
    except ValueError:
        return "low"
    if days < 0:
        return "high"
    if days <= 1:
        return "high"
    if days <= 3:
        return "medium"
    return "low"
