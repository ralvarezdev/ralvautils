function Repair-OneDriveGitConflicts {
    [CmdletBinding()]
    param(
        [string]$Path = '.',
        [string]$Suffix = (Get-RalvaConfig -Key 'LaptopSuffix')
    )

    if (-not $Suffix) {
        throw "LaptopSuffix not configured. Run: Set-RalvaConfig -Key LaptopSuffix -Value '-LAPTOP-YOURNAME'"
    }

    $gitPath = Join-Path $Path '.git'
    if (-not (Test-Path $gitPath)) {
        throw "No .git directory found at: $Path"
    }

    $suffixedFiles = Get-ChildItem -Path $gitPath -Filter "*$Suffix*" -Recurse -Force
    if (-not $suffixedFiles) {
        Write-Host "No conflicting files found with suffix '$Suffix'." -ForegroundColor Green
        return
    }

    foreach ($file in $suffixedFiles) {
        $originalName = $file.Name -replace [regex]::Escape($Suffix), ''
        $originalPath = Join-Path $file.DirectoryName $originalName

        if (Test-Path $originalPath) {
            Move-Item -Path $originalPath -Destination "$originalPath.bak" -Force -ErrorAction SilentlyContinue
            Write-Host "Backed up: $originalName -> $originalName.bak" -ForegroundColor Yellow
        }

        Move-Item -Path $file.FullName -Destination $originalPath -Force
        Write-Host "Replaced: $originalName" -ForegroundColor Green
    }
}
