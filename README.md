# TaskFlow Pro 🚀

An advanced desktop productivity and task-management application built with **Python, Tkinter and SQLite**.

## ✨ Features

- Modern desktop UI
- SQLite persistent database
- Add, edit and delete tasks
- Task descriptions
- Categories: Personal, Work, Study, Shopping, Health and Project
- Tags
- Low / Medium / High priority
- Due dates
- Pending / Completed filtering
- Category and priority filtering
- Favorites
- Advanced search across title, description and tags
- Sorting by date, due date, priority or title
- Multi-select tasks
- Bulk complete and bulk delete
- Completion statistics
- Overdue task counter
- Dark / light theme toggle
- CSV export
- CSV import
- Keyboard shortcuts
- Local database — no cloud account required

## 🛠️ Tech Stack

- Python 3
- Tkinter / ttk
- SQLite
- CSV module
- Standard library only

## ▶️ Run

Make sure Python 3 with Tkinter is installed, then run:

```bash
python todo.py
```

The application automatically creates `taskflow.db` in the project directory.

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `Ctrl + N` | New task |
| `Ctrl + F` | Focus search |
| `Delete` | Delete selected tasks |
| `Ctrl + E` | Export CSV |
| Double-click | Edit task |

## 📁 Project Structure

```text
To-Do-List/
├── todo.py          # Application launcher
├── app.py           # Main GUI and application logic
├── database.py      # SQLite database layer
├── README.md
├── LICENSE
└── taskflow.db      # Created automatically at runtime
```

## 🔒 Privacy

Task data is stored locally in SQLite. This project does not send your tasks to a remote server.

## 📌 Roadmap

- [ ] Recurring tasks
- [ ] Better desktop notifications
- [ ] Calendar view
- [ ] Productivity charts
- [ ] Automatic database backup
- [ ] Multiple projects/workspaces
- [ ] Drag-and-drop task ordering

## License

MIT License
