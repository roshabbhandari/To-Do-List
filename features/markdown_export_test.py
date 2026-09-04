from features.markdown_export import tasks_to_markdown


def test_tasks_to_markdown_renders_status_priority_and_due_date():
    tasks = [{"completed": 1, "title": "Study", "priority": "High", "due_date": "2026-09-04"}]
    text = tasks_to_markdown(tasks, "Today")
    assert text == "# Today\n\n- [x] **Study** (High) — due 2026-09-04\n"


def test_tasks_to_markdown_uses_safe_defaults():
    assert "Untitled" in tasks_to_markdown([{}])
