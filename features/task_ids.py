def unique_task_ids(tasks):
    seen = set()
    duplicates = set()
    for task in tasks:
        task_id = task.get("id")
        if task_id in seen:
            duplicates.add(task_id)
        seen.add(task_id)
    return {"unique": seen - duplicates, "duplicates": duplicates}
