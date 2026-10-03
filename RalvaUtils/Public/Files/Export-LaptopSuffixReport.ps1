function Export-LaptopSuffixReport {
    [CmdletBinding()]
    param(
        [string]$Path       = (Get-OneDrivePath),
        [string]$Suffix     = (Get-RalvaConfig -Key 'LaptopSuffix'),
        [string]$OutputFile = (Join-Path (Get-DesktopPath) 'LaptopSuffixReport.txt')
    )

    if (-not $Suffix) {
        throw "LaptopSuffix not configured. Run: Set-RalvaConfig -Key LaptopSuffix -Value '-LAPTOP-YOURNAME'"
    }

    if (-not (Test-Path $Path)) { throw "Path not found: $Path" }

    $dir = Split-Path $OutputFile
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

    Write-Host "Scanning $Path for items containing '$Suffix'..." -ForegroundColor Cyan
    Write-Host "Output: $OutputFile" -ForegroundColor Yellow

    "--- Items containing '$Suffix' (Run: $(Get-Date)) ---" |
        Out-File -FilePath $OutputFile -Encoding utf8

    function Search-Items ([string]$CurrentPath) {
        Get-ChildItem -Path $CurrentPath -ErrorAction SilentlyContinue | ForEach-Object {
            if ($_.Name -like "*$Suffix*") {
                $label = if ($_.PSIsContainer) { 'DIR ' } else { 'FILE' }
                $entry = "[$($_.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))] [$label] $($_.FullName)"
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
