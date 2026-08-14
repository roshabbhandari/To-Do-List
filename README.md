# Roshab Tasks 🚀

A modern desktop productivity and task-management application built with **Python, Tkinter and SQLite**.

Developed by **Roshab Bhandari**.

## ✨ Features

- Modern dark-first desktop UI
- Light / dark theme toggle
- SQLite persistent local database
- Add, edit and delete tasks
- Task descriptions and tags
- Categories: Personal, Work, Study, Shopping, Health and Project
- Low / Medium / High priority
- Due dates
- Scheduled alarm reminders
- Desktop reminder dialog and Windows alert sound
- Pending / Completed filtering
- Category and priority filtering
- Favorites
- Advanced search across title, description and tags
- Sorting by creation date, due date, priority or title
- Multi-select tasks
- Bulk complete and bulk delete
- Completion, overdue and alarm statistics
- CSV export and import
- Keyboard shortcuts
- No cloud account required

## ⏰ Alarm Reminders

Create a task and enable the **⏰ alarm** option.

Use this format for the reminder time:

```text
YYYY-MM-DD HH:MM
```

Example:

```text
2026-08-14 18:30
```

The app checks reminders every 10 seconds while it is running. When a reminder becomes due, Roshab Tasks shows a desktop alert and uses the system alert sound when available.

For Windows, the application uses the built-in `winsound` module. On other platforms, the popup still works and the normal Tk window bell is used.

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

The application automatically creates or upgrades `taskflow.db` in the project directory. Existing task data is preserved when reminder columns are added.

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `Ctrl + N` | Focus new task input |
| `Ctrl + F` | Focus search |
| `Delete` | Delete selected tasks |
| `Ctrl + E` | Export CSV |
| Double-click | Edit task |

## 📁 Project Structure

```text
To-Do-List/
├── todo.py          # Application launcher
├── app.py           # Main GUI and task/reminder logic
├── database.py      # SQLite database and reminder queries
├── README.md
├── LICENSE
└── taskflow.db      # Created automatically at runtime
```

## 🔒 Privacy

Task data is stored locally in SQLite. This project does not send your tasks to a remote server.

## 📌 Roadmap

- [x] Modern dark productivity UI
- [x] Persistent task reminders
- [x] Alarm statistics
- [ ] Recurring tasks
- [ ] Calendar view
- [ ] Productivity charts
- [ ] Automatic database backup
- [ ] Multiple projects/workspaces
- [ ] Optional packaged Android/mobile version

## License

MIT License
