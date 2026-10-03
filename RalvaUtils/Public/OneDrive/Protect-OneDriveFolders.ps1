function Protect-OneDriveFolders {
    [CmdletBinding()]
    param(
        [string]$Path = (Get-OneDrivePath)
    )

    function Invoke-FolderProtection ([string]$CurrentPath) {
        Get-ChildItem -Path $CurrentPath -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            if ($Script:DevFolderNames -contains $_.Name) {
                try {
                    Set-Content -Path $_.FullName -Value 'Unpinned' -Stream 'com.apple.subst' -ErrorAction Stop
                    Write-Host "Ignored: $($_.FullName)" -ForegroundColor Green
                } catch {
                    Write-Host "Failed: $($_.FullName)" -ForegroundColor Yellow
                }
            } else {
                Invoke-FolderProtection $_.FullName
            }
        }
    }

    Write-Host "Scanning $Path for dev folders to unpin from OneDrive..." -ForegroundColor Cyan
    Invoke-FolderProtection $Path
    Write-Host "Done." -ForegroundColor Green
}
