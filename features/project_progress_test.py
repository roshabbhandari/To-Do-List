from features.project_progress import project_progress


def test_project_progress_is_case_insensitive():
    tasks = [
        {"category": "Study", "completed": 1, "priority": "High"},
        {"category": "study", "completed": 0, "priority": "Medium"},
        {"category": "Work", "completed": 0, "priority": "High"},
    ]
    result = project_progress(tasks, "STUDY")
    assert result["total"] == 2
    assert result["completed"] == 1
    assert result["completion_rate"] == 50.0
    assert result["pending_priorities"] == {"Medium": 1}


def test_empty_project():
    result = project_progress([], "Study")
    assert result["completion_rate"] == 0.0
