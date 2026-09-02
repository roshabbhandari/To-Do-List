from dataclasses import dataclass


@dataclass(frozen=True)
class FocusBlock:
    title: str
    minutes: int


def build_focus_plan(tasks, work_minutes=25, break_minutes=5, max_tasks=4):
    selected = [task for task in tasks if not task.get("completed")][:max_tasks]
    plan = []
    for index, task in enumerate(selected):
        plan.append(FocusBlock(str(task.get("title", "Untitled")), work_minutes))
        if index < len(selected) - 1:
            plan.append(FocusBlock("Break", break_minutes))
    return plan
