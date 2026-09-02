from datetime import date

from features.smart_scheduler import prioritize, rank_task


def test_overdue_high_priority_ranks_first():
    today = date(2026, 9, 2)
    tasks = [
        {"title": "later", "priority": "Low", "due_date": "2026-09-10"},
        {"title": "urgent", "priority": "High", "due_date": "2026-09-01"},
    ]
    assert prioritize(tasks, today)[0]["title"] == "urgent"


def test_completed_task_is_deprioritized():
    today = date(2026, 9, 2)
    active = {"priority": "Low", "due_date": "2026-09-02", "completed": False}
    done = {"priority": "High", "due_date": "2026-09-02", "completed": True}
    assert rank_task(active, today) > rank_task(done, today)
