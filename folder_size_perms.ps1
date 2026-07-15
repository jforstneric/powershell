param(
    [Parameter(Mandatory = $true)]
    [string]$RootPath,

    [string]$OutputFolder = "."
)

$ErrorActionPreference = "Continue"

if (-not (Test-Path -LiteralPath $RootPath -PathType Container)) {
    throw "Root path '$RootPath' does not exist or is not a directory."
}

$root = (Resolve-Path -LiteralPath $RootPath).Path.TrimEnd('\')
$sizeReport = Join-Path $OutputFolder "FolderSizes.csv"
$permissionReport = Join-Path $OutputFolder "FolderPermissions.csv"
$errorReport = Join-Path $OutputFolder "AuditErrors.csv"

$folderStats = @{}
$errors = New-Object System.Collections.Generic.List[object]

function Add-FolderIfMissing {
    param([string]$Path)

    if (-not $folderStats.ContainsKey($Path)) {
        $folderStats[$Path] = [PSCustomObject]@{
            FolderPath = $Path
            SizeBytes  = [int64]0
            SizeGB     = [double]0
            FileCount  = [int64]0
        }
    }
}

Add-FolderIfMissing -Path $root

Write-Host "Collecting folder list..."
try {
    Get-ChildItem -LiteralPath $root -Directory -Recurse -Force -ErrorAction Stop |
        ForEach-Object {
            Add-FolderIfMissing -Path $_.FullName
        }
}
catch {
    $errors.Add([PSCustomObject]@{
        Stage = "Folder enumeration"
        Path  = $root
        Error = $_.Exception.Message
    })
}

Write-Host "Calculating recursive folder sizes..."
# Get all files once and group by DirectoryName
$files = Get-ChildItem -LiteralPath $root -File -Recurse -Force -ErrorAction Stop

# Group files by their parent directory and calculate sizes
$fileGroups = $files | Group-Object DirectoryName

foreach ($group in $fileGroups) {
    $folderPath = $group.Name
    Add-FolderIfMissing -Path $folderPath
    $folderStats[$folderPath].SizeBytes += ($group.Group | Measure-Object -Property Length -Sum).Sum
    $folderStats[$folderPath].FileCount += $group.Count
}

$folderStats.Values |
    ForEach-Object {
        $_.SizeGB = [math]::Round($_.SizeBytes / 1GB, 3)
        $_
    } |
    Sort-Object FolderPath |
    Export-Csv -Path $sizeReport -NoTypeInformation -Encoding UTF8

Write-Host "Exporting permissions..."
$permissionRows = New-Object System.Collections.Generic.List[object]

foreach ($folder in ($folderStats.Keys | Sort-Object)) {
    try {
        $acl = Get-Acl -LiteralPath $folder

        foreach ($ace in $acl.Access) {
            $permissionRows.Add([PSCustomObject]@{
                FolderPath        = $folder
                Owner             = $acl.Owner
                Identity          = $ace.IdentityReference.Value
                AccessType        = $ace.AccessControlType
                Rights            = $ace.FileSystemRights
                IsInherited       = $ace.IsInherited
                InheritanceFlags  = $ace.InheritanceFlags
                PropagationFlags  = $ace.PropagationFlags
            })
        }
    }
    catch {
        $errors.Add([PSCustomObject]@{
            Stage = "ACL read"
            Path  = $folder
            Error = $_.Exception.Message
        })
    }
}

$permissionRows |
    Export-Csv -Path $permissionReport -NoTypeInformation -Encoding UTF8

$errors |
    Export-Csv -Path $errorReport -NoTypeInformation -Encoding UTF8

Write-Host "Done."
Write-Host "Folder size report: $sizeReport"
Write-Host "Permission report: $permissionReport"
Write-Host "Error report: $errorReport"