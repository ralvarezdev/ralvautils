function Protect-OneDriveFolders {
    param (
        [string]$Path
    )

    # List of target folders to ignore and stop traversing
    $DevFolderNames = @(
        # JavaScript / TypeScript / Bundlers
        "node_modules", ".turbo", ".next", ".nuxt", ".parsed-cache",
        ".eslintcache", ".prettiercache", ".pnpm-store", ".yarn",
        
        # Python & Environment Managers
        ".venv", "venv", "__pycache__", ".pytest_cache", 
        ".mypy_cache", ".ruff_cache", ".tox", ".pixi",
        
        # Go / Tooling / General CI
        ".golangci-lint", ".task"
    )

    # Get immediate subdirectories only
    $SubDirs = Get-ChildItem -Path $Path -Directory -ErrorAction SilentlyContinue

    foreach ($Dir in $SubDirs) {
        if ($DevFolderNames -contains $Dir.Name) {
            try {
                # 1. Apply the Unpinned attribute to the parent match
                Set-Content -Path $Dir.FullName -Value "Unpinned" -Stream "com.apple.subst" -ErrorAction Stop
                Write-Host "Successfully ignored & skipped traversing: $($Dir.FullName)" -ForegroundColor Green
            } catch {
                Write-Host "Failed to modify: $($Dir.FullName)" -ForegroundColor Yellow
            }
            # 2. CRITICAL: We DO NOT call the function recursively here. 
            # It marks the folder and moves to the next sibling folder.
        } else {
            # It's a normal folder, keep searching deeper
            Protect-OneDriveFolders -Path $Dir.FullName
        }
    }
}

# Resolve the starting OneDrive path safely for PowerShell 5.1
$OneDrivePath = if ($env:OneDrive) { $env:OneDrive } else { "$env:USERPROFILE\OneDrive" }

Write-Host "Starting optimized scan on: $OneDrivePath" -ForegroundColor Cyan
Protect-OneDriveFolders -Path $OneDrivePath