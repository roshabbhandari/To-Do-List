def filter_tasks(tasks, *, status="all", category="all", priority="all", favorite=False):
    status = str(status).lower()
    category = str(category).lower()
    priority = str(priority).lower()
    result = []
    for task in tasks:
        if status == "completed" and not task.get("completed"):
            continue
        if status == "pending" and task.get("completed"):
            continue
        if category != "all" and str(task.get("category", "")).lower() != category:
            continue
        if priority != "all" and str(task.get("priority", "")).lower() != priority:
            continue
        if favorite and not task.get("favorite"):
            continue
        result.append(task)
    return result
