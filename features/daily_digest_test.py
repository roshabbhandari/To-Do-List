from datetime import date

from features.daily_digest import build_daily_digest


def test_daily_digest_separates_today_and_overdue():
    tasks = [
        {"id": 1, "title": "Today", "completed": 0, "due_date": "2026-09-04"},
        {"id": 2, "title": "Late", "completed": 0, "due_date": "2026-09-02"},
        {"id": 3, "title": "Done", "completed": 1, "due_date": "2026-09-04"},
    ]
    result = build_daily_digest(tasks, date(2026, 9, 4))
    assert [t["id"] for t in result["due_today"]] == [1]
    assert [t["id"] for t in result["overdue"]] == [2]
    assert result["action_count"] == 2
