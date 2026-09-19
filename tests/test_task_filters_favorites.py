from task_filters import filter_tasks


def test_filter_tasks_can_select_favorites_only():
    tasks = [
        {"title": "A", "favorite": True},
        {"title": "B", "favorite": False},
        {"title": "C"},
    ]
    assert filter_tasks(tasks, favorite=True) == [tasks[0]]
