from collections import defaultdict


def workload_by_category(tasks):
    result = defaultdict(lambda: {"total": 0, "completed": 0, "pending": 0})
    for task in tasks:
        category = task.get("category") or "Uncategorized"
        bucket = result[category]
        bucket["total"] += 1
        if task.get("completed"):
            bucket["completed"] += 1
        else:
            bucket["pending"] += 1
    return dict(result)


def overloaded_categories(tasks, threshold=5):
    if threshold < 1:
        raise ValueError("threshold must be positive")
    workload = workload_by_category(tasks)
    return sorted(
        category for category, values in workload.items()
        if values["pending"] >= threshold
    )
