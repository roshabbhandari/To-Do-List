from collections import defaultdict


def group_by_category(tasks):
    groups = defaultdict(list)
    for task in tasks:
        groups[str(task.get("category") or "Uncategorized")].append(task)
    return dict(groups)
