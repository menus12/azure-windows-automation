# Test C: Custom Script Extension entry point. Copies the custom data payload
# to a .ps1 file and runs it. Records whether CustomData.bin is plain text or
# Base64 so the README can document the actual on-disk format.
$ErrorActionPreference = "Stop"
$probe = "C:\probe"
New-Item -ItemType Directory -Force -Path $probe | Out-Null

$raw = [IO.File]::ReadAllText("C:\AzureData\CustomData.bin")
$format = "plain"
if ($raw.Trim() -match '^[A-Za-z0-9+/]+={0,2}$') {
    $raw = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($raw.Trim()))
    $format = "base64"
}
"customdata-format=$format" | Out-File -FilePath (Join-Path $probe "cse-wrapper.marker") -Encoding ascii

$script = Join-Path $probe "customdata.ps1"
Set-Content -Path $script -Value $raw -Encoding UTF8
& $script -Invoker cse
