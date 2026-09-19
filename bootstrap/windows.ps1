#Requires -Version 5.1
<#
.SYNOPSIS
  Full-stack Windows bootstrap: IDE + extensions + shell links + gh/glab.
  Never overwrites company *.local / proxy / credentials.
#>
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

Write-Host "=== Windows full-stack bootstrap ==="
Write-Host "dotfiles: $Root"

function Ensure-WingetApp([string]$Id) {
  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "skip winget missing: $Id"
    return
  }
  Write-Host "winget install $Id (idempotent)"
  winget install --id $Id -e --accept-source-agreements --accept-package-agreements --silent 2>$null | Out-Null
}

function Ensure-Dir([string]$Path) {
  if (-not (Test-Path $Path)) {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
    Write-Host "create $Path"
  } else {
    Write-Host "keep  $Path"
  }
}

# Apps
Ensure-WingetApp "Git.Git"
Ensure-WingetApp "Microsoft.VisualStudioCode"
Ensure-WingetApp "Anysphere.Cursor"
Ensure-WingetApp "GitHub.cli"

# glab (best-effort)
if (-not (Get-Command glab -ErrorAction SilentlyContinue)) {
  if (Get-Command winget -ErrorAction SilentlyContinue) {
    winget install --id GLab.GLab -e --accept-source-agreements --accept-package-agreements --silent 2>$null | Out-Null
  }
}

# Agent dirs (no secrets copied)
Ensure-Dir "$env:USERPROFILE\.cursor"
Ensure-Dir "$env:USERPROFILE\.copilot\skills"
Ensure-Dir "$env:USERPROFILE\.claude"

# Shell + IDE links via Git Bash install.sh
$bash = "C:\Program Files\Git\bin\bash.exe"
if (Test-Path $bash) {
  Write-Host "running install.sh via Git Bash..."
  & $bash -lc "cd '$($Root -replace '\\','/')' && chmod +x install.sh doctor.sh dry-run.sh harvest.sh uninstall.sh && ./install.sh"
} else {
  Write-Host "WARN Git Bash not found; run ./install.sh manually after Git installs"
}

# Extensions
$cursorExt = Join-Path $Root "config\extensions-cursor.txt"
$vscodeExt = Join-Path $Root "config\extensions-vscode.txt"
if ((Test-Path $cursorExt) -and (Get-Command cursor -ErrorAction SilentlyContinue)) {
  Get-Content $cursorExt | ForEach-Object {
    if ($_ -and -not $_.StartsWith("#")) {
      Write-Host "cursor --install-extension $_"
      cursor --install-extension $_ 2>$null | Out-Null
    }
  }
}
if ((Test-Path $vscodeExt) -and (Get-Command code -ErrorAction SilentlyContinue)) {
  Get-Content $vscodeExt | ForEach-Object {
    if ($_ -and -not $_.StartsWith("#")) {
      Write-Host "code --install-extension $_"
      code --install-extension $_ 2>$null | Out-Null
    }
  }
}

Write-Host ""
Write-Host "Interactive auth (tokens stay local):"
Write-Host "  gh auth login"
Write-Host "  glab auth login"
Write-Host "Company overlay: never modified. Run: bash company/verify-company.sh"
Write-Host "Done."
