function Get-FilesModifiedToday {
    [CmdletBinding()]
    param(
        [string]$Path = (Get-OneDrivePath)
    )

    if (-not (Test-Path $Path)) {
        throw "Path not found: $Path"
    }

    $today = (Get-Date).Date

    function Search-Path ([string]$CurrentPath) {
        Get-ChildItem -Path $CurrentPath -File -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime.Date -eq $today }

        Get-ChildItem -Path $CurrentPath -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            if ($_.LastWriteTime.Date -eq $today) {
                Write-Host "`n[!] Folder modified today: $($_.FullName)" -ForegroundColor Cyan
                $choices = [System.Management.Automation.Host.ChoiceDescription[]] @(
                    [System.Management.Automation.Host.ChoiceDescription]::new('&Yes', 'Recurse into this folder'),
                    [System.Management.Automation.Host.ChoiceDescription]::new('&No',  'Skip this folder')
                )
                $decision = $Host.UI.PromptForChoice('Traverse folder?', $_.FullName, $choices, 1)
                $_
                if ($decision -eq 0) { Search-Path $_.FullName }
                else                 { Write-Host "--> Skipped: $($_.FullName)" -ForegroundColor Yellow }
            } else {
                Search-Path $_.FullName
            }
        }
    }

    Search-Path $Path
}
