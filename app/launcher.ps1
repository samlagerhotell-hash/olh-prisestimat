# OLH Prisestimat launcher: updates the app from GitHub if there is a newer version, then opens it in an Edge window.
# version.txt (here and on GitHub) = first line the version, then one "<sha256> <file>" line per app file.
# New files are downloaded to a temp folder and only copied in when every hash matches. Any failure (offline,
# GitHub down, bad file) is ignored and the installed version opens.   -NoOpen = update only (for testing).
param([switch]$NoOpen)
$here = $PSScriptRoot
$raw  = 'https://raw.githubusercontent.com/samlagerhotell-hash/olh-prisestimat/main/app'

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $local  = '0'
    $lv = Join-Path $here 'version.txt'
    if (Test-Path $lv) { $local = (Get-Content $lv -TotalCount 1).Trim() }
    $remote = (Invoke-WebRequest "$raw/version.txt" -UseBasicParsing -TimeoutSec 5).Content -split "`r?`n" | Where-Object { $_.Trim() }
    if ([version]$remote[0].Trim() -gt [version]$local) {
        $tmp = Join-Path $env:TEMP ('olh-prisestimat-' + [guid]::NewGuid())
        New-Item -ItemType Directory -Path $tmp | Out-Null
        try {
            $files = foreach ($line in $remote[1..($remote.Count - 1)]) {
                $sha, $name = $line.Trim() -split '\s+', 2
                if ($name -notmatch '^[\w.-]+$') { throw "bad file name $name" }
                $out = Join-Path $tmp $name
                Invoke-WebRequest "$raw/$name" -UseBasicParsing -TimeoutSec 20 -OutFile $out
                if ((Get-FileHash $out -Algorithm SHA256).Hash -ne $sha.ToUpper()) { throw "hash mismatch $name" }
                $name
            }
            foreach ($name in $files) { Copy-Item (Join-Path $tmp $name) (Join-Path $here $name) -Force }
            [IO.File]::WriteAllText($lv, (($remote -join "`n") + "`n"))
        } finally { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue }
    }
} catch { }

if ($NoOpen) { return }
$edge = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe' -ErrorAction SilentlyContinue).'(default)'
if (-not $edge -or -not (Test-Path $edge)) {
    $edge = @("${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe", "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe") |
        Where-Object { Test-Path $_ } | Select-Object -First 1
}
Start-Process $edge -ArgumentList ('--app="' + ([Uri](Join-Path $here 'Prisestimat.html')).AbsoluteUri + '"')
