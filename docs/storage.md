# Local Storage

Roshab Tasks stores application data in a local SQLite database.

## Stored data

The database can contain task fields, descriptions, tags, categories, priorities, due dates, reminder settings, and student-focused records such as notes, exams, goals, and timetable entries.

## Privacy model

The application is designed for local use. Keeping the database on the user's machine means task and study data do not need a cloud account or remote synchronization service.

## Schema changes

When adding a new column or table:

1. Keep existing data readable.
2. Provide a safe migration or upgrade path.
3. Use sensible defaults for older records.
4. Verify both fresh and existing databases.

The database file is runtime state, not source code, and should be treated separately from the application modules.