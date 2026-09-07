def query(tasks, *, completed=None, category=None, priority=None):
    result = list(tasks)
    if completed is not None:
        result = [t for t in result if bool(t.get("completed")) is completed]
    if category is not None:
        result = [t for t in result if str(t.get("category", "")).casefold() == str(category).casefold()]
    if priority is not None:
        result = [t for t in result if str(t.get("priority", "")).casefold() == str(priority).casefold()]
    return result
