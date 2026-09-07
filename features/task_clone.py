def clone_task(task, new_id=None):
    cloned = dict(task)
    cloned.pop("completed_at", None)
    cloned["completed"] = False
    if new_id is not None:
        cloned["id"] = new_id
    return cloned
