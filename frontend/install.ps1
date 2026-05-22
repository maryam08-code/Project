$ErrorActionPreference = "Stop"

$nodeDir = "C:\Program Files\nodejs"
if (-not (Test-Path (Join-Path $nodeDir "node.exe"))) {
  throw "Node.js tidak ditemukan di $nodeDir. Install Node.js LTS terlebih dahulu."
}

if (($env:Path -split ";") -notcontains $nodeDir) {
  $env:Path = "$nodeDir;$env:Path"
}

Set-Location $PSScriptRoot
& "$nodeDir\npm.cmd" install
