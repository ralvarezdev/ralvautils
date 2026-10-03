function Get-OneDrivePath {
    if ($env:OneDrive -and (Test-Path $env:OneDrive)) { return $env:OneDrive }
    $default = "$env:USERPROFILE\OneDrive"
    if (Test-Path $default) { return $default }
    throw "OneDrive folder not found. Set the OneDrive environment variable or pass -Path explicitly."
}
