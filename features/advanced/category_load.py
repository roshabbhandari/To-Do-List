from __future__ import annotations

from collections import Counter


def category_load(tasks: list[dict]) -> dict[str, int]:
    """Count pending tasks by category."""
    return dict(Counter(
        str(task.get("category") or "Uncategorized")
        for task in tasks
        if not task.get("completed")
    ))
