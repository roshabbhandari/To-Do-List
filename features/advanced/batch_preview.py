from __future__ import annotations


def preview_batch(tasks: list[dict], action: str) -> dict:
    """Return a dry-run summary for a bulk task action."""
    supported = {"complete", "favorite", "delete", "archive"}
    action = str(action).strip().lower()
    if action not in supported:
        raise ValueError(f"unsupported action: {action}")
    ids = [int(t["id"]) for t in tasks]
    return {"action": action, "count": len(ids), "task_ids": ids, "dry_run": True}
