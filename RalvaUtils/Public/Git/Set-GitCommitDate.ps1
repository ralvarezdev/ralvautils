function Set-GitCommitDate {
    [CmdletBinding()]
    param(
        [string]$Path = '.'
    )
    Push-Location $Path
    try {
        $count = git rev-list --count HEAD
        git rebase -i --root
        for ($i = 1; $i -le $count; $i++) {
            $env:GIT_COMMITTER_DATE = git log -1 --format=%ad
            git commit --amend -S --date=$env:GIT_COMMITTER_DATE --no-edit
            git rebase --continue
        }
    } finally {
        Remove-Item Env:GIT_COMMITTER_DATE -ErrorAction SilentlyContinue
        Pop-Location
    }
}
