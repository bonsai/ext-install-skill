param(
  [Parameter(Mandatory=$true, Position=0)]
  [string]$Repository,
  [ValidateSet('edge','chrome','auto')]
  [string]$Browser = 'auto',
  [string]$Url = ''
)

$ErrorActionPreference = 'Stop'

function Normalize-Repository {
  param([string]$Value)
  $v = $Value.Trim()
  if ($v -match '^https://github\.com/([^/]+)/([^/#?]+?)(?:\.git)?/?$') {
    return "$($Matches[1])/$($Matches[2])"
  }
  if ($v -match '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') { return $v }
  throw "GitHub repository must be owner/repo or https://github.com/owner/repo: $Value"
}

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
    if ($path -and (Test-Path $path -PathType Leaf)) { return $path }
  }
  if ($Name -eq 'edge') { $cmd = 'msedge' }
  elseif ($Name -eq 'chrome') { $cmd = 'chrome' }
  else { $cmd = $null }
  if ($cmd) {
    $found = Get-Command $cmd -ErrorAction SilentlyContinue
    if ($found) { return $found.Source }
  }
  return $null
}

function Find-Manifest {
  param([string]$Root)
  $rootManifest = Join-Path $Root 'manifest.json'
  if (Test-Path $rootManifest -PathType Leaf) { return $Root }
  $found = Get-ChildItem -Path $Root -Filter 'manifest.json' -File -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName.Split([IO.Path]::DirectorySeparatorChar).Count -le ($Root.Split([IO.Path]::DirectorySeparatorChar).Count + 3) } |
    Select-Object -First 1
  if ($found) { return $found.DirectoryName }
  throw "manifest.json not found under $Root"
}

$repo = Normalize-Repository $Repository
$parts = $repo.Split('/')
$base = if ($env:LOCALAPPDATA) { Join-Path $env:LOCALAPPDATA 'ext-install' } else { Join-Path $HOME '.local/share/ext-install' }
$dir = Join-Path $base "$($parts[0])-$($parts[1])"
New-Item -ItemType Directory -Force -Path $base | Out-Null

Write-Host "[1/3] source: $dir"
if (Test-Path (Join-Path $dir '.git')) {
  git -C $dir pull --ff-only
  if ($LASTEXITCODE -ne 0) { throw "git pull failed ($LASTEXITCODE)" }
} else {
  gh repo clone $repo $dir
  if ($LASTEXITCODE -ne 0) {
    git clone "https://github.com/$repo.git" $dir
    if ($LASTEXITCODE -ne 0) { throw "git clone failed ($LASTEXITCODE)" }
  }
}

$extensionDir = Find-Manifest $dir
$manifestPath = Join-Path $extensionDir 'manifest.json'
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
if ($manifest.manifest_version -notin @(2,3)) { throw 'manifest_version must be 2 or 3' }
if ([string]::IsNullOrWhiteSpace($manifest.name)) { throw 'manifest.json has no name' }

Write-Host "[2/3] manifest: $manifestPath"
Write-Host "      name: $($manifest.name)"

$browserPath = Get-BrowserPath $Browser
if (-not $browserPath) { throw "Browser not found: $Browser" }

$args = @("--load-extension=$extensionDir")
if ($Url) { $args += @('--new-window', $Url) }
Write-Host "[3/3] launch: $browserPath"
Write-Host "      --load-extension=$extensionDir"
Start-Process -FilePath $browserPath -ArgumentList $args
Write-Host "Installed and launched: $($manifest.name)"
