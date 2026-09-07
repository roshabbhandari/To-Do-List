def partition_tasks(tasks, size):
    if size <= 0:
        raise ValueError("size must be positive")
    tasks = list(tasks)
    return [tasks[i:i + size] for i in range(0, len(tasks), size)]
