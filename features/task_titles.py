def normalize_title(title):
    return " ".join(str(title or "").strip().split())


def title_key(title):
    return normalize_title(title).casefold()
