import csv
import io


def to_csv(tasks):
    fields = ["id", "title", "category", "priority", "due_date", "completed"]
    out = io.StringIO()
    writer = csv.DictWriter(out, fieldnames=fields, extrasaction="ignore")
    writer.writeheader()
    writer.writerows(tasks)
    return out.getvalue()
