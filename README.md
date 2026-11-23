# Powershell
A small repo for various Powershell utility scripts.

### Scripts:

##### delete_older_than.ps1:
Used to delete files older than X days from folders specified in paths.txt. For safety, it first checks that paths.txt exists (otherwise it would start deleting files in the current working directory which could have bad consequences).

##### folder_size_perms.ps1:
Script to go calculate folder sizes + permissions for all folders on a specified Windows drive.  
Run with: "Z:\" -OutputFolder "C:\Temp\AzureFileShareAudit", note that you have to create the Output Folder manually beforehand.

##### azure_resources_by_region.ps1:
Logs into a specified Azure subscription and exports all Virtual Machines and Storage Accounts located in the hard-coded regions (North Europe, France Central, France South, West Europe, Norway East, Norway West, Southeast Asia) to an XLSX file in the current working directory. The XLSX lists each resource's name, resource group, region and resource ID.
Run with: .\azure_resources_by_region.ps1 -Subscription "MySubscriptionNameOrId". Requires the Az modules; ImportExcel (used for the XLSX export) is installed automatically if missing.
