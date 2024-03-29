﻿#For hard-coding a path into our script.

# $path = "C:\path\to\folder\"

#For passing the path as an argument when running the script.
#Example: delete_older_than.ps1 -path "C:\path\to\folder\"

#param([string]$path)

#For passing multiple paths from a text file and passing the text file as an argument. 
#Second argument is age of files (defaults to 90).

param([string]$list, [Int32]$days=90)

#If statement tests if the path to our file exists (otherwise this would start deleting files in our CWD).

if (Test-Path -Path $list) {

    $paths = Get-Content -Path $list

    Get-ChildItem -Path $paths | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$days) } | Remove-Item

    exit 
}

else {
    Write-Host "Error - cannot find path $list."
    exit
}