# Package n64-decomp.skill from a clean staging folder (fast; avoids dist/workspace bloat).
# Usage: powershell -File scripts/package_release.ps1

$ErrorActionPreference = "Stop"
$Root = Split-Path $PSScriptRoot -Parent
$Stage = Join-Path $Root "dist\n64-decomp"
$OutDir = Join-Path $Root "dist"
$SkillCreator = Join-Path $env:USERPROFILE ".agents\skills\skill-creator"

foreach ($sub in @("resources", "scripts", "examples")) {
    New-Item -ItemType Directory -Force -Path (Join-Path $Stage $sub) | Out-Null
}
Copy-Item (Join-Path $Root "SKILL.md") $Stage -Force
Copy-Item (Join-Path $Root "resources\*") (Join-Path $Stage "resources\") -Force
Copy-Item (Join-Path $Root "scripts\configure_min.py") (Join-Path $Stage "scripts\") -Force
Copy-Item (Join-Path $Root "scripts\project-state-template.md") (Join-Path $Stage "scripts\") -Force
Copy-Item (Join-Path $Root "examples\*") (Join-Path $Stage "examples\") -Force

# Remove accidental multi-GB artifacts from dist (recursive package mistake)
Get-ChildItem $OutDir -Filter "*.skill" -File | Where-Object { $_.Length -gt 10MB } | ForEach-Object {
    Write-Warning "Removing bloated artifact: $($_.FullName) ($([math]::Round($_.Length/1MB)) MB)"
    Remove-Item $_.FullName -Force
}

Push-Location $SkillCreator
python -m scripts.package_skill $Stage $OutDir
Pop-Location

$artifact = Join-Path $OutDir "n64-decomp.skill"
if (Test-Path $artifact) {
    $kb = [math]::Round((Get-Item $artifact).Length / 1KB, 1)
    Write-Host "OK: $artifact ($kb KB)"
}
