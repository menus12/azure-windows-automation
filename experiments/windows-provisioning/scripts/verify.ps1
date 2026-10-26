# Inspection script, run with `az vm run-command invoke` after deployment.
$ErrorActionPreference = "Continue"

Write-Output "== Boot time"
(Get-CimInstance Win32_OperatingSystem).LastBootUpTime.ToString("o")

Write-Output "== C:\AzureData"
Get-ChildItem C:\AzureData -ErrorAction SilentlyContinue | Select-Object Name, Length, CreationTime | Format-Table -AutoSize | Out-String

Write-Output "== CustomData.bin first 80 chars"
if (Test-Path C:\AzureData\CustomData.bin) { ([IO.File]::ReadAllText("C:\AzureData\CustomData.bin")).Substring(0, 80) }

Write-Output "== Markers in C:\probe"
Get-ChildItem C:\probe -Filter *.marker -ErrorAction SilentlyContinue | ForEach-Object { "--- $($_.Name)"; Get-Content $_.FullName }

Write-Output "== Installed programs"
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
    Where-Object { $_.DisplayName -match '7-Zip|PowerShell 7' } |
    Select-Object DisplayName, DisplayVersion, InstallDate | Format-Table -AutoSize | Out-String

Write-Output "== Binaries"
if (Test-Path "C:\Program Files\7-Zip\7z.exe") { (& "C:\Program Files\7-Zip\7z.exe" | Select-Object -Skip 1 -First 1) } else { "7z.exe missing" }
if (Test-Path "C:\Program Files\PowerShell\7\pwsh.exe") { & "C:\Program Files\PowerShell\7\pwsh.exe" -NoProfile -Command '$PSVersionTable.PSVersion.ToString()' } else { "pwsh.exe missing" }

Write-Output "== User data from IMDS (decoded)"
try {
    $ud = Invoke-RestMethod -Headers @{ Metadata = "true" } -UseBasicParsing -Uri "http://169.254.169.254/metadata/instance/compute/userData?api-version=2021-01-01&format=text"
    [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($ud))
} catch { "IMDS error: $_" }
