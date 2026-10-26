# Strict script: stops on the first error. The download URL returns 404.
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

New-Item -ItemType Directory -Force -Path "C:\probe" | Out-Null
"started=$(Get-Date -Format o)" | Out-File -FilePath "C:\probe\fail-throw.marker" -Encoding ascii

$msi = Join-Path $env:TEMP "missing.msi"
Invoke-WebRequest -UseBasicParsing -Uri "https://github.com/ip7z/7zip/releases/download/0.0/does-not-exist.msi" -OutFile $msi

"reached-end=$(Get-Date -Format o)" | Out-File -FilePath "C:\probe\fail-throw.marker" -Append -Encoding ascii
