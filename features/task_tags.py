def parse_tags(value):
    if isinstance(value, (list, tuple, set)):
        raw = value
    else:
        raw = str(value or "").replace(",", " ").split()
    seen = set()
    result = []
    for tag in raw:
        tag = str(tag).strip().lstrip("#").casefold()
        if tag and tag not in seen:
            seen.add(tag)
            result.append(tag)
    return result
