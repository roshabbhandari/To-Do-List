from __future__ import annotations

from collections import defaultdict
from typing import Iterable, Mapping


def workload_by_category(tasks: Iterable[Mapping]) -> dict[str, int]:
    totals = defaultdict(int)
    for task in tasks:
        if task.get("completed"):
            continue
        category = str(task.get("category") or "Uncategorized").strip() or "Uncategorized"
        totals[category] += 1
    return dict(sorted(totals.items(), key=lambda item: (-item[1], item[0].casefold())))


def workload_level(pending_count: int) -> str:
    if pending_count < 5:
        return "light"
    if pending_count < 10:
        return "moderate"
    if pending_count < 20:
        return "heavy"
    return "critical"
