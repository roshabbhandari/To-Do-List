from task_metrics import completion_rate


def test_completion_rate_handles_empty_and_mixed_tasks():
    assert completion_rate([]) == 0.0
    assert completion_rate([{"completed": True}, {"completed": False}, {}]) == 33.33
