Function ThrowOnNonZeroExit {
  Param( [String]$Message )
  If ($LastExitCode -ne 0) {
    Throw $Message
  }
}

$ErrorActionPreference = 'Stop'

$sdkPath = (Resolve-Path "C:\Program Files (x86)\Windows Kits\10\bin\10.0.17763.0\x64")
$makePri = (Join-Path $sdkPath "makepri.exe")
$makeAppx = (Join-Path $sdkPath "makeappx.exe")
$version = "v1.2.3".TrimStart("v")

$distDir = (Resolve-Path dist)
$binaryArchives = Get-ChildItem -File -Filter *Windows*.tar.gz $distDir
if ($binaryArchives.count -ne 1) {
  Throw "Packaging error. build artifact contained $($binaryArchives.count) normally named windows binary archive files"
}

Remove-Item -Path build -Recurse -ErrorAction Ignore
$buildDir = New-Item -ItemType Directory -Path .\build\msix

# Add installer assets
$assetsDir = New-Item -ItemType Directory -Path (Join-Path $buildDir assets)
Copy-Item -Path .\scripts\winget\assets\* -Destination $assetsDir -Recurse | Out-Null

# Add manifest file
(Get-Content (Resolve-Path .\scripts\winget\AppxManifest.xml)).Replace('0.0.1.0', "$($version).0") | Set-Content (Join-Path $buildDir AppxManifest.xml)

# Generate pri resource map for installer assets
$priConfig = (Resolve-Path .\scripts\winget\priconfig.xml)
Push-Location $buildDir
& $makePri new /ProjectRoot $buildDir /ConfigXml $priConfig | Out-Null
ThrowOnNonZeroExit "Failed to create pri file"
Pop-Location

# Add algokit binaries
$binaryArchive = $binaryArchives[0]
tar -xf $binaryArchive -C $buildDir

# Generate msix
$packageFile = (Join-Path $distDir winget-algokit.msix) # TODO: NC - Name this better
& $makeAppx pack /o /h SHA256 /d $buildDir /p $packageFile | Out-Null
ThrowOnNonZeroExit "Failed to build msix"

# Code sign the msix
