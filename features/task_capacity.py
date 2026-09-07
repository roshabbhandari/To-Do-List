def capacity(tasks, minutes):
    if minutes < 0:
        raise ValueError("minutes must be non-negative")
    selected, used = [], 0
    for task in tasks:
        try:
            effort = max(0, int(task.get("estimate_minutes", 0) or 0))
        except (TypeError, ValueError):
            effort = 0
        if used + effort <= minutes:
            selected.append(task)
            used += effort
    return {"tasks": selected, "used_minutes": used, "remaining_minutes": minutes - used}
