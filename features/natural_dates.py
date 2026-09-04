from __future__ import annotations

from datetime import date, timedelta


def parse_natural_date(value: str, base: date | None = None) -> str | None:
    text = str(value or "").strip().casefold()
    if not text:
        return None
    base = base or date.today()
    if text == "today":
        target = base
    elif text == "tomorrow":
        target = base + timedelta(days=1)
    elif text == "next week":
        target = base + timedelta(days=7)
    elif text.startswith("+") and text.endswith("d") and text[1:-1].isdigit():
        target = base + timedelta(days=int(text[1:-1]))
    else:
        try:
            target = date.fromisoformat(text)
        except ValueError:
            return None
    return target.isoformat()
