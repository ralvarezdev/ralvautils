function Export-RecentFilesReport {
    [CmdletBinding()]
    param(
        [string]$Path       = (Get-OneDrivePath),
        [int]$DaysBack      = 1,
        [string]$OutputFile = (Join-Path (Get-DesktopPath) 'RecentFilesReport.txt')
    )

    if (-not (Test-Path $Path)) { throw "Path not found: $Path" }

    $dir = Split-Path $OutputFile
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

    $targetDates = 0..$DaysBack | ForEach-Object { (Get-Date).AddDays(-$_).Date }

    Write-Host "Scanning $Path for items created/modified in the last $($DaysBack + 1) day(s)..." -ForegroundColor Cyan
    Write-Host "Output: $OutputFile" -ForegroundColor Yellow

    "--- Created/Modified in last $($DaysBack + 1) day(s) (Run: $(Get-Date)) ---" |
        Out-File -FilePath $OutputFile -Encoding utf8

    function Search-Items ([string]$CurrentPath) {
        Get-ChildItem -Path $CurrentPath -ErrorAction SilentlyContinue | ForEach-Object {
            $createdRecent  = $targetDates -contains $_.CreationTime.Date
            $modifiedRecent = $targetDates -contains $_.LastWriteTime.Date

            if ($createdRecent -or $modifiedRecent) {
                $label  = if ($_.PSIsContainer) { 'DIR ' } else { 'FILE' }
                $action = if ($createdRecent -and $modifiedRecent) { 'CREATED/MODIFIED' }
                          elseif ($createdRecent)                  { 'CREATED         ' }
                          else                                     { 'MODIFIED         ' }
                $entry  = "[$($_.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))] [$label] [$action] $($_.FullName)"
                Write-Host $entry -ForegroundColor Gray
                $entry | Out-File -FilePath $OutputFile -Append -Encoding utf8
            }
        }

        Get-ChildItem -Path $CurrentPath -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -ne '.git' } |
            ForEach-Object { Search-Items $_.FullName }
    }

    Search-Items $Path
    Write-Host "Done. Report saved to: $OutputFile" -ForegroundColor Green
}
