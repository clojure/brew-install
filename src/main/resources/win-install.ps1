#!/usr/bin/env pwsh

$ErrorActionPreference = "Stop"

$Version="${project.version}"
$ClojureToolsUrl="https://download.clojure.org/install/clojure-tools-$Version.zip"

if (!(Test-Path "clojure-tools")) {
    echo "Downloading and expanding zip"
    Invoke-WebRequest -Uri $ClojureToolsUrl -OutFile "clojure-tools-$Version.zip"
    Expand-Archive "clojure-tools-$Version.zip" -DestinationPath .
}

if ($PSVersionTable.Platform -eq "Unix") {
    echo "Platform is unix"
    $DestinationPath="/usr/local"
} else {
    $DestinationPath="$env:APPDATA\Clojure"
}

echo "Installing libs into $DestinationPath"
@("clojure-tools/deps.edn", "clojure-tools/example-deps.edn") | Copy-Item -Destination $DestinationPath
Copy-Item "clojure-tools/clojure-tools-$Version.jar" "$DestinationPath"

echo "Installing clojure and clj into $DestinationPath"
if ($PSVersionTable.Platform -eq "Unix") {
    Get-Content "clojure-tools/clojure.ps1" | %{$_ -replace "__PREFIX__", "$DestinationPath" -replace "__VERSION__", "$Version"} > "$DestinationPath/clojure"
    Copy-Item "clojure-tools/clj.ps1" "$DestinationPath/clj"
    chmod 755 "$DestinationPath/clojure"
    chmod 755 "$DestinationPath/clj"
} else {
    Get-Content "clojure-tools/clojure.ps1" | %{$_ -replace "__PREFIX__", "$DestinationPath" -replace "__VERSION__", "$Version"} > "$DestinationPath/clojure.ps1"
    Copy-Item "clojure-tools/clj.ps1" "$DestinationPath\clj.ps1"
    Copy-Item "clojure-tools/clj.bat" "$DestinationPath/clj.bat"
    Copy-Item "clojure-tools/clojure.bat" "$DestinationPath/clojure.bat"

    $userPath=[Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User)
    if (!($userPath -contains $DestinationPath)) {
        $env:PATH += ";$DestinationPath"
        [Environment]::SetEnvironmentVariable("Path", "$userPath;$DestinationPath", [System.EnvironmentVariableTarget]::User)
    }
}

echo "Removing download"
Remove-Item -Recurse clojure-tools
Remove-Item "clojure-tools-$Version.zip"

echo "Use clj -h for help."
