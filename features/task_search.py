def search_tasks(tasks, query):
    needle = str(query or "").strip().casefold()
    if not needle:
        return list(tasks)
    return [
        task for task in tasks
        if needle in str(task.get("title", "")).casefold()
        or needle in str(task.get("category", "")).casefold()
    ]
