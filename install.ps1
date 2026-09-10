param(
  [Parameter(Mandatory=$true, Position=0)]
  [string]$Url,
  [ValidateSet('edge','chrome','auto')]
  [string]$Browser = 'auto'
)

$script = Join-Path $PSScriptRoot 'ext-install.ps1'
& $script -Url $Url -Browser $Browser
exit $LASTEXITCODE
