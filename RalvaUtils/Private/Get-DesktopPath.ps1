function Get-DesktopPath {
    $key = Get-ItemProperty `
        -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' `
        -Name 'Desktop' -ErrorAction SilentlyContinue
    if ($key) { return [Environment]::ExpandEnvironmentVariables($key.Desktop) }
    return "$env:USERPROFILE\Desktop"
}
