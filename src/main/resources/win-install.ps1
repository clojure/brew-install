#!/usr/bin/env pwsh

$ErrorActionPreference = 'Stop'

$Version = '${project.version}'
$ClojureToolsUrl = "https://download.clojure.org/install/clojure-tools-$Version.zip"

Write-Host 'Downloading Clojure tools' -ForegroundColor Gray
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
Invoke-WebRequest -Uri $ClojureToolsUrl -OutFile clojure-tools.zip

Write-Warning 'Clojure will install as a module in your PowerShell module path.'
Write-Host ''
Write-Host 'Possible install locations:'

$InstallLocations = $env:PSModulePath -split [IO.Path]::PathSeparator
for ($Index = 0; $Index -lt $InstallLocations.Length; $Index++) {
  Write-Host ('  {0}) {1}' -f ($Index + 1), $InstallLocations[$Index])
}
$Choice = Read-Host 'Enter number of preferred install location'
$DestinationPath = $InstallLocations[$Choice - 1]

Write-Host ''

$ExistingLocation = "$DestinationPath\ClojureTools"
if (Test-Path $ExistingLocation) {
  Write-Host 'Cleaning up existing install' -ForegroundColor Gray
  Remove-Item -Path $ExistingLocation -Recurse
}

Write-Host 'Installing PowerShell module'
Expand-Archive clojure-tools.zip -DestinationPath $DestinationPath

Write-Host 'Removing download'
Remove-Item clojure-tools.zip

Write-Host 'Clojure now installed. Use "clj -h" for help.' -ForegroundColor Green
