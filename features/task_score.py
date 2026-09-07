def score(task):
    value = 0
    value += {"high": 30, "medium": 20, "low": 10}.get(str(task.get("priority", "")).casefold(), 0)
    value += 15 if task.get("favorite") else 0
    value += 25 if not task.get("completed") else 0
    return value
