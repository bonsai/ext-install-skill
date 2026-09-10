param(
  [Parameter(Mandatory=$true, Position=0)]
  [string]$Url,
  [ValidateSet('edge','chrome','auto')]
  [string]$Browser = 'auto'
)

$ErrorActionPreference = 'Stop'

function Get-BrowserPath {
  param([string]$Name)
  $candidates = @()
  if ($Name -in @('edge','auto')) {
    $candidates += @(
      "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
      "$env:ProgramFiles(x86)\Microsoft\Edge\Application\msedge.exe",
      "$env:LOCALAPPDATA\Microsoft\Edge\Application\msedge.exe"
    )
  }
  if ($Name -in @('chrome','auto')) {
    $candidates += @(
      "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
      "$env:ProgramFiles(x86)\Google\Chrome\Application\chrome.exe",
      "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
    )
  }
  foreach ($path in $candidates) {
    if ($path -and (Test-Path $path)) { return $path }
  }
  $cmd = if ($Name -eq 'edge') { 'msedge' } elseif ($Name -eq 'chrome') { 'chrome' } else { $null }
  if ($cmd) {
    $found = Get-Command $cmd -ErrorAction SilentlyContinue
    if ($found) { return $found.Source }
  }
  return $null
}

if ([string]::IsNullOrWhiteSpace($Url)) { throw 'usage: .\ext-install.ps1 <url> [-Browser edge|chrome|auto]' }

$browserPath = Get-BrowserPath $Browser
if (-not $browserPath) { throw "Browser not found: $Browser" }

Write-Host "[1/2] browser: $browserPath"
Write-Host "[2/2] open:    $Url"

# URL-first bridge: the Skill hands the URL to the browser layer.
Start-Process -FilePath $browserPath -ArgumentList @('--new-window', $Url)
Write-Host 'Browser action dispatched.'
