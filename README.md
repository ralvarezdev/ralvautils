# ralvautils

My personal CLI utilities: PowerShell scripts (mostly Windows, OneDrive, git and dev-folder housekeeping) and a `RalvaUtils` PowerShell module that centralises them.

**Note:** These are personal tools. Several loose scripts contain machine-specific values (paths, drive names, a laptop-name suffix) and are meant to be read and adapted, not run blindly. Many delete files, so review a script before running it. There is no LICENSE file.

---

## Project structure

```
RalvaUtils/                    PowerShell module (psd1, psm1, Public/, Private/)
*.ps1                          Original standalone scripts
Taskfile.yml                   Task shortcuts for loading/configuring the module
docs/CENTRALIZATION-PLAN.md    Plan for moving the loose scripts into the module
```

Per the plan, the scripts are being turned into module functions.

## The RalvaUtils module

Version 0.1.0, requires PowerShell 7.0+. Importing it loads `Private/` and `Public/**`, then user config from `~/.ralvautils/config.json` if present.

```powershell
Import-Module ./RalvaUtils -Force
Get-Command -Module RalvaUtils
```

- **Config** — `Get-RalvaConfig`, `Set-RalvaConfig` (keys `LaptopSuffix`, `ProjectRoots`)
- **Git** — `Set-GitCommitDate`
- **OneDrive** — `Protect-OneDriveFolders`, `Repair-OneDriveGitConflicts`, `Repair-OneDriveSyncConflicts`, `Remove-OneDriveDevCache`
- **Dev cache** — `Remove-LocalDevCache`, `Invoke-ProjectCleanup`
- **Files** — `Test-KebabCase`, `Get-FilesModifiedToday`, `Export-LaptopSuffixReport`, `Export-RecentFilesReport`, `Remove-NullFiles`

Parameters are documented only through `Get-Help <function> -Full`.

## Task shortcuts

[Task](https://taskfile.dev) targets in `Taskfile.yml`, which call `pwsh`:

- **`task init`** — Import the module to confirm it loads.
- **`task setup-profile`** — Append an `Import-Module` line to your PowerShell profile.
- **`task test`** — Import the module and list its commands.
- **`task config-laptop-suffix -- <suffix>`** — Set `LaptopSuffix`.
- **`task config-project-roots -- 'C:\a;C:\b'`** — Set `ProjectRoots` (semicolon-separated).

## Loose scripts

- **Cleanup** — `cache-cleanup.ps1`, `delete-dev-cache-from-local.ps1`, `delete-dev-cache-from-onedrive.ps1`, `nul-removal.ps1`, `project-cleanup.ps1` (defines `Invoke-ProjectCleanup`; it does not invoke itself)
- **OneDrive and git conflicts** — `fix-onedrive-git-mess.ps1`, `onedrive-remove-cloud-conflicts.ps1`, `ignore-dev-by-onedrive.ps1`, `reset-onedrive.ps1`
- **File reports** — `check-kebab-case.ps1`, `get-files-modified-today.ps1`, `log-files-laptop-suffix.ps1`, `log-modified-and-created-today-and-yesterday.ps1`
- **Git** — `git-compact.ps1`, `git-modify-committed-date.ps1`, `git-remote-fetch.ps1`
- **System** — `compact-docker-disk.ps1` (`diskpart` to compact a Docker Desktop WSL disk), `debloat-windows.ps1` (registry tweaks to disable telemetry/AI features), `link-games.ps1`, `mount-ehdd.ps1`
