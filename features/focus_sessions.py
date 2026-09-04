from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class FocusBlock:
    task_id: int
    title: str
    focus_minutes: int = 25
    break_minutes: int = 5


def build_focus_plan(tasks, focus_minutes: int = 25, break_minutes: int = 5, limit: int = 4) -> list[FocusBlock]:
    focus_minutes = max(1, int(focus_minutes))
    break_minutes = max(0, int(break_minutes))
    limit = max(0, int(limit))
    pending = [t for t in tasks if not t.get("completed")]
    pending.sort(key=lambda t: (str(t.get("priority", "Medium")).lower() != "high", str(t.get("due_date", "")), str(t.get("title", "")).casefold()))
    return [FocusBlock(int(t["id"]), str(t.get("title", "")), focus_minutes, break_minutes) for t in pending[:limit]]
