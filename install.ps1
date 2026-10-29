# Installs OLH Prisestimat for the current user: copies the app to %LOCALAPPDATA%\OLH Prisestimat and puts an
# "OLH Prisestimat" shortcut on the desktop that opens it in its own Edge window. No admin rights needed.
$ErrorActionPreference = 'Stop'
$src  = Join-Path $PSScriptRoot 'app'
$dest = Join-Path $env:LOCALAPPDATA 'OLH Prisestimat'
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Copy-Item -Path (Join-Path $src '*') -Destination $dest -Force

# Edge: the App Paths registry entry first, then the usual install folders.
$edge = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe' -ErrorAction SilentlyContinue).'(default)'
if (-not $edge -or -not (Test-Path $edge)) {
  $edge = @("${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe", "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe") |
    Where-Object { Test-Path $_ } | Select-Object -First 1
}
if (-not $edge) { throw 'Microsoft Edge was not found. Install Edge, then run Install again.' }

$page = ([Uri](Join-Path $dest 'Prisestimat.html')).AbsoluteUri
$lnk  = Join-Path ([Environment]::GetFolderPath('Desktop')) 'OLH Prisestimat.lnk'
$s = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk)
$s.TargetPath = $edge
$s.Arguments = "--app=`"$page`""
$s.WorkingDirectory = $dest
$s.IconLocation = "$edge,0"
$s.Description = 'OLH Prisestimat'
$s.Save()
Write-Host "Installed. Double-click 'OLH Prisestimat' on your desktop."
