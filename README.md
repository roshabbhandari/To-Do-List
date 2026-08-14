# Roshab Tasks 🚀

A modern desktop productivity and student-management application built with **Python, Tkinter and SQLite**.

Developed by **Roshab Bhandari**.

## ✨ Main Features

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

## 🎓 Student Hub

`student_hub.py` adds a dedicated student workspace using the same local SQLite database.

### Focus & Study

- Pomodoro focus timer
- Study, short-break and long-break modes
- Daily study goals
- Focus session completion alerts

### Academic Tools

- GPA calculator (4.0 scale)
- Attendance percentage calculator
- Exam countdown with days remaining
- Saved exam schedule

### Notes & Planning

- Quick study notes
- Local note storage
- Weekly class timetable
- Subject, time and room planner

Run the Student Hub with:

```bash
python student_hub.py
```

## ⏰ Alarm Reminders

Create a task and enable the **⏰ alarm** option.

Use this format:

```text
YYYY-MM-DD HH:MM
```

Example:

```text
2026-08-14 18:30
```

Roshab Tasks checks reminders while the app is running. When a reminder becomes due, it shows a desktop alert and uses the system alert sound when available.

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

The application automatically creates or upgrades `taskflow.db`. Existing task data is preserved when reminder columns are added.

For the student workspace:

```bash
python student_hub.py
```

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
├── student_hub.py   # Student study, academic and planning tools
├── README.md
├── LICENSE
└── taskflow.db      # Created automatically at runtime
```

## 🔒 Privacy

Task, notes, goals, exams and timetable data are stored locally in SQLite. This project does not send student data to a remote server.

## 📌 Roadmap

- [x] Modern dark productivity UI
- [x] Persistent task reminders
- [x] Alarm statistics
- [x] Student focus timer
- [x] GPA calculator
- [x] Attendance calculator
- [x] Exam countdown
- [x] Student notes
- [x] Weekly timetable
- [ ] Recurring tasks
- [ ] Calendar view
- [ ] Productivity charts
- [ ] Automatic database backup
- [ ] Multiple projects/workspaces
- [ ] Packaged Android/mobile version
- [ ] Packaged iOS/mobile version

## License

MIT License
