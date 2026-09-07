import json


def to_json(tasks):
    return json.dumps(list(tasks), ensure_ascii=False, indent=2, default=str)


def from_json(value):
    data = json.loads(value)
    if not isinstance(data, list):
        raise ValueError("task payload must be a list")
    return data
