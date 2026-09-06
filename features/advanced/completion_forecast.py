from __future__ import annotations


def completion_forecast(total: int, completed: int, daily_rate: float) -> dict:
    """Estimate days remaining from a historical daily completion rate."""
    if total < 0 or completed < 0 or daily_rate < 0:
        raise ValueError("counts and rate must be non-negative")
    remaining = max(0, total - completed)
    days = None if daily_rate == 0 and remaining else (0 if not remaining else remaining / daily_rate)
    return {"remaining": remaining, "daily_rate": daily_rate, "estimated_days": days}
