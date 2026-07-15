param(
    [Parameter(Mandatory = $true)]
    [string]$RootPath,

    [string]$OutputFolder = "."
)

$ErrorActionPreference = "Continue"

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
Get-ChildItem -LiteralPath $root -File -Recurse -Force -ErrorAction SilentlyContinue |
    ForEach-Object {
        $file = $_
        $parent = $file.DirectoryName

        while ($parent -and $parent.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
            Add-FolderIfMissing -Path $parent
            $folderStats[$parent].SizeBytes += $file.Length
            $folderStats[$parent].FileCount += 1

            if ($parent -ieq $root) {
                break
            }

            $parent = Split-Path -Path $parent -Parent
        }
    }

$folderStats.Values |
    ForEach-Object {
        $_.SizeGB = [math]:: / 1GB, 3)
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