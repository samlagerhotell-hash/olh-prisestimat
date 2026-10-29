# Installs OLH Prisestimat for the current user: copies the app to %LOCALAPPDATA%\OLH Prisestimat and puts an
# "OLH Prisestimat" shortcut on the desktop. The shortcut runs launcher.ps1, which updates the app from GitHub
# and opens it in its own Edge window. No admin rights needed.   -Target / -Desktop are for testing only.
param([string]$Target = (Join-Path $env:LOCALAPPDATA 'OLH Prisestimat'),
      [string]$Desktop = [Environment]::GetFolderPath('Desktop'))
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force -Path $Target | Out-Null
Copy-Item -Path (Join-Path $PSScriptRoot 'app\*') -Destination $Target -Force

# Edge (for the icon and a clear error now rather than later): App Paths first, then the usual folders.
$edge = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe' -ErrorAction SilentlyContinue).'(default)'
if (-not $edge -or -not (Test-Path $edge)) {
  $edge = @("${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe", "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe") |
    Where-Object { Test-Path $_ } | Select-Object -First 1
}
if (-not $edge) { throw 'Microsoft Edge was not found. Install Edge, then run Install again.' }

$s = (New-Object -ComObject WScript.Shell).CreateShortcut((Join-Path $Desktop 'OLH Prisestimat.lnk'))
$s.TargetPath = Join-Path $env:WINDIR 'System32\conhost.exe'
$s.Arguments = '--headless powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + (Join-Path $Target 'launcher.ps1') + '"'
$s.WorkingDirectory = $Target
$s.IconLocation = "$edge,0"
$s.Description = 'OLH Prisestimat'
$s.Save()
Write-Host "Installed. Double-click 'OLH Prisestimat' on your desktop. It updates itself."
