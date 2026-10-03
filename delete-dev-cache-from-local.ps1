# 1. Define target folder names for permanent deletion
$DevFolderNames = @(
    # JavaScript / TypeScript / Bundlers
    "node_modules", ".turbo", ".next", ".nuxt", ".parsed-cache",
    ".eslintcache", ".prettiercache", ".pnpm-store", ".yarn", # Fixed leading space in .eslintcache

    # Python & Environment Managers
    ".venv", "venv", "__pycache__", ".pytest_cache", 
    ".mypy_cache", ".ruff_cache", ".tox", ".pixi",

    # Go / Tooling / General CI
    ".golangci-lint", ".task"
)

# 2. Assign the StartPath to the Current Working Directory (CWD)
$StartPath = $PWD.Path

Write-Host "Scanning CWD: $StartPath for heavy dev dependencies to permanently remove..." -ForegroundColor Cyan

# 3. Find and delete the folders
# Note: -Depth limits recursion slightly if needed, but -Recurse works perfectly here.
Get-ChildItem -Path $StartPath -Directory -Recurse -ErrorAction SilentlyContinue | 
    Where-Object { 
        # Match the folder name AND ensure we aren't accidentally trying to delete the root CWD itself
        $DevFolderNames -contains $_.Name -and $_.FullName -ne $StartPath 
    } | 
    ForEach-Object {
        Write-Host "Permanently deleting: $($_.FullName)" -ForegroundColor Red
        # Using -LiteralPath is safer to handle folders that might contain wildcards like `[` or `]`
        Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
    }