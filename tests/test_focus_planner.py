from features.focus_planner import FocusBlock, build_focus_plan


def test_focus_plan_inserts_breaks():
    tasks = [{"title": "A", "completed": False}, {"title": "B", "completed": False}]
    plan = build_focus_plan(tasks)
    assert plan == [FocusBlock("A", 25), FocusBlock("Break", 5), FocusBlock("B", 25)]


def test_focus_plan_skips_completed():
    tasks = [{"title": "Done", "completed": True}, {"title": "Next", "completed": False}]
    plan = build_focus_plan(tasks)
    assert plan[0] == FocusBlock("Next", 25)
