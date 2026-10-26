# Custom Script Extension entry point. Runs the custom data payload in a
# separate powershell.exe -File process, so the payload keeps PowerShell's
# default error handling, and passes its exit code back to the extension.
$probe = "C:\probe"
New-Item -ItemType Directory -Force -Path $probe | Out-Null
$script = Join-Path $probe "payload.ps1"
Copy-Item -Path "C:\AzureData\CustomData.bin" -Destination $script -Force
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script
"payload-exit=$LASTEXITCODE" | Out-File -FilePath (Join-Path $probe "cse-wrapper.marker") -Encoding ascii
exit $LASTEXITCODE
