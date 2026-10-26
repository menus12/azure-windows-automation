# Test D: Managed Run Command payload. Installs PowerShell 7 from the official MSI.
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$probe = "C:\probe"
New-Item -ItemType Directory -Force -Path $probe | Out-Null
$marker = Join-Path $probe "runcommand.marker"
"started=$(Get-Date -Format o) user=$(whoami)" | Out-File -FilePath $marker -Encoding ascii

$msiUrl = "https://github.com/PowerShell/PowerShell/releases/download/v7.6.9/PowerShell-7.6.9-win-x64.msi"
$msi = Join-Path $env:TEMP "PowerShell-7.6.9-win-x64.msi"
Invoke-WebRequest -UseBasicParsing -Uri $msiUrl -OutFile $msi

$msiLog = Join-Path $probe "pwsh-msi.log"
$p = Start-Process -FilePath msiexec.exe -ArgumentList "/i `"$msi`" /qn /norestart /l*v `"$msiLog`"" -Wait -PassThru
if ($p.ExitCode -ne 0) { throw "msiexec exited with $($p.ExitCode)" }

"finished=$(Get-Date -Format o) msiexec=$($p.ExitCode)" | Out-File -FilePath $marker -Append -Encoding ascii
Write-Output "PowerShell 7 installed"
