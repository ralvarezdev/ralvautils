function Invoke-ProjectCleanup {
    [CmdletBinding()]
    param(
        [string[]]$Path = (Get-RalvaConfig -Key 'ProjectRoots')
    )

    if (-not $Path -or $Path.Count -eq 0) {
        throw "No project roots configured. Pass -Path or run: Set-RalvaConfig -Key ProjectRoots -Value @('C:\...')"
    }

    $escapedNames = $Script:DevFolderNames | ForEach-Object { [regex]::Escape($_) }
    $regex        = "^($($escapedNames -join '|'))$"
    $found        = [System.Collections.Generic.List[System.IO.FileSystemInfo]]::new()

    function Find-ProjectJunk ([string]$CurrentPath) {
        Get-ChildItem -Path $CurrentPath -Force -ErrorAction SilentlyContinue | ForEach-Object {
            if ($_.PSIsContainer) {
                if ($_.Name -match $regex) {
                    $found.Add($_)
                } elseif ($_.Name -notmatch '^(\.git|\.vscode|\.idea)$') {
                    Find-ProjectJunk $_.FullName
                }
            }
        }
    }

    Write-Host "Scanning for project junk..." -ForegroundColor Cyan
    foreach ($root in $Path) {
        if (Test-Path $root) { Find-ProjectJunk $root }
        else { Write-Warning "Root not found: $root" }
    }

    if ($found.Count -eq 0) {
        Write-Host "Clean! No junk folders found." -ForegroundColor Green
        return
    }

    Write-Host "Calculating sizes..." -ForegroundColor Gray
    $totalBytes = ($found | ForEach-Object {
        (Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue |
            Measure-Object -Property Length -Sum).Sum
    } | Measure-Object -Sum).Sum

    $totalGb = [Math]::Round($totalBytes / 1GB, 2)
    Write-Host "Found $($found.Count) folder(s) ($totalGb GB reclaimable)." -ForegroundColor Yellow

    $choice = Read-Host "Action: [L]ist, [D]elete, [C]ancel"
    switch ($choice.ToUpper()) {
        'L' {
            Write-Host "`nJunk folders:" -ForegroundColor Cyan
            $found.FullName | Sort-Object
        }
        'D' {
            $confirm = Read-Host "Type 'YES' to delete all $($found.Count) folders"
            if ($confirm -eq 'YES') {
                foreach ($item in $found) {
                    Write-Host "Removing: $($item.FullName)" -ForegroundColor Red
                    Remove-Item -Path $item.FullName -Recurse -Force -ErrorAction SilentlyContinue
                }
                Write-Host "Done." -ForegroundColor Green
            } else {
                Write-Host "Aborted." -ForegroundColor Cyan
            }
        }
        Default { Write-Host "Cancelled." -ForegroundColor Cyan }
    }
}
