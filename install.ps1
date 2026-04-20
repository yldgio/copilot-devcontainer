<#
.SYNOPSIS
  Copies .devcontainer/ and .mcp.json into the current directory.

.DESCRIPTION
  Install the Copilot dev container into any repo.

.EXAMPLE
  irm https://raw.githubusercontent.com/yldgio/copilot-devcontainer/main/install.ps1 | iex

.EXAMPLE
  # Pinned version
  irm https://raw.githubusercontent.com/yldgio/copilot-devcontainer/main/install.ps1 -OutFile tmp_install.ps1
  .\tmp_install.ps1 -Version v1.0.0
  Remove-Item tmp_install.ps1

.EXAMPLE
  # Pinned version via iex using env var
  $env:DEVCONTAINER_VERSION = "v1.0.0"; irm https://raw.githubusercontent.com/yldgio/copilot-devcontainer/main/install.ps1 | iex
#>
param(
  [string]$Version,
  [switch]$Force
)

$ErrorActionPreference = "Stop"

# Env var fallbacks (for use with irm | iex)
if (-not $Version) { $Version = if ($env:DEVCONTAINER_VERSION) { $env:DEVCONTAINER_VERSION } else { "main" } }
if (-not $Force)   { $Force   = $env:DEVCONTAINER_FORCE -eq "1" }

$Repo = "yldgio/copilot-devcontainer"
$Dest = (Get-Location).Path

# ── Conflict check ────────────────────────────────────────────────────────────
if ((Test-Path "$Dest\.devcontainer") -and -not $Force) {
  Write-Host ""
  Write-Host "❌  .devcontainer/ already exists in $Dest" -ForegroundColor Red
  Write-Host "    Use -Force to overwrite:"
  Write-Host ""
  Write-Host '    $env:DEVCONTAINER_FORCE="1"; irm https://raw.githubusercontent.com/yldgio/copilot-devcontainer/main/install.ps1 | iex'
  Write-Host ""
  exit 1
}

# ── Build URL ─────────────────────────────────────────────────────────────────
# Accepts branch name, tag, or full commit SHA — GitHub resolves all three.
$Url = "https://github.com/$Repo/archive/$Version.zip"

# ── Download + extract to temp dir ───────────────────────────────────────────
$TmpDir  = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
$ZipFile = Join-Path $TmpDir "archive.zip"
$ExtDir  = Join-Path $TmpDir "extracted"
New-Item -ItemType Directory -Path $TmpDir | Out-Null

try {
  Write-Host ""
  Write-Host "  › Downloading $Repo@$Version ..."
  Invoke-WebRequest -Uri $Url -OutFile $ZipFile -UseBasicParsing
  Expand-Archive -Path $ZipFile -DestinationPath $ExtDir

  $Src = Get-ChildItem -Path $ExtDir -Directory | Select-Object -First 1 -ExpandProperty FullName
  if (-not $Src) {
    Write-Error "❌  Failed to extract archive." -ErrorAction Stop
  }

  $SrcDev = Join-Path $Src ".devcontainer"
  $SrcMcp = Join-Path $Src ".mcp.json"

  if (-not (Test-Path $SrcDev)) {
    Write-Error "❌  .devcontainer/ not found in archive. Wrong version?" -ErrorAction Stop
  }

  Write-Host "  › Installing files into $Dest ..."

  # Stage first, then move atomically to avoid partial state on interruption
  $Stage = Join-Path $TmpDir "stage"
  New-Item -ItemType Directory -Path $Stage | Out-Null

  Copy-Item -Recurse -Path $SrcDev -Destination (Join-Path $Stage ".devcontainer")
  Copy-Item           -Path $SrcMcp -Destination (Join-Path $Stage ".mcp.json")

  if ($Force) {
    if (Test-Path "$Dest\.devcontainer") { Remove-Item -Recurse -Force "$Dest\.devcontainer" }
    if (Test-Path "$Dest\.mcp.json")     { Remove-Item -Force          "$Dest\.mcp.json"     }
  }

  Move-Item -Path (Join-Path $Stage ".devcontainer") -Destination "$Dest\.devcontainer"
  Move-Item -Path (Join-Path $Stage ".mcp.json")     -Destination "$Dest\.mcp.json"

  Write-Host ""
  Write-Host "✅  Dev container files installed successfully." -ForegroundColor Green
  Write-Host "    Open this folder in VS Code and choose:"
  Write-Host "    Dev Containers: Reopen in Container"
  Write-Host ""
}
finally {
  Remove-Item -Recurse -Force $TmpDir -ErrorAction SilentlyContinue
}
