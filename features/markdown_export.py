from __future__ import annotations

from typing import Iterable, Mapping


def tasks_to_markdown(tasks: Iterable[Mapping], title: str = "Task List") -> str:
    lines = [f"# {title.strip() or 'Task List'}", ""]
    for task in tasks:
        status = "x" if task.get("completed") else " "
        task_title = str(task.get("title", "Untitled")).strip() or "Untitled"
        priority = str(task.get("priority", "Medium"))
        due = str(task.get("due_date", "")).strip()
        suffix = f" — due {due}" if due else ""
        lines.append(f"- [{status}] **{task_title}** ({priority}){suffix}")
    return "\n".join(lines) + "\n"
