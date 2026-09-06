from __future__ import annotations

from collections import Counter


def priority_stats(tasks: list[dict]) -> dict[str, int]:
    """Count pending tasks by priority with stable keys."""
    stats = Counter(str(t.get("priority", "Medium")) for t in tasks if not t.get("completed"))
    return {name: stats.get(name, 0) for name in ("High", "Medium", "Low")}
