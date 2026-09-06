from __future__ import annotations

from datetime import date


def build_digest(tasks: list[dict], today: date | None = None) -> dict:
    """Create a compact daily task digest."""
    today = today or date.today()
    today_str = today.isoformat()
    pending = [t for t in tasks if not t.get("completed")]
    due_today = [t for t in pending if str(t.get("due_date", "")) == today_str]
    overdue = [
        t for t in pending
        if str(t.get("due_date", "")).strip() and str(t.get("due_date")) < today_str
    ]
    return {
        "date": today_str,
        "pending": len(pending),
        "due_today": len(due_today),
        "overdue": len(overdue),
        "top_tasks": [t.get("title", "Untitled") for t in due_today[:5]],
    }
