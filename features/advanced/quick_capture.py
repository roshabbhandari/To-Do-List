from __future__ import annotations


def parse_quick_capture(text: str) -> dict:
    """Parse a compact task string: title @category #tag !priority."""
    raw = " ".join(str(text).split())
    priority = "Medium"
    for marker, value in (("!high", "High"), ("!medium", "Medium"), ("!low", "Low")):
        if marker in raw.lower():
            priority = value
            raw = raw.replace(marker, "").replace(marker.title(), "")
            break
    tags = [part[1:] for part in raw.split() if part.startswith("#") and len(part) > 1]
    category = next((part[1:] for part in raw.split() if part.startswith("@") and len(part) > 1), "Personal")
    title = " ".join(part for part in raw.split() if not part.startswith("#") and not part.startswith("@"))
    return {"title": title.strip(), "category": category, "priority": priority, "tags": tags}
