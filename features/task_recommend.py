from .task_risk import deadline_risk


def recommend(tasks, today=None):
    weights = {"critical": 4, "high": 3, "medium": 2, "low": 1, "unknown": 0}
    pending = [t for t in tasks if not t.get("completed")]
    return sorted(pending, key=lambda t: -weights[deadline_risk(t, today)])
