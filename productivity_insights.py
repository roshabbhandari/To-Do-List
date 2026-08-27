"""Advanced local productivity insights for Roshab Tasks.

Run with: python productivity_insights.py
No network or external services are required.
"""
from __future__ import annotations

from datetime import date, datetime
from database import Database


def _parse_date(value: str) -> date | None:
    if not value:
        return None
    try:
        return datetime.strptime(value, "%Y-%m-%d").date()
    except ValueError:
        return None


def analyze_tasks(rows):
    """Return deterministic productivity metrics from SQLite task rows."""
    rows = list(rows)
    total = len(rows)
    completed = sum(int(r["completed"]) for r in rows)
    pending = total - completed
    today = date.today()
    overdue = sum(
        1 for r in rows
        if not r["completed"] and _parse_date(r["due_date"]) and _parse_date(r["due_date"]) < today
    )
    high_pending = sum(1 for r in rows if not r["completed"] and r["priority"] == "High")

    categories: dict[str, int] = {}
    for row in rows:
        if not row["completed"]:
            category = (row["category"] or "Uncategorized").strip() or "Uncategorized"
            categories[category] = categories.get(category, 0) + 1

    completion_rate = round((completed / total) * 100, 1) if total else 0.0

    # A transparent 0-100 score: completion progress minus overdue pressure.
    score = round(max(0.0, min(100.0,
        completion_rate - (overdue * 8) - (high_pending * 2)
    )), 1)

    next_tasks = sorted(
        [r for r in rows if not r["completed"]],
        key=lambda r: (
            0 if r["priority"] == "High" else 1 if r["priority"] == "Medium" else 2,
            0 if r["due_date"] else 1,
            r["due_date"] or "9999-12-31",
            (r["title"] or "").lower(),
        ),
    )[:5]

    return {
        "total": total,
        "completed": completed,
        "pending": pending,
        "overdue": overdue,
        "high_pending": high_pending,
        "completion_rate": completion_rate,
        "productivity_score": score,
        "top_category": max(categories, key=categories.get) if categories else "None",
        "category_counts": dict(sorted(categories.items())),
        "next_tasks": [r["title"] for r in next_tasks],
    }


def print_insights(metrics):
    print("\n=== Roshab Tasks • Productivity Insights ===")
    print(f"Productivity score : {metrics['productivity_score']}/100")
    print(f"Completion rate    : {metrics['completion_rate']}%")
    print(f"Total / Done       : {metrics['total']} / {metrics['completed']}")
    print(f"Pending / Overdue  : {metrics['pending']} / {metrics['overdue']}")
    print(f"High-priority left : {metrics['high_pending']}")
    print(f"Top active category: {metrics['top_category']}")
    print("\nNext best tasks:")
    if not metrics["next_tasks"]:
        print("  • Nothing pending — nice work!")
    else:
        for idx, title in enumerate(metrics["next_tasks"], 1):
            print(f"  {idx}. {title}")


if __name__ == "__main__":
    db = Database()
    print_insights(analyze_tasks(db.export_rows()))
