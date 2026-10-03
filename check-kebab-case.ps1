$root = Split-Path -Parent $MyInvocation.MyCommand.Path

$violations = @()

Get-ChildItem -Path $root -Recurse -File |
    Where-Object { $_.Name -ne "check-kebab-case.ps1" } |
    ForEach-Object {
        $name = $_.BaseName
        $reasons = @()

        if ($name -cmatch '[A-Z]')          { $reasons += "uppercase letters" }
        if ($name -match ' ')               { $reasons += "spaces" }
        if ($name -match '_')               { $reasons += "underscores" }
        if ($name -match '[^a-zA-Z0-9\-áéíóúüñÁÉÍÓÚÜÑ]') { $reasons += "special characters" }

        if ($reasons.Count -gt 0) {
            $violations += [PSCustomObject]@{
                File    = $_.FullName.Replace($root + "\", "")
                Reasons = $reasons -join ", "
            }
        }
    }

if ($violations.Count -eq 0) {
    Write-Host "All files follow kebab-case." -ForegroundColor Green
} else {
    Write-Host "$($violations.Count) file(s) with naming issues:`n" -ForegroundColor Yellow
    $violations | Format-Table -AutoSize -Wrap
}
