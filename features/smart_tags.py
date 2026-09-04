from __future__ import annotations

import re
from collections import Counter
from typing import Iterable, Mapping


def normalize_tags(value: str) -> list[str]:
    parts = re.split(r"[,\s]+", str(value or "").strip())
    cleaned = {p.lower().lstrip("#") for p in parts if p.strip()}
    return sorted(cleaned)


def suggest_tags(tasks: Iterable[Mapping], limit: int = 5) -> list[str]:
    counts = Counter()
    for task in tasks:
        counts.update(normalize_tags(str(task.get("tags", ""))))
    return [tag for tag, _ in counts.most_common(max(0, limit))]
