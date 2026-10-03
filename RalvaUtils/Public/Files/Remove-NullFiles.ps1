function Remove-NullFiles {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$Path = '.'
    )

    @('nul', 'null') | ForEach-Object {
        $name = $_
        Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -ieq $name } |
            ForEach-Object {
                if ($PSCmdlet.ShouldProcess($_.FullName, 'Remove-Item')) {
                    Write-Host "Removing: $($_.FullName)" -ForegroundColor Red
                    Remove-Item -LiteralPath "\\?\$($_.FullName)" -Force -Recurse -ErrorAction SilentlyContinue
                }
            }
    }
}
