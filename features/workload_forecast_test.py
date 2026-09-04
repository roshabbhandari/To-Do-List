from features.workload_forecast import workload_by_category, workload_level


def test_workload_by_category_excludes_completed():
    tasks = [
        {"category": "Study", "completed": 0},
        {"category": "Study", "completed": 1},
        {"category": "Work", "completed": 0},
    ]
    assert workload_by_category(tasks) == {"Study": 1, "Work": 1}


def test_workload_level_boundaries():
    assert workload_level(0) == "light"
    assert workload_level(5) == "moderate"
    assert workload_level(10) == "heavy"
    assert workload_level(20) == "critical"
