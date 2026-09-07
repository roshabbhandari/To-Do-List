from collections import Counter


def status_counts(tasks):
    return Counter("completed" if t.get("completed") else "pending" for t in tasks)


def priority_counts(tasks):
    return Counter(str(t.get("priority") or "none").lower() for t in tasks)
