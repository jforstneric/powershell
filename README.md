# Powershell
A small repo for various Powershell utility scripts.

### Scripts:

##### delete_older_than.ps1:
Used to delete files older than X days from folders specified in paths.txt. For safety, it first checks that paths.txt exists (otherwise it would start deleting files in the current working directory which could have bad consequences).
