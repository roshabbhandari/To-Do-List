from __future__ import annotations

from collections import Counter
from typing import Iterable, Mapping


def project_progress(tasks: Iterable[Mapping], project: str) -> dict:
    selected = [t for t in tasks if str(t.get("category", "")).casefold() == project.casefold()]
    total = len(selected)
    completed = sum(bool(t.get("completed")) for t in selected)
    pending = total - completed
    percent = round((completed / total) * 100, 1) if total else 0.0
    priorities = Counter(str(t.get("priority", "Medium")) for t in selected if not t.get("completed"))
    return {
        "project": project,
        "total": total,
        "completed": completed,
        "pending": pending,
        "completion_rate": percent,
        "pending_priorities": dict(priorities),
    }
