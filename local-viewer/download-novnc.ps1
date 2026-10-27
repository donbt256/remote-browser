# Downloads the official noVNC client source into this folder.
# Run from the repository's local-viewer directory in PowerShell.
$ErrorActionPreference = "Stop"
$api = Invoke-RestMethod -Uri "https://api.github.com/repos/novnc/noVNC/releases/latest" -Headers @{ "User-Agent" = "remote-browser-local-viewer" }
$tag = $api.tag_name
if (-not $tag) { throw "Could not determine the latest noVNC release." }

$zip = Join-Path $env:TEMP "novnc-$tag.zip"
$extract = Join-Path $env:TEMP "novnc-$tag"
$target = Join-Path $PSScriptRoot "vendor\noVNC"

Invoke-WebRequest -Uri "https://github.com/novnc/noVNC/archive/refs/tags/$tag.zip" -OutFile $zip
if (Test-Path $extract) { Remove-Item $extract -Recurse -Force }
Expand-Archive -Path $zip -DestinationPath $extract -Force
$source = Get-ChildItem $extract -Directory | Select-Object -First 1
if (-not $source -or -not (Test-Path (Join-Path $source.FullName "core\rfb.js"))) {
  throw "The downloaded archive did not contain the expected noVNC client."
}
New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
if (Test-Path $target) { Remove-Item $target -Recurse -Force }
Copy-Item $source.FullName $target -Recurse
Write-Host "Installed noVNC $tag into $target"
Write-Host "Open README.md for how to serve the local viewer."
