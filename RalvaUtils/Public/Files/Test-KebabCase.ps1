function Test-KebabCase {
    [CmdletBinding()]
    param(
        [string]$Path = (Split-Path -Parent $PSCommandPath)
    )

    $violations = Get-ChildItem -Path $Path -Recurse -File |
        Where-Object { $_.Extension -notin @('.psd1', '.psm1') } |
        ForEach-Object {
            $name    = $_.BaseName
            $reasons = @()
            if ($name -cmatch '[A-Z]')                                          { $reasons += 'uppercase letters' }
            if ($name -match ' ')                                               { $reasons += 'spaces' }
            if ($name -match '_')                                               { $reasons += 'underscores' }
            if ($name -match '[^a-zA-Z0-9\-áéíóúüñÁÉÍÓÚÜÑ]')                 { $reasons += 'special characters' }
            if ($reasons.Count -gt 0) {
                [PSCustomObject]@{
                    File    = $_.FullName.Replace($Path + '\', '')
                    Reasons = $reasons -join ', '
                }
            }
        }

    if (-not $violations) {
        Write-Host "All files follow kebab-case." -ForegroundColor Green
    } else {
        Write-Host "$($violations.Count) file(s) with naming issues:" -ForegroundColor Yellow
        $violations | Format-Table -AutoSize -Wrap
    }
}
