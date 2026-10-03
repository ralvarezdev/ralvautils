$NUMBER_COMMITS=git rev-list --count HEAD

git rebase -i --root
for ($i = 1; $i -le $NUMBER_COMMITS; $i += 1)
{
    $env:GIT_COMMITTER_DATE=git log -1 --format=%ad
    git commit --amend -S --date=$env:GIT_COMMITTER_DATE --no-edit
    git rebase --continue
 }

Remove-Item ENV:GIT_COMMITTER_DATE
