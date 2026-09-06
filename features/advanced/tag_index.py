from __future__ import annotations


def build_tag_index(tasks: list[dict]) -> dict[str, list[int]]:
    """Build a normalized tag -> task ID index."""
    index: dict[str, list[int]] = {}
    for task in tasks:
        raw = task.get("tags", "")
        tags = raw if isinstance(raw, list) else str(raw).split(",")
        for tag in tags:
            name = " ".join(str(tag).strip().lower().split())
            if name:
                index.setdefault(name, []).append(int(task["id"]))
    return index
