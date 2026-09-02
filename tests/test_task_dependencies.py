import pytest

from features.task_dependencies import dependency_order


def test_dependency_comes_first():
    tasks = [
        {"id": 2, "title": "Build", "depends_on": 1},
        {"id": 1, "title": "Plan", "depends_on": ""},
    ]
    ordered = dependency_order(tasks)
    assert [task["id"] for task in ordered] == [1, 2]


def test_circular_dependency_is_rejected():
    tasks = [
        {"id": 1, "title": "A", "depends_on": 2},
        {"id": 2, "title": "B", "depends_on": 1},
    ]
    with pytest.raises(ValueError):
        dependency_order(tasks)
