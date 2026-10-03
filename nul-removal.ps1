# Combined script to safely remove files named 'nul' or 'null'
Get-ChildItem -Path . -Recurse -File -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -ieq 'nul' -or $_.Name -ieq 'null' } |
    ForEach-Object {
        # Ensure we are getting the absolute full path
        $absolutePath = $_.FullName
        
        # Format the path with the Win32 namespaces prefix to bypass reserved name restrictions
        if ($absolutePath -notlike '\\?\*') {
            $safePath = "\\?\$absolutePath"
        } else {
            $safePath = $absolutePath
        }

        Write-Host "Attempting to remove: $absolutePath" -ForegroundColor Cyan
        
        try {
            # -LiteralPath is crucial here to prevent wildcard parsing
            Remove-Item -LiteralPath $safePath -Force -Verbose -ErrorAction Stop
            Write-Host "Successfully removed: $absolutePath" -ForegroundColor Green
        }
        catch {
            Write-Warning "PowerShell failed to remove $absolutePath. Trying CMD fallback..."
            # CMD fallback using the raw tool to override Windows reserved name locking
            cmd.exe /c "del /f /q /a `"$safePath`""
        }
    }