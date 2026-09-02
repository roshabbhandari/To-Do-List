from datetime import date

PRIORITY_WEIGHT = {"High": 3, "Medium": 2, "Low": 1}


def rank_task(task, today=None):
    today = today or date.today()
    priority = str(task.get("priority", "Medium"))
    score = PRIORITY_WEIGHT.get(priority, 2) * 10
    due = str(task.get("due_date", "")).strip()
    if due:
        try:
            days = (date.fromisoformat(due) - today).days
        except ValueError:
            days = 30
        if days < 0:
            score += 50
        elif days == 0:
            score += 40
        elif days <= 3:
            score += 25
        elif days <= 7:
            score += 10
    if task.get("favorite"):
        score += 5
    if task.get("completed"):
        score -= 100
    return score


def prioritize(tasks, today=None):
    return sorted(tasks, key=lambda task: rank_task(task, today), reverse=True)
