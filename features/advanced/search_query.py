from __future__ import annotations


def matches_query(task: dict, query: str) -> bool:
    """Match a task against title, description, category, or tags."""
    needle = str(query).strip().lower()
    if not needle:
        return True
    haystack = " ".join(str(task.get(k, "") or "") for k in ("title", "description", "category", "tags")).lower()
    return needle in haystack


def filter_tasks(tasks: list[dict], query: str) -> list[dict]:
    return [task for task in tasks if matches_query(task, query)]
