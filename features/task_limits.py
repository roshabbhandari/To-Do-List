def enforce_limit(tasks, limit):
    if limit < 0:
        raise ValueError("limit must be non-negative")
    items = list(tasks)
    return items[:limit]
