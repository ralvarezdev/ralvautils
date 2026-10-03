# ==============================================================================
# PRE-REQUISITES & AUTHENTICATION
# ==============================================================================
if (-not (Get-Module -Name Microsoft.Graph.Files -ListAvailable -ErrorAction SilentlyContinue)) {
    Write-Host "Installing missing Microsoft Graph dependencies..." -ForegroundColor Yellow
    Install-PSResource -Name Microsoft.Graph.Files -Scope CurrentUser -Reinstall -ErrorAction SilentlyContinue
}

Import-Module Microsoft.Graph.Files

Write-Host "Connecting to Microsoft Graph API..." -ForegroundColor Cyan
Connect-MgGraph -Scopes "Files.ReadWrite.All"

# ==============================================================================
# DATA CONFIGURATION & BACKEND FUNCTIONS
# ==============================================================================

$script:DevFolderNames = @(
    "node_modules", ".turbo", ".next", ".nuxt", ".parsed-cache",
    ".eslintcache", ".prettiercache", ".pnpm-store", ".yarn",
    ".venv", "__pycache__", ".pytest_cache", ".mypy_cache",
    ".ruff_cache", ".tox", ".pixi", ".golangci-lint", ".task"
)

# Adaptive Progressive Deletion Engine with 404 Guard rails
function Invoke-AdaptiveFolderDelete {
    param (
        [string]$DriveId = "me",
        [string]$FolderId,
        [string]$RelativePath
    )

    try {
        # 1. Attempt immediate quick parent removal pass
        if (-not [string]::IsNullOrWhiteSpace($FolderId)) {
            Remove-MgDriveItem -DriveId $DriveId -DriveItemId $FolderId -ErrorAction Stop
        } else {
            Remove-MgDriveItem -DriveId $DriveId -DriveItemPath $RelativePath -ErrorAction Stop
        }
        Write-Host "   [SUCCESS] Deleted folder block: /$RelativePath" -ForegroundColor Green
    }
    catch {
        # GUARD: If item was already purged by local OneDrive client sync, ignore and return safely
        if ($_.Exception.Message -match "404" -or $_.Exception.Message -match "itemNotFound") {
            return
        }

        # 2. Progressively step down if the 5k threshold constraint is triggered
        if ($_.Exception.Message -match "threshold" -or $_.Exception.Message -match "422") {
            Write-Host "   [THRESHOLD] /$RelativePath is > 5k items. Processing child objects..." -ForegroundColor Yellow
            
            $Children = $null
            if (-not [string]::IsNullOrWhiteSpace($FolderId)) {
                $Children = Get-MgDriveItemChild -DriveId $DriveId -DriveItemId $FolderId -ErrorAction SilentlyContinue
            } else {
                $Children = Get-MgDriveItemChild -DriveId $DriveId -DriveItemPath $RelativePath -ErrorAction SilentlyContinue
            }

            $SubDirs = $Children | Where-Object { $null -ne $_.Folder }
            $Files   = $Children | Where-Object { $null -ne $_.File }

            # Drop flat files at this folder depth
            foreach ($File in $Files) {
                try {
                    if (-not [string]::IsNullOrWhiteSpace($File.Id)) {
                        Remove-MgDriveItem -DriveId $DriveId -DriveItemId $File.Id -ErrorAction Stop
                    } else {
                        Remove-MgDriveItem -DriveId $DriveId -DriveItemPath "$RelativePath/$($File.Name)" -ErrorAction Stop
                    }
                } catch {
                    if ($_.Exception.Message -notmatch "404" -and $_.Exception.Message -notmatch "itemNotFound") {
                        Write-Error "File delete error: $_"
                    }
                }
            }

            # Progressively scale execution down into subdirectories
            foreach ($SubDir in $SubDirs) {
                Invoke-AdaptiveFolderDelete -DriveId $DriveId -FolderId $SubDir.Id -RelativePath "$RelativePath/$($SubDir.Name)"
            }

            # 3. Final cleanup loop on empty root shell wrapper
            try {
                if (-not [string]::IsNullOrWhiteSpace($FolderId)) {
                    Remove-MgDriveItem -DriveId $DriveId -DriveItemId $FolderId -ErrorAction SilentlyContinue
                } else {
                    Remove-MgDriveItem -DriveId $DriveId -DriveItemPath $RelativePath -ErrorAction SilentlyContinue
                }
            } catch {}
        }
        else {
            Write-Error "Failed to process /$RelativePath due to alternative error structural constraint: $_"
        }
    }
}

# Ordered Resume Traversal Logic
function Remove-GraphFolder {
    param (
        [string]$ItemId = "root",
        [string]$CurrentPath = "Root",
        [string[]]$CheckpointPath = @()
    )

    $Folders = Get-MgDriveItemChild -DriveId "me" -DriveItemId $ItemId -Filter "folder ne null" -ErrorAction SilentlyContinue |
               Sort-Object Name

    if ($null -eq $Folders -or $Folders.Count -eq 0) {
        return
    }

    $InCheckpointMode = $CheckpointPath.Count -gt 0

    if ($InCheckpointMode) {
        $ActiveCheckpointItem = $CheckpointPath[0]
        $RemainingCheckpoints = $CheckpointPath | Select-Object -Skip 1

        foreach ($Dir in $Folders) {
            $CleanedName = $Dir.Name.Trim()

            if ($CleanedName -lt $ActiveCheckpointItem) {
                continue
            }
            elseif ($CleanedName -eq $ActiveCheckpointItem) {
                if ($RemainingCheckpoints.Count -gt 0) {
                    Write-Host "--> Re-entering checkpoint branch: $CurrentPath/$CleanedName" -ForegroundColor Yellow
                    Remove-GraphFolder -ItemId $Dir.Id -CurrentPath "$CurrentPath/$CleanedName" -CheckpointPath $RemainingCheckpoints
                } else {
                    Write-Host "--> Checkpoint threshold reached at [$CleanedName]. Resuming active sweep from here..." -ForegroundColor Green
                    Execute-NormalScan -Dir $Dir -CurrentPath $CurrentPath
                }
            }
            else {
                Execute-NormalScan -Dir $Dir -CurrentPath $CurrentPath
            }
        }
    } else {
        foreach ($Dir in $Folders) {
            Execute-NormalScan -Dir $Dir -CurrentPath $CurrentPath
        }
    }
}

function Execute-NormalScan ($Dir, $CurrentPath) {
    $CleanedName = $Dir.Name.Trim()

    if ($CleanedName -eq ".git") {
        Write-Host "Omit & Skip Traversing Git Repository: $CurrentPath/$CleanedName" -ForegroundColor Cyan
        return
    }

    if ($script:DevFolderNames -contains $CleanedName) {
        Write-Host "[MATCH Target Found]: $CurrentPath/$CleanedName" -ForegroundColor Red
        
        $CloudGraphPath = "$CurrentPath/$CleanedName".Replace('Root/', '')
        Invoke-AdaptiveFolderDelete -DriveId "me" -FolderId $Dir.Id -RelativePath $CloudGraphPath
    } else {
        Write-Host "Scanning: $CurrentPath/$CleanedName" -ForegroundColor Gray
        Remove-GraphFolder -ItemId $Dir.Id -CurrentPath "$CurrentPath/$CleanedName" -CheckpointPath @()
    }
}

# ==============================================================================
# RUN EXECUTION ROUTINE
# ==============================================================================

$CheckpointSegments = @(
    "Documents",
    "private",
    "projects",
    "archived",
    "teamsteelbot",
    "klevor-v2-platform",
    "platform",
    "robot"
)

Write-Host "Resuming scan securely from workspace checkpoint..." -ForegroundColor Cyan
Remove-GraphFolder -ItemId "root" -CurrentPath "Root" -CheckpointPath $CheckpointSegments