from datetime import datetime


def archive_completed(tasks, before=None):
    before = before or datetime.now()
    archived = []
    active = []
    for task in tasks:
        if not task.get("completed"):
            active.append(task)
            continue
        updated_at = task.get("updated_at") or task.get("created_at")
        try:
            updated = datetime.fromisoformat(updated_at) if updated_at else before
        except (TypeError, ValueError):
            updated = before
        if updated <= before:
            archived.append(task)
        else:
            active.append(task)
    return archived, active
