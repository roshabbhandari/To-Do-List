from datetime import date

from features.task_streaks import completion_streak, longest_streak


def test_current_streak():
    today = date(2026, 9, 2)
    dates = ["2026-09-02", "2026-09-01", "2026-08-31", "2026-08-20"]
    assert completion_streak(dates, today) == 3


def test_longest_streak():
    dates = ["2026-08-01", "2026-08-02", "2026-08-03", "2026-08-10"]
    assert longest_streak(dates) == 3


def test_empty_streak():
    assert longest_streak([]) == 0
