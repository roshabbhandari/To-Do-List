def summarize(task):
    title = str(task.get("title") or "Untitled").strip()
    category = task.get("category") or "Uncategorized"
    priority = task.get("priority") or "none"
    status = "completed" if task.get("completed") else "pending"
    return f"{title} | {category} | {priority} | {status}"
