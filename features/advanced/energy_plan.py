from __future__ import annotations


def energy_plan(tasks: list[dict], energy: str = "normal") -> list[dict]:
    """Select pending tasks suited to low, normal, or high energy."""
    weights = {"low": {"Low": 3, "Medium": 1, "High": 0}, "normal": {"Low": 1, "Medium": 3, "High": 3}, "high": {"Low": 0, "Medium": 2, "High": 4}}
    energy = str(energy).lower()
    if energy not in weights:
        raise ValueError("energy must be low, normal, or high")
    scored = []
    for task in tasks:
        if task.get("completed"):
            continue
        priority = str(task.get("priority", "Medium"))
        score = weights[energy].get(priority, 1)
        scored.append((score, int(task.get("id", 0)), task))
    scored.sort(key=lambda item: (-item[0], item[1]))
    return [item[2] for item in scored]
