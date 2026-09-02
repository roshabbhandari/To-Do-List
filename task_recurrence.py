from datetime import date
from recurring_tasks import build_schedule


def preview_recurring_task(start, frequency, count=5):
    if not isinstance(start, date):
        raise TypeError("start must be a date")
    if count < 1 or count > 100:
        raise ValueError("count must be between 1 and 100")
    return build_schedule(start, frequency, count)
