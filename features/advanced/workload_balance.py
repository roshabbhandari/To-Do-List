from __future__ import annotations

from collections import Counter


def workload_balance(tasks: list[dict]) -> dict:
    """Measure how evenly pending tasks are distributed across categories."""
    counts = Counter(
        str(t.get("category") or "Uncategorized")
        for t in tasks if not t.get("completed")
    )
    if not counts:
        return {"categories": {}, "max_load": 0, "min_load": 0, "spread": 0}
    values = list(counts.values())
    return {
        "categories": dict(counts),
        "max_load": max(values),
        "min_load": min(values),
        "spread": max(values) - min(values),
    }
