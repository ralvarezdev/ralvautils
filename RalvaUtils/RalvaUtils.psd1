@{
    RootModule        = 'RalvaUtils.psm1'
    ModuleVersion     = '0.1.0'
    Author            = 'Ramon Alvarez'
    Description       = 'Personal PowerShell utility module — git, OneDrive, dev cache, file tools.'
    PowerShellVersion = '7.0'

    FunctionsToExport = @(
        # Config
        'Get-RalvaConfig'
        'Set-RalvaConfig'
        # Git
        'Set-GitCommitDate'
        # OneDrive
        'Protect-OneDriveFolders'
        'Repair-OneDriveGitConflicts'
        'Repair-OneDriveSyncConflicts'
        'Remove-OneDriveDevCache'
        # Dev cache
        'Remove-LocalDevCache'
        'Invoke-ProjectCleanup'
        # Files
        'Test-KebabCase'
        'Get-FilesModifiedToday'
        'Export-LaptopSuffixReport'
        'Export-RecentFilesReport'
        'Remove-NullFiles'
    )

    CmdletsToExport   = @()
    AliasesToExport   = @()
    VariablesToExport = @()
}
