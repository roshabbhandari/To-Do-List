def filter_completed(tasks, completed=True):
    return [task for task in tasks if bool(task.get("completed")) is completed]


def filter_priority(tasks, priority):
    wanted = str(priority).casefold()
    return [task for task in tasks if str(task.get("priority", "")).casefold() == wanted]
