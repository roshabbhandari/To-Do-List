from __future__ import annotations

from datetime import date, timedelta


def next_occurrences(start: str, cadence: str, count: int = 5) -> list[str]:
    """Generate simple daily or weekly recurring task dates."""
    if count < 0:
        raise ValueError("count must be non-negative")
    first = date.fromisoformat(start)
    step = {"daily": 1, "weekly": 7}.get(str(cadence).lower())
    if step is None:
        raise ValueError("cadence must be daily or weekly")
    return [(first + timedelta(days=step * i)).isoformat() for i in range(count)]
