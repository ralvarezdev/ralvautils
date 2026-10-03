function Get-RalvaConfig {
    [CmdletBinding()]
    param(
        [string]$Key
    )
    if ($Key) { return $Script:Config[$Key] }
    return $Script:Config
}

function Set-RalvaConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Key,
        [Parameter(Mandatory)][object]$Value
    )
    $Script:Config[$Key] = $Value
    $dir = Split-Path $Script:ConfigPath
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $Script:Config | ConvertTo-Json | Set-Content -Path $Script:ConfigPath -Encoding utf8
    Write-Host "Config saved: $Key = $Value" -ForegroundColor Green
}
