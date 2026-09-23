# Local Backup Guide

Because task and student data are stored locally, backups should include the SQLite database used by the application.

## Simple backup

Close the application and copy the database file to a separate folder or external drive.

## Safer routine

Keep more than one backup generation so a damaged or accidentally changed database does not replace the only good copy.

## Before upgrades

Create a backup before changing the application version or applying database migrations. If a migration is interrupted, the previous database copy provides a recovery point.

## Restore

Close the application, replace the working database with a known-good backup, and start the application again.

Do not commit personal task data or real student records to the public Git repository.