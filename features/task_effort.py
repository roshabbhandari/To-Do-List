def total_estimated_minutes(tasks):
    total = 0
    for task in tasks:
        try:
            total += max(0, int(task.get("estimate_minutes", 0) or 0))
        except (TypeError, ValueError):
            continue
    return total
