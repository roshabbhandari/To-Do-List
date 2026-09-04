from features.task_duplicates import duplicate_groups


def test_duplicate_groups_normalize_spacing_and_case():
    tasks = [
        {"id": 1, "title": "Buy Milk"},
        {"id": 2, "title": "  buy   milk "},
        {"id": 3, "title": "Study Python"},
    ]
    assert duplicate_groups(tasks) == [[1, 2]]


def test_duplicate_groups_skip_empty_titles():
    assert duplicate_groups([{"id": 1, "title": ""}]) == []
