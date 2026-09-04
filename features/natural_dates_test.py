from datetime import date

from features.natural_dates import parse_natural_date


def test_parse_relative_dates():
    base = date(2026, 9, 4)
    assert parse_natural_date("today", base) == "2026-09-04"
    assert parse_natural_date("tomorrow", base) == "2026-09-05"
    assert parse_natural_date("+3d", base) == "2026-09-07"


def test_parse_iso_date_and_invalid_value():
    assert parse_natural_date("2026-10-01") == "2026-10-01"
    assert parse_natural_date("not-a-date") is None
