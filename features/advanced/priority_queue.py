from __future__ import annotations

import heapq


def build_queue(tasks: list[dict]) -> list[tuple[int, int, dict]]:
    """Build a stable heap ordered by priority and task ID."""
    weights = {"High": 0, "Medium": 1, "Low": 2}
    queue = []
    for task in tasks:
        if task.get("completed"):
            continue
        priority = weights.get(str(task.get("priority", "Medium")), 1)
        queue.append((priority, int(task.get("id", 0)), task))
    heapq.heapify(queue)
    return queue
