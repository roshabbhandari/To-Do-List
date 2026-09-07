from datetime import datetime


def mark_completed(task, when=None):
    updated = dict(task)
    updated["completed"] = True
    updated["completed_at"] = (when or datetime.now()).isoformat()
    return updated


def reopen(task):
    updated = dict(task)
    updated["completed"] = False
    updated.pop("completed_at", None)
    return updated
