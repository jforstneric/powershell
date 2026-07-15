# Powershell
A small repo for various Powershell utility scripts.

### Scripts:

##### delete_older_than.ps1:
Used to delete files older than X days from folders specified in paths.txt. For safety, it first checks that paths.txt exists (otherwise it would start deleting files in the current working directory which could have bad consequences).

##### folder_size_perms.ps1:
Script to go calculate folder sizes + permissions for all folders on a specified Windows drive.  
Run with: "Z:\" -OutputFolder "C:\Temp\AzureFileShareAudit", note that you have to create the Output Folder manually beforehand.
