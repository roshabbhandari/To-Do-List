from __future__ import annotations


def next_actions(tasks: list[dict], limit: int = 3) -> list[dict]:
    """Return the best pending next actions using priority and due-date rank."""
    if limit < 0:
        raise ValueError("limit must be non-negative")

    def key(task: dict) -> tuple[int, str]:
        priority = {"High": 3, "Medium": 2, "Low": 1}.get(str(task.get("priority", "Medium")), 2)
        due = str(task.get("due_date", "9999-12-31")) or "9999-12-31"
        return (-priority, due)

    pending = [task for task in tasks if not task.get("completed")]
    return sorted(pending, key=key)[:limit]
