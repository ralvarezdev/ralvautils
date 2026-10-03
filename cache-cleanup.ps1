# 1. Standard Package Manager Garbage Collection
uv cache clean
go clean -cache -modcache
pip cache purge
winget clean
pnpm store prune

# 2. Targeted Developer Cache Folder Cleanses
# Clears heavy package targets while preserving root configurations
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\rattler\cache"
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\pixi\cache"
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\pnpm-cache"
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\npm-cache"

# 3. Clean Zed Specifics Safely (Preserving threads.db)
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\Zed\cache\languages"
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\Zed\node\cache"
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\Zed\logs\*"

# 4. Wipe Entire Updater Leftovers & System Crash Trash
$NukeList = @(
    "CrashDumps", "D3DSCache", "SquirrelTemp", "Downloaded Installations", "Package Cache",
    "@lineardesktop-updater", "arduino-ide-updater", "binance-updater", "bruno-updater", 
    "canva-updater", "mqtt-explorer-updater", "neo4j-desktop-updater", 
    "open-plc-editor-updater", "podman-desktop-updater", "vortex-updater"
)

foreach ($folder in $NukeList) {
    if (Test-Path "$env:LOCALAPPDATA\$folder") {
        Remove-Item -Recurse -Force "$env:LOCALAPPDATA\$folder" -ErrorAction SilentlyContinue
    }
}

# 5. Flush Global Windows Temp Environment
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\Temp\*" -ErrorAction SilentlyContinue