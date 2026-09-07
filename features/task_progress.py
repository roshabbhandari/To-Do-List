def progress(tasks):
    total = len(tasks)
    done = sum(1 for task in tasks if task.get("completed"))
    return {"total": total, "completed": done, "pending": total - done,
            "percent": round(done * 100 / total, 2) if total else 0.0}
