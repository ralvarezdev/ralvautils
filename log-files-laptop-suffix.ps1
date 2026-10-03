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
        
        # Dedicated output log name for complete historical search
        $OutputFile = Join-Path -Path $ResolvedDesktop -ChildPath "All_Laptop_Filtered_Entries.txt"
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

    Write-Host "Scanning $Path for ALL items containing '-LAPTOP-JCIDV7GB' (No Date Filter)..." -ForegroundColor Cyan
    Write-Host "Results will be saved securely to: $OutputFile`n" -ForegroundColor Yellow

    # Initialize the output log file with a clean header
    "--- Full Search: All Items Containing '-LAPTOP-JCIDV7GB' (Run Date: $(Get-Date)) ---" | Out-File -FilePath $OutputFile -Encoding utf8

    # Internal recursive processing worker
    function Get-FilesWorker {
        param ([string]$CurrentPath)

        # 1. Collect all filesystem items (both Files and Folders) at this level
        $Items = Get-ChildItem -Path $CurrentPath -ErrorAction SilentlyContinue
        foreach ($Item in $Items) {
            
            # Wildcard filter catches names like '.env-LAPTOP-JCIDV7GB.example' or trailing variations
            if ($Item.Name -like "*-LAPTOP-JCIDV7GB*") {
                $TypeLabel = if ($Item.PSIsContainer) { "DIR " } else { "FILE" }
                $Timestamp = $Item.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')
                $LogEntry  = "[$Timestamp] [$TypeLabel] $($Item.FullName)"
                
                Write-Host "Logging: $LogEntry" -ForegroundColor Gray
                
                # Append matching record entries smoothly
                $LogEntry | Out-File -FilePath $OutputFile -Append -Encoding utf8
            }
        }

        # 2. Descend down into subdirectories
        $SubDirs = Get-ChildItem -Path $CurrentPath -Directory -ErrorAction SilentlyContinue
        foreach ($Dir in $SubDirs) {
            # Omit and completely bypass .git repositories
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