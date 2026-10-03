function Remove-OneDriveDevCache {
    [CmdletBinding()]
    param(
        [string[]]$CheckpointPath = @()
    )

    if (-not (Get-Module -Name Microsoft.Graph.Files -ListAvailable -ErrorAction SilentlyContinue)) {
        Write-Host "Installing Microsoft.Graph.Files..." -ForegroundColor Yellow
        Install-PSResource -Name Microsoft.Graph.Files -Scope CurrentUser -Reinstall -ErrorAction SilentlyContinue
    }
    Import-Module Microsoft.Graph.Files

    Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
    Connect-MgGraph -Scopes 'Files.ReadWrite.All'

    function Invoke-AdaptiveFolderDelete ([string]$DriveId = 'me', [string]$FolderId, [string]$RelativePath) {
        try {
            if ($FolderId) {
                Remove-MgDriveItem -DriveId $DriveId -DriveItemId $FolderId -ErrorAction Stop
            } else {
                Remove-MgDriveItem -DriveId $DriveId -DriveItemPath $RelativePath -ErrorAction Stop
            }
            Write-Host "  [OK] /$RelativePath" -ForegroundColor Green
        } catch {
            if ($_.Exception.Message -match '404|itemNotFound') { return }

            if ($_.Exception.Message -match 'threshold|422') {
                Write-Host "  [THRESHOLD] /$RelativePath — processing children..." -ForegroundColor Yellow
                $children = if ($FolderId) {
                    Get-MgDriveItemChild -DriveId $DriveId -DriveItemId $FolderId -ErrorAction SilentlyContinue
                } else {
                    Get-MgDriveItemChild -DriveId $DriveId -DriveItemPath $RelativePath -ErrorAction SilentlyContinue
                }

                $children | Where-Object { $_.File } | ForEach-Object {
                    try {
                        $id = $_.Id
                        if ($id) { Remove-MgDriveItem -DriveId $DriveId -DriveItemId $id -ErrorAction Stop }
                        else     { Remove-MgDriveItem -DriveId $DriveId -DriveItemPath "$RelativePath/$($_.Name)" -ErrorAction Stop }
                    } catch {
                        if ($_.Exception.Message -notmatch '404|itemNotFound') { Write-Error "File error: $_" }
                    }
                }

                $children | Where-Object { $_.Folder } | ForEach-Object {
                    Invoke-AdaptiveFolderDelete -DriveId $DriveId -FolderId $_.Id -RelativePath "$RelativePath/$($_.Name)"
                }

                try {
                    if ($FolderId) { Remove-MgDriveItem -DriveId $DriveId -DriveItemId $FolderId -ErrorAction SilentlyContinue }
                    else           { Remove-MgDriveItem -DriveId $DriveId -DriveItemPath $RelativePath -ErrorAction SilentlyContinue }
                } catch {}
            } else {
                Write-Error "Failed /$RelativePath : $_"
            }
        }
    }

    function Invoke-NormalScan ($Dir, [string]$CurrentPath) {
        $name = $Dir.Name.Trim()
        if ($name -eq '.git') { Write-Host "Skip .git: $CurrentPath/$name" -ForegroundColor Cyan; return }

        if ($Script:DevFolderNames -contains $name) {
            Write-Host "[MATCH] $CurrentPath/$name" -ForegroundColor Red
            $cloudPath = "$CurrentPath/$name" -replace '^Root/', ''
            Invoke-AdaptiveFolderDelete -FolderId $Dir.Id -RelativePath $cloudPath
        } else {
            Write-Host "Scan: $CurrentPath/$name" -ForegroundColor Gray
            Invoke-GraphFolderScan -ItemId $Dir.Id -CurrentPath "$CurrentPath/$name" -CheckpointPath @()
        }
    }

    function Invoke-GraphFolderScan ([string]$ItemId = 'root', [string]$CurrentPath = 'Root', [string[]]$CheckpointPath = @()) {
        $folders = Get-MgDriveItemChild -DriveId 'me' -DriveItemId $ItemId -Filter 'folder ne null' -ErrorAction SilentlyContinue |
                   Sort-Object Name

        if (-not $folders) { return }

        if ($CheckpointPath.Count -gt 0) {
            $head      = $CheckpointPath[0]
            $remaining = $CheckpointPath | Select-Object -Skip 1

            foreach ($dir in $folders) {
                $name = $dir.Name.Trim()
                if ($name -lt $head) { continue }
                elseif ($name -eq $head) {
                    if ($remaining.Count -gt 0) {
                        Write-Host "--> Checkpoint: $CurrentPath/$name" -ForegroundColor Yellow
                        Invoke-GraphFolderScan -ItemId $dir.Id -CurrentPath "$CurrentPath/$name" -CheckpointPath $remaining
                    } else {
                        Write-Host "--> Resuming from: $name" -ForegroundColor Green
                        Invoke-NormalScan $dir $CurrentPath
                    }
                } else {
                    Invoke-NormalScan $dir $CurrentPath
                }
            }
        } else {
            foreach ($dir in $folders) { Invoke-NormalScan $dir $CurrentPath }
        }
    }

    Write-Host "Starting OneDrive cloud dev cache removal..." -ForegroundColor Cyan
    Invoke-GraphFolderScan -ItemId 'root' -CurrentPath 'Root' -CheckpointPath $CheckpointPath
    Write-Host "Complete." -ForegroundColor Green
}
