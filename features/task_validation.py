def validate_task(task):
    errors = []
    if not str(task.get("title", "")).strip():
        errors.append("title is required")
    priority = str(task.get("priority", "")).lower()
    if priority and priority not in {"low", "medium", "high"}:
        errors.append("invalid priority")
    return errors
