function Export-RecentFilesReport {
    param (
        # Safe fallback targeting your main active OneDrive directory
        [string]$Path = $(if ($env:OneDrive) { $env:OneDrive } else { "$env:USERPROFILE\OneDrive" }),
        [string]$OutputFile = $null
    )

    # 1. Dynamically locate the true active Desktop directory to bypass OneDrive redirection errors
    if ([string]::IsNullOrWhiteSpace($OutputFile)) {
        $UserShellFolders = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
        $RegistryDesktop  = Get-ItemProperty -Path $UserShellFolders -Name "Desktop" -ErrorAction SilentlyContinue
        
        $ResolvedDesktop  = if ($RegistryDesktop) { 
            [Environment]::ExpandEnvironmentVariables($RegistryDesktop.Desktop) 
        } else { 
            "$env:USERPROFILE\Desktop" 
        }
        
        # CHANGED: Updated file name to Recent_Raw_Sync_Log.txt
        $OutputFile = Join-Path -Path $ResolvedDesktop -ChildPath "Recent_Raw_Sync_Log.txt"
    }

    if (-not (Test-Path -Path $Path)) {
        Write-Error "Could not automatically locate your target folder at: $Path"
        return
    }

    # Ensure the parent folder container physically exists before starting any file streams
    $ParentDir = Split-Path -Path $OutputFile -Parent
    if (-not (Test-Path -Path $ParentDir)) {
        New-Item -ItemType Directory -Path $ParentDir -Force | Out-Null
    }

    # Define our 48-hour date window boundaries
    $TargetDates = @(
        (Get-Date).Date,            # Today
        (Get-Date).AddDays(-1).Date # Yesterday
    )

    Write-Host "Scanning $Path for ALL raw files and folders created or modified today and yesterday..." -ForegroundColor Cyan
    Write-Host "Results will be saved securely to: $OutputFile`n" -ForegroundColor Yellow

    # Initialize the output log file with a clean header
    "--- Raw Files & Folders Created/Modified Today & Yesterday (Run Date: $(Get-Date)) ---" | Out-File -FilePath $OutputFile -Encoding utf8

    # Internal recursive processing worker
    function Get-FilesWorker {
        param ([string]$CurrentPath)

        # 1. Collect all filesystem items (both Files AND Folders) at this specific level
        $Items = Get-ChildItem -Path $CurrentPath -ErrorAction SilentlyContinue
        foreach ($Item in $Items) {
            
            # Check if EITHER creation time OR modification time falls on today/yesterday
            $IsCreatedRecent  = $TargetDates -contains $Item.CreationTime.Date
            $IsModifiedRecent = $TargetDates -contains $Item.LastWriteTime.Date

            if ($IsCreatedRecent -or $IsModifiedRecent) {
                # Add a clear type label wrapper so you know if it's a [FILE] or [DIR]
                $TypeLabel   = if ($Item.PSIsContainer) { "DIR " } else { "FILE" }
                $ActionLabel = if ($IsCreatedRecent -and $IsModifiedRecent) { "CREATED/MODIFIED" } 
                               elseif ($IsCreatedRecent) { "CREATED " } 
                               else { "MODIFIED" }

                $Timestamp = $Item.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')
                $LogEntry = "[$Timestamp] [$TypeLabel] [$ActionLabel] $($Item.FullName)"
                
                Write-Host "Logging: $LogEntry" -ForegroundColor Gray
                
                # Append matching record entries smoothly
                $LogEntry | Out-File -FilePath $OutputFile -Append -Encoding utf8
            }
        }

        # 2. Descend down into subdirectories
        $SubDirs = Get-ChildItem -Path $CurrentPath -Directory -ErrorAction SilentlyContinue
        foreach ($Dir in $SubDirs) {
            # Omit and completely bypass .git repositories to save precious CPU cycles and overhead
            if ($Dir.Name -eq ".git") { continue }

            Get-FilesWorker -CurrentPath $Dir.FullName
        }
    }

    # Launch execution engine
    Get-FilesWorker -CurrentPath $Path

    Write-Host "`nScan complete! Your raw file log is ready." -ForegroundColor Green
}

# Run the export routine
Export-RecentFilesReport