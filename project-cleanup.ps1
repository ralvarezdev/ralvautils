function Invoke-ProjectCleanup {
    <#
    .SYNOPSIS
        Scans specific project roots for programming caches and build artifacts.
        Optimized to prune search branches once a match is found.
    #>
    $myProjectRoots = @(
        "$HOME\OneDrive\Documents\private\projects",
        "$HOME\OneDrive\Documents\private\education",
        "$HOME\PyCharmMiscProject"
    )

    # The list of specific folder names to target
    $junkNames = @(
        'node_modules', 'dist', 'target', 'build', '_build', 'envs', '.pixi',
        '.venv', 'venv', 'pycache', 'pycache', '.pytest_cache', '.ruff_cache',
        '.next', '.turbo', '.nuxt', '.parcel-cache', '.cache', '.gradle',
        'obj', 'bin', 'cmake-build-debug', 'cmake-build-release', '.vs', 'ipch', '.tlog'
    )
    
    # Properly escape dots and join names into a regex string
    $escapedNames = $junkNames | ForEach-Object { [regex]::Escape($_) }
    $regex = "^($($escapedNames -join '|'))$"

    $foundItems = New-Object System.Collections.Generic.List[PSObject]

    # Recursive function with pruning logic
    function Get-ProjectJunk {
        param([string]$CurrentPath)
        $items = Get-ChildItem -Path $CurrentPath -Force -ErrorAction SilentlyContinue
        
        foreach ($item in $items) {
            if ($item.PSIsContainer) {
                if ($item.Name -match $regex) {
                    # MATCH: This is a junk folder. Add it and STOP looking inside it.
                    $foundItems.Add($item)
                } else {
                    # NO MATCH: Only recurse if it's not a hidden system/git folder
                    if ($item.Name -notmatch '^(\.git|\.vscode|\.idea)$') {
                        Get-ProjectJunk -CurrentPath $item.FullName
                    }
                }
            }
        }
    }

    Write-Host "Scanning for project junk..." -ForegroundColor Cyan
    foreach ($root in $myProjectRoots) {
        if (Test-Path $root) { Get-ProjectJunk -CurrentPath $root }
    }

    if ($foundItems.Count -eq 0) {
        Write-Host "No cache folders found. Your workspace is clean!" -ForegroundColor Green
        return
    }

    # Calculate total reclaimable size
    $totalSize = 0
    Write-Host "Calculating sizes (this may take a moment)..." -ForegroundColor Gray
    foreach($item in $foundItems) {
        $size = (Get-ChildItem $item.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        if ($size) { $totalSize += $size }
    }

    Write-Host "`nFound $($foundItems.Count) junk folders ($([Math]::Round($totalSize / 1GB, 2)) GB reclaimable)." -ForegroundColor Yellow
    $choice = Read-Host "Choose an action: [L]ist All, [D]elete All, [C]ancel"

    switch ($choice.ToUpper()) {
        "L" { 
            Write-Host "`n--- Junk Folders Found ---" -ForegroundColor Cyan
            $foundItems.FullName | Sort-Object 
        }
        "D" {
            $confirm = Read-Host "ARE YOU SURE? This deletes ALL $($foundItems.Count) folders (Type 'YES' to confirm)"
            if ($confirm -eq "YES") {
                foreach ($item in $foundItems) {
                    Write-Host "Removing: $($item.FullName)" -ForegroundColor Red
                    Remove-Item -Path $item.FullName -Recurse -Force -ErrorAction SilentlyContinue
                }
                Write-Host "Cleanup Complete!" -ForegroundColor Green
            } else {
                Write-Host "Aborted." -ForegroundColor Cyan
            }
        }
        Default { Write-Host "Operation cancelled." -ForegroundColor Cyan }
    }
}