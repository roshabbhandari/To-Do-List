from __future__ import annotations

import re


def _normalize(title: str) -> str:
    return re.sub(r"\s+", " ", str(title).strip().lower())


def duplicate_groups(tasks: list[dict]) -> list[list[int]]:
    """Find task IDs sharing the same normalized title."""
    groups: dict[str, list[int]] = {}
    for task in tasks:
        key = _normalize(task.get("title", ""))
        if key:
            groups.setdefault(key, []).append(int(task["id"]))
    return [ids for ids in groups.values() if len(ids) > 1]
