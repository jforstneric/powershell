# Logs into a specified Azure subscription and exports all Virtual Machines and Storage
# Accounts located in the regions listed below to an XLSX file in the current working directory.
#
# Usage: .\azure_resources_by_region.ps1 -Subscription "MySubscriptionNameOrId"
#
# Requires the Az PowerShell modules. ImportExcel is used to write the XLSX (no Excel
# installation needed) and is installed automatically if missing.

param(
    [Parameter(Mandatory = $true)]
    [string]$Subscription
)

# Regions to check (hard-coded).
$regions = @(
    "North Europe"
    "France Central"
    "France South"
    "West Europe"
    "Norway East"
    "Norway West"
    "Southeast Asia"
)

# Azure returns locations as lower-case names without spaces, e.g. "northeurope".
$regionNames = $regions | ForEach-Object { ($_ -replace '\s', '').ToLower() }

if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
    Install-Module -Name ImportExcel -Scope CurrentUser -Force
}
Import-Module -Name ImportExcel

Connect-AzAccount
Set-AzContext -Subscription $Subscription

$resources = New-Object System.Collections.Generic.List[object]

Write-Host "Collecting virtual machines..."
Get-AzVM |
    Where-Object { $regionNames -contains (($_.Location -replace '\s', '').ToLower()) } |
    ForEach-Object {
        $resources.Add([PSCustomObject]@{
            ResourceType  = "Virtual Machine"
            Name          = $_.Name
            ResourceGroup = $_.ResourceGroupName
            Region        = $_.Location
            ResourceId    = $_.Id
        })
    }

Write-Host "Collecting storage accounts..."
Get-AzStorageAccount |
    Where-Object { $regionNames -contains (($_.Location -replace '\s', '').ToLower()) } |
    ForEach-Object {
        $resources.Add([PSCustomObject]@{
            ResourceType  = "Storage Account"
            Name          = $_.StorageAccountName
            ResourceGroup = $_.ResourceGroupName
            Region        = $_.Location
            ResourceId    = $_.Id
        })
    }

Write-Host "Found $($resources.Count) resources in the specified regions."

if ($resources.Count -gt 0) {
    $excelPath = Join-Path -Path (Get-Location) -ChildPath ("AzureResources_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".xlsx")

    $resources |
        Sort-Object -Property Region, ResourceGroup, Name |
        Export-Excel -Path $excelPath -WorksheetName "Resources" -AutoSize -FreezeTopRow

    Write-Host "XLSX export saved to: $excelPath"
}
else {
    Write-Host "No resources found in the specified regions, no XLSX created."
}
