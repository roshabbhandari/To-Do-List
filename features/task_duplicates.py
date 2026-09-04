from __future__ import annotations

import re
from collections import defaultdict
from typing import Iterable, Mapping


def _key(title: str) -> str:
    return re.sub(r"\s+", " ", str(title or "").strip().casefold())


def duplicate_groups(tasks: Iterable[Mapping]) -> list[list[int]]:
    groups = defaultdict(list)
    for task in tasks:
        key = _key(task.get("title", ""))
        if key:
            groups[key].append(int(task["id"]))
    return [ids for ids in groups.values() if len(ids) > 1]
