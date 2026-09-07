def sort_tasks(tasks, key="priority", reverse=False):
    weights = {"high": 0, "medium": 1, "low": 2}
    def value(task):
        if key == "priority":
            return weights.get(str(task.get("priority", "")).lower(), 3)
        if key == "title":
            return str(task.get("title", "")).casefold()
        if key == "due_date":
            return str(task.get("due_date") or "9999-12-31")
        return task.get(key)
    return sorted(tasks, key=value, reverse=reverse)
