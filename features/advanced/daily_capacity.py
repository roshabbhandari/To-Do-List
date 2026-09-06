from __future__ import annotations


def capacity_report(tasks: list[dict], available_minutes: int) -> dict:
    """Estimate whether pending work fits the available daily capacity."""
    if available_minutes < 0:
        raise ValueError("available_minutes must be non-negative")
    total = sum(max(0, int(t.get("estimate_minutes", 0) or 0)) for t in tasks if not t.get("completed"))
    return {
        "available_minutes": available_minutes,
        "planned_minutes": total,
        "remaining_minutes": available_minutes - total,
        "over_capacity": total > available_minutes,
    }
