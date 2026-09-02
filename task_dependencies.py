from collections import defaultdict, deque


def dependency_order(tasks):
    graph = defaultdict(list)
    indegree = {task["id"]: 0 for task in tasks}
    ids = set(indegree)

    for task in tasks:
        for dependency in task.get("depends_on", []):
            if dependency not in ids:
                continue
            graph[dependency].append(task["id"])
            indegree[task["id"]] += 1

    queue = deque(sorted(k for k, v in indegree.items() if v == 0))
    result = []
    while queue:
        current = queue.popleft()
        result.append(current)
        for child in sorted(graph[current]):
            indegree[child] -= 1
            if indegree[child] == 0:
                queue.append(child)

    if len(result) != len(indegree):
        raise ValueError("circular task dependency detected")
    return result
