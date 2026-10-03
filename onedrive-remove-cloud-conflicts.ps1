function Repair-OneDriveSyncConflicts {
    param (
        # Target your active synced OneDrive directory
        [string]$Path = $(if ($env:OneDrive) { $env:OneDrive } else { "$env:USERPROFILE\OneDrive" }),
        # HARD GUARD: Set to $false to actually execute deletions and renames
        [bool]$DryRun = $true
    )

    if (-not (Test-Path -Path $Path)) {
        Write-Error "Could not locate target folder at: $Path"
        return
    }

    if ($DryRun) {
        Write-Host "=========================================================" -ForegroundColor Yellow
        Write-Host " RUNNING IN DRY-RUN MODE - NO FILES WILL BE CHANGED      " -ForegroundColor Yellow
        Write-Host "=========================================================" -ForegroundColor Yellow
    } else {
        Write-Host "=========================================================" -ForegroundColor Red
        Write-Host " WARNING: LIVE MODE! EXECUTING DELETIONS AND RENAMES     " -ForegroundColor Red
        Write-Host "=========================================================" -ForegroundColor Red
    }

    Write-Host "Scanning $Path for conflicting laptop-suffix pairs...`n" -ForegroundColor Cyan

    # Internal recursive repair worker
    function Repair-FilesWorker {
        param ([string]$CurrentPath)

        # 1. Grab all files at this specific level
        $Files = Get-ChildItem -Path $CurrentPath -File -ErrorAction SilentlyContinue
        foreach ($File in $Files) {
            
            # Identify if this file is a local laptop conflict copy
            if ($File.Name -match '(?<Prefix>.*)-LAPTOP-JCIDV7GB(?<Extension>\.[^.]+|$)$') {
                $BaseName = $Matches['Prefix']
                $Extension = $Matches['Extension']
                
                # Reconstruct what the original pristine filename should be
                $OriginalName = $BaseName + $Extension
                $OriginalFullPath = Join-Path -Path $CurrentPath -ChildPath $OriginalName

                # Check if the cloud version (original name) exists alongside it
                if (Test-Path -Path $OriginalFullPath) {
                    
                    if ($DryRun) {
                        Write-Host "[DRY-RUN PAIR MATCH FOUND]" -ForegroundColor Yellow
                        Write-Host "  X Remove Cloud Original : $OriginalFullPath" -ForegroundColor Gray
                        Write-Host "  <- Rename Laptop Version: $($File.FullName) -> $OriginalName`n" -ForegroundColor DarkGreen
                    } 
                    else {
                        try {
                            # 1. Nuke the out-of-sync cloud original file
                            Write-Host "[DELETE] Removing cloud original: $OriginalFullPath" -ForegroundColor Red
                            Remove-Item -Path $OriginalFullPath -Force -ErrorAction Stop

                            # 2. Rename your laptop copy to the original clean filename
                            Write-Host "[RENAME] Restoring laptop copy: $($File.Name) -> $OriginalName" -ForegroundColor Green
                            Rename-Item -Path $File.FullName -NewName $OriginalName -Force -ErrorAction Stop
                        } 
                        catch {
                            Write-Error "Failed to process pair for $($File.FullName): $_"
                        }
                    }
                } else {
                    # Orphan handling: Suffix file exists, but no original file is there to conflict with
                    if ($DryRun) {
                        Write-Host "[DRY-RUN ORPHAN FOUND]" -ForegroundColor Cyan
                        Write-Host "  <- Rename Solo Laptop Version: $($File.FullName) -> $OriginalName`n" -ForegroundColor DarkCyan
                    } else {
                        try {
                            Write-Host "[RENAME ORPHAN] Restoring single file: $($File.Name) -> $OriginalName" -ForegroundColor Cyan
                            Rename-Item -Path $File.FullName -NewName $OriginalName -Force -ErrorAction Stop
                        } catch {
                            Write-Error "Failed to rename orphan file $($File.FullName): $_"
                        }
                    }
                }
            }
        }

        # 2. Recurse down subdirectories (Bypassing .git repositories automatically)
        $SubDirs = Get-ChildItem -Path $CurrentPath -Directory -ErrorAction SilentlyContinue
        foreach ($Dir in $SubDirs) {
            if ($Dir.Name -eq ".git") { continue }
            Repair-FilesWorker -CurrentPath $Dir.FullName
        }
    }

    # Launch execution engine
    Repair-FilesWorker -CurrentPath $Path

    Write-Host "`nProcessing complete!" -ForegroundColor Green
}

# ==============================================================================
# RUN ENGINE
# ==============================================================================
# Run as Dry-Run first to review actions safely
Repair-OneDriveSyncConflicts -DryRun $true