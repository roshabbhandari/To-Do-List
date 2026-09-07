def favorites(tasks):
    return [task for task in tasks if bool(task.get("favorite"))]


def toggle_favorite(task):
    updated = dict(task)
    updated["favorite"] = not bool(task.get("favorite"))
    return updated
