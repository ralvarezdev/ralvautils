function Repair-OneDriveSyncConflicts {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$Path   = (Get-OneDrivePath),
        [string]$Suffix = (Get-RalvaConfig -Key 'LaptopSuffix')
    )

    if (-not $Suffix) {
        throw "LaptopSuffix not configured. Run: Set-RalvaConfig -Key LaptopSuffix -Value '-LAPTOP-YOURNAME'"
    }

    if (-not (Test-Path $Path)) {
        throw "Path not found: $Path"
    }

    $escapedSuffix = [regex]::Escape($Suffix)
    $pattern       = "(?<Prefix>.*)$escapedSuffix(?<Extension>\.[^.]+|$)$"

    function Repair-FilesWorker ([string]$CurrentPath) {
        Get-ChildItem -Path $CurrentPath -File -ErrorAction SilentlyContinue | ForEach-Object {
            if ($_.Name -match $pattern) {
                $originalName     = $Matches['Prefix'] + $Matches['Extension']
                $originalFullPath = Join-Path $CurrentPath $originalName

                if (Test-Path $originalFullPath) {
                    if ($PSCmdlet.ShouldProcess($originalFullPath, 'Remove cloud original and rename laptop copy')) {
                        Remove-Item -Path $originalFullPath -Force -ErrorAction Stop
                        Rename-Item -Path $_.FullName -NewName $originalName -Force -ErrorAction Stop
                        Write-Host "[FIXED] $originalName" -ForegroundColor Green
                    } else {
                        Write-Host "[DRY-RUN] Would remove: $originalFullPath" -ForegroundColor Yellow
                        Write-Host "[DRY-RUN] Would rename: $($_.Name) -> $originalName" -ForegroundColor DarkGreen
                    }
                } else {
                    if ($PSCmdlet.ShouldProcess($_.FullName, 'Rename orphan laptop copy')) {
                        Rename-Item -Path $_.FullName -NewName $originalName -Force -ErrorAction Stop
                        Write-Host "[ORPHAN FIXED] $originalName" -ForegroundColor Cyan
                    } else {
                        Write-Host "[DRY-RUN] Would rename orphan: $($_.Name) -> $originalName" -ForegroundColor DarkCyan
                    }
                }
            }
        }

        Get-ChildItem -Path $CurrentPath -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -ne '.git' } |
            ForEach-Object { Repair-FilesWorker $_.FullName }
    }

    Write-Host "Scanning $Path for conflict pairs (suffix: $Suffix)..." -ForegroundColor Cyan
    Repair-FilesWorker $Path
    Write-Host "Done." -ForegroundColor Green
}
