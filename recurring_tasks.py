from datetime import date
import calendar


def next_occurrence(current, frequency):
    if not isinstance(current, date):
        raise TypeError("current must be a date")
    key = str(frequency).strip().lower()
    if key == "daily":
        return current.fromordinal(current.toordinal() + 1)
    if key == "weekly":
        return current.fromordinal(current.toordinal() + 7)
    if key == "monthly":
        year = current.year + (current.month // 12)
        month = current.month % 12 + 1
        day = min(current.day, calendar.monthrange(year, month)[1])
        return date(year, month, day)
    raise ValueError("frequency must be daily, weekly, or monthly")


def build_schedule(start, frequency, count):
    if count < 1:
        raise ValueError("count must be positive")
    dates = [start]
    for _ in range(count - 1):
        dates.append(next_occurrence(dates[-1], frequency))
    return dates
