# 1. Find all files inside .git with the specific suffix
$suffixedFiles = Get-ChildItem -Path .\.git -Filter "*-LAPTOP-JCIDV7GB*" -Recurse -Force

foreach ($file in $suffixedFiles) {
    # 2. Calculate what the original filename should be by removing the suffix
    $originalName = $file.Name -replace "-LAPTOP-JCIDV7GB", ""
    $originalPath = Join-Path $file.DirectoryName $originalName

    # 3. If the original file exists, back it up first
    if (Test-Path $originalPath) {
        Move-Item -Path $originalPath -Destination "$originalPath.bak" -Force -ErrorAction SilentlyContinue
        Write-Host "Backed up: $originalName -> $originalName.bak" -ForegroundColor Yellow
    }

    # 4. Rename the suffixed file to the original filename
    Move-Item -Path $file.FullName -Destination $originalPath -Force
    Write-Host "Replaced with newer version: $originalName" -ForegroundColor Green
}
