from datetime import date

from features.task_health import task_health


def test_task_health_counts_due_dates():
    tasks = [
        {"completed": 1, "priority": "High", "due_date": "2026-09-01"},
        {"completed": 0, "priority": "High", "due_date": "2026-09-03"},
        {"completed": 0, "priority": "Medium", "due_date": "2026-09-04"},
    ]
    result = task_health(tasks, date(2026, 9, 4))
    assert result["total"] == 3
    assert result["completed"] == 1
    assert result["pending"] == 2
    assert result["overdue"] == 1
    assert result["due_today"] == 1
    assert result["high_pending"] == 1
