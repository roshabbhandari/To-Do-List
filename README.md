# TaskFlow — Python To-Do List

A clean desktop To-Do List application built with Python and Tkinter.

## Features

- Add tasks
- Edit tasks
- Mark tasks as completed
- Delete tasks
- Search tasks
- Filter by status and priority
- Low / Medium / High priority
- Optional due dates
- Task statistics
- Automatic JSON data storage
- Dark desktop UI
- Keyboard shortcuts

## Requirements

Python 3.x with Tkinter support.

No external Python packages are required.

## Run

```bash
python todo.py
```

The application automatically creates `tasks.json` when tasks are saved.

## Keyboard Shortcuts

- `Ctrl + N` — Focus the new-task field
- `Enter` — Add a task
- `Delete` — Delete the selected task
- `Ctrl + S` — Save tasks
- Double-click a task — Toggle completed status

## Project Structure

```text
To-Do-List/
├── todo.py
├── README.md
└── tasks.json   # created automatically when the app runs
```

## License

MIT License
