from features.focus_sessions import build_focus_plan


def test_focus_plan_prioritizes_high_priority_tasks():
    tasks = [
        {"id": 1, "title": "Normal", "priority": "Low", "completed": 0, "due_date": "2026-09-04"},
        {"id": 2, "title": "Urgent", "priority": "High", "completed": 0, "due_date": "2026-09-08"},
    ]
    plan = build_focus_plan(tasks, limit=1)
    assert plan[0].task_id == 2
    assert plan[0].focus_minutes == 25


def test_focus_plan_respects_limit():
    tasks = [{"id": i, "title": str(i), "completed": 0} for i in range(5)]
    assert len(build_focus_plan(tasks, limit=2)) == 2
