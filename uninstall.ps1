# Removes OLH Prisestimat: the desktop shortcut and %LOCALAPPDATA%\OLH Prisestimat.
$lnk  = Join-Path ([Environment]::GetFolderPath('Desktop')) 'OLH Prisestimat.lnk'
$dest = Join-Path $env:LOCALAPPDATA 'OLH Prisestimat'
Remove-Item -LiteralPath $lnk -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $dest -Recurse -Force -ErrorAction SilentlyContinue
Write-Host 'OLH Prisestimat removed.'
