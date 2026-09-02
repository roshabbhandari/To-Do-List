from collections import Counter


def goal_progress(tasks, category=None):
    selected = [t for t in tasks if category is None or t.get("category") == category]
    total = len(selected)
    done = sum(1 for t in selected if t.get("completed"))
    percent = round(done / total * 100, 1) if total else 0.0
    priorities = Counter(
        str(t.get("priority", "medium")).lower()
        for t in selected
        if not t.get("completed")
    )
    return {
        "total": total,
        "completed": done,
        "pending": total - done,
        "completion_rate": percent,
        "pending_priorities": dict(priorities),
    }


def category_goals(tasks):
    categories = sorted({t.get("category", "") for t in tasks if t.get("category", "")})
    return {category: goal_progress(tasks, category) for category in categories}
