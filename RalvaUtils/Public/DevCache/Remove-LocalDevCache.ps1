function Remove-LocalDevCache {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string[]]$Path = @($PWD.Path)
    )

    $escapedNames = $Script:DevFolderNames | ForEach-Object { [regex]::Escape($_) }
    $regex        = "^($($escapedNames -join '|'))$"
    $found        = [System.Collections.Generic.List[System.IO.DirectoryInfo]]::new()

    function Find-DevFolders ([string]$CurrentPath) {
        Get-ChildItem -Path $CurrentPath -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
            if ($_.Name -match $regex) {
                $found.Add([System.IO.DirectoryInfo]$_.FullName)
            } elseif ($_.Name -notmatch '^(\.git|\.vscode|\.idea)$') {
                Find-DevFolders $_.FullName
            }
        }
    }

    foreach ($root in $Path) {
        if (-not (Test-Path $root)) { Write-Warning "Path not found: $root"; continue }
        Write-Host "Scanning $root..." -ForegroundColor Cyan
        Find-DevFolders $root
    }

    if ($found.Count -eq 0) {
        Write-Host "No dev cache folders found." -ForegroundColor Green
        return
    }

    Write-Host "Found $($found.Count) folder(s)." -ForegroundColor Yellow

    foreach ($item in $found) {
        if ($PSCmdlet.ShouldProcess($item.FullName, 'Remove-Item -Recurse -Force')) {
            Write-Host "Removing: $($item.FullName)" -ForegroundColor Red
            Remove-Item -Path $item.FullName -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
