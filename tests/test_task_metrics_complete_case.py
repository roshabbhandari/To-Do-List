from task_metrics import completion_rate


def test_completion_rate_returns_full_percentage_for_completed_tasks():
    assert completion_rate([{"completed": True}, {"completed": True}]) == 100.0
