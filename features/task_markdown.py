def to_markdown(tasks):
    lines = []
    for task in tasks:
        mark = "x" if task.get("completed") else " "
        title = str(task.get("title") or "Untitled").strip()
        lines.append(f"- [{mark}] {title}")
    return "\n".join(lines)
