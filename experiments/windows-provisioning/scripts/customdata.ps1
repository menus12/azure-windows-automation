# Test A / C payload: installs 7-Zip from the official MSI.
# If Azure ever executes custom data on its own, it runs with the default
# -Invoker value and leaves an "autorun" marker. The Custom Script Extension
# wrapper calls it with -Invoker cse.
param([string]$Invoker = "autorun")

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$probe = "C:\probe"
New-Item -ItemType Directory -Force -Path $probe | Out-Null
$marker = Join-Path $probe "customdata-$Invoker.marker"
"started=$(Get-Date -Format o) user=$(whoami)" | Out-File -FilePath $marker -Encoding ascii

$msiUrl = "https://github.com/ip7z/7zip/releases/download/26.05/7z2605-x64.msi"
$msi = Join-Path $env:TEMP "7z2605-x64.msi"
Invoke-WebRequest -UseBasicParsing -Uri $msiUrl -OutFile $msi

$msiLog = Join-Path $probe "7zip-msi.log"
$p = Start-Process -FilePath msiexec.exe -ArgumentList "/i `"$msi`" /qn /norestart /l*v `"$msiLog`"" -Wait -PassThru
if ($p.ExitCode -ne 0) { throw "msiexec exited with $($p.ExitCode)" }

"finished=$(Get-Date -Format o) msiexec=$($p.ExitCode)" | Out-File -FilePath $marker -Append -Encoding ascii
Write-Output "7-Zip installed (invoker=$Invoker)"
