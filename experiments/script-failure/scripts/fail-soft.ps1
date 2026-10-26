# Script written with PowerShell defaults: no $ErrorActionPreference, no exit
# code checks. The download URL returns 404 and msiexec then fails on the
# missing file, but nothing stops the script.
$ProgressPreference = "SilentlyContinue"

New-Item -ItemType Directory -Force -Path "C:\probe" | Out-Null
"started=$(Get-Date -Format o)" | Out-File -FilePath "C:\probe\fail-soft.marker" -Encoding ascii

$msi = Join-Path $env:TEMP "missing.msi"
Invoke-WebRequest -UseBasicParsing -Uri "https://github.com/ip7z/7zip/releases/download/0.0/does-not-exist.msi" -OutFile $msi

$p = Start-Process -FilePath msiexec.exe -ArgumentList "/i `"$msi`" /qn /norestart" -Wait -PassThru
"msiexec=$($p.ExitCode)" | Out-File -FilePath "C:\probe\fail-soft.marker" -Append -Encoding ascii

"reached-end=$(Get-Date -Format o)" | Out-File -FilePath "C:\probe\fail-soft.marker" -Append -Encoding ascii
Write-Output "script finished"
