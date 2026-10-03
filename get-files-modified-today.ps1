function Get-ModifiedTodayCustom {
    param (
        # 5.1 compatible fallback syntax
        [string]$Path = $(if ($env:OneDrive) { $env:OneDrive } else { "$env:USERPROFILE\OneDrive" })
    )

    if (-not (Test-Path -Path $Path)) {
        Write-Error "Could not automatically locate your OneDrive folder at: $Path"
        return
    }

    $Today = (Get-Date).Date

    # 1. List files in the current folder modified today
    Get-ChildItem -Path $Path -File -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime.Date -eq $Today }

    # 2. Get all subdirectories
    $SubDirs = Get-ChildItem -Path $Path -Directory -ErrorAction SilentlyContinue

    foreach ($Dir in $SubDirs) {
        if ($Dir.LastWriteTime.Date -eq $Today) {
            # Folder was modified today! Let's prompt the user.
            Write-Host "`n[!] Found folder modified today: $($Dir.FullName)" -ForegroundColor Cyan

            # Create an interactive prompt choice
            $Caption = "Traverse Folder?"
            $Message = "This folder was modified today. Do you still want to look inside it?"
            $Choices = [System.Management.Automation.Host.ChoiceDescription[]] @(
                [System.Management.Automation.Host.ChoiceDescription]::new("&Yes", "Recurse into this folder"),
                [System.Management.Automation.Host.ChoiceDescription]::new("&No", "Skip this folder's contents")
            )

            # Default choice is No [1]
            $Decision = $Host.UI.PromptForChoice($Caption, $Message, $Choices, 1)

            if ($Decision -eq 0) {
                $Dir
                Get-ModifiedTodayCustom -Path $Dir.FullName
            } else {
                $Dir
                Write-Host "--> Skipped traversing inside: $($Dir.FullName)" -ForegroundColor Yellow
            }
        } else {
            # Folder wasn't modified today, seamlessly dig inside without asking
            Get-ModifiedTodayCustom -Path $Dir.FullName
        }
    }
}

# Run the function cleanly
Get-ModifiedTodayCustom