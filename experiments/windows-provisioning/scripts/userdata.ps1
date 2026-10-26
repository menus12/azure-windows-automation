# Test B payload: if Azure ever executes user data, this leaves a marker.
New-Item -ItemType Directory -Force -Path "C:\probe" | Out-Null
"executed=$(Get-Date -Format o)" | Out-File -FilePath "C:\probe\userdata-autorun.marker" -Encoding ascii
