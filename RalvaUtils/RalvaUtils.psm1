#Requires -Version 7.0

$Script:Config = @{
    LaptopSuffix = $null
    ProjectRoots = @()
}

$Script:ConfigPath = Join-Path $env:USERPROFILE '.ralvautils' 'config.json'

Get-ChildItem "$PSScriptRoot\Private" -Filter '*.ps1' |
    ForEach-Object { . $_.FullName }

Get-ChildItem "$PSScriptRoot\Public" -Filter '*.ps1' -Recurse |
    ForEach-Object { . $_.FullName }

if (Test-Path $Script:ConfigPath) {
    $loaded = Get-Content $Script:ConfigPath -Raw | ConvertFrom-Json -AsHashtable
    foreach ($key in $loaded.Keys) { $Script:Config[$key] = $loaded[$key] }
}
