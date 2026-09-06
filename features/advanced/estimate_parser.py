from __future__ import annotations

import re


def parse_estimate(value: str) -> int:
    """Parse human-friendly duration like '30m', '1h', or '1h 20m'."""
    text = str(value).strip().lower()
    if not text:
        return 0
    total = 0
    for amount, unit in re.findall(r"(\d+)\s*(h|m)", text):
        total += int(amount) * (60 if unit == "h" else 1)
    if total == 0 and text.isdigit():
        total = int(text)
    return total
