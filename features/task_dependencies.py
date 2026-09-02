def dependency_order(tasks):
    items = {str(task["id"]): task for task in tasks if "id" in task}
    result = []
    visiting = set()
    visited = set()

    def visit(task_id):
        if task_id in visited:
            return
        if task_id in visiting:
            raise ValueError("Circular task dependency detected")
        visiting.add(task_id)
        task = items[task_id]
        dependency = task.get("depends_on")
        if dependency not in (None, "", 0, "0"):
            dependency = str(dependency)
            if dependency in items:
                visit(dependency)
        visiting.remove(task_id)
        visited.add(task_id)
        result.append(task)

    for task_id in items:
        visit(task_id)
    return result
