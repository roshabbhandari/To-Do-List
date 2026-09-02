import json
from pathlib import Path


def save_template(path, template):
    data = dict(template)
    if not str(data.get("title", "")).strip():
        raise ValueError("template title is required")
    Path(path).write_text(json.dumps(data, indent=2), encoding="utf-8")
    return Path(path)


def load_template(path):
    data = json.loads(Path(path).read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError("template must be a JSON object")
    return data


def instantiate(template, **overrides):
    result = dict(template)
    result.update({k: v for k, v in overrides.items() if v is not None})
    return result
