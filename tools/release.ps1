# Release a new version: writes app/version.txt = the version, then "<sha256> <file>" for every app file.
# Installed copies pick it up the next time they open, once this is pushed to main.
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\release.ps1 1.1.0
param([Parameter(Mandatory)][string]$NewVersion)
$ErrorActionPreference = 'Stop'
[void][version]$NewVersion
$app = Join-Path (Split-Path $PSScriptRoot -Parent) 'app'
$lines = @($NewVersion) + (Get-ChildItem $app -File | Where-Object Name -ne 'version.txt' | Sort-Object Name |
    ForEach-Object { (Get-FileHash $_.FullName -Algorithm SHA256).Hash + ' ' + $_.Name })
[IO.File]::WriteAllText((Join-Path $app 'version.txt'), (($lines -join "`n") + "`n"))
$lines
