def dependencies_ready(task, tasks_by_id):
    for dep_id in task.get("depends_on", []) or []:
        dependency = tasks_by_id.get(dep_id)
        if dependency is None or not dependency.get("completed"):
            return False
    return True
