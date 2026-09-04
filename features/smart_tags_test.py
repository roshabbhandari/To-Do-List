from features.smart_tags import normalize_tags, suggest_tags


def test_normalize_tags_deduplicates_hashes_and_case():
    assert normalize_tags("#Python python, API") == ["api", "python"]


def test_suggest_tags_returns_most_common():
    tasks = [
        {"tags": "python api"},
        {"tags": "python"},
        {"tags": "api"},
    ]
    assert suggest_tags(tasks, 2) == ["python", "api"]
