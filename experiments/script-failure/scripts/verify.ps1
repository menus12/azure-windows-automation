# Inspection script, run with `az vm run-command invoke` on each VM.
Get-ChildItem C:\probe -Filter *.marker -ErrorAction SilentlyContinue | ForEach-Object { "--- $($_.Name)"; Get-Content $_.FullName }
