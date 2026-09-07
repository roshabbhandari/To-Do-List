from .task_score import score


def top_tasks(tasks, limit=5):
    if limit < 0:
        raise ValueError("limit must be non-negative")
    return sorted(tasks, key=score, reverse=True)[:limit]
