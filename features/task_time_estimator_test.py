from features.task_time_estimator import estimate_minutes, estimate_batch_minutes, due_soon
from datetime import datetime


def test_estimate_minutes_uses_priority():
    assert estimate_minutes({"priority": "High", "title": "x"}) == 60


def test_estimate_batch_minutes():
    tasks = [{"priority": "Low", "title": "a"}, {"priority": "Medium", "title": "b"}]
    assert estimate_batch_minutes(tasks) == 65


def test_due_soon_handles_invalid_date():
    assert not due_soon({"due_date": "bad"})


def test_due_soon_detects_near_deadline():
    now = datetime(2026, 9, 4)
    assert due_soon({"due_date": "2026-09-05"}, now=now)
