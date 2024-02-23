Param(
  [Parameter(Mandatory=$true)]
  [String]
  $releaseVersion,
)

Function ThrowOnNonZeroExit {
  Param( [String]$Message )
  If ($LastExitCode -ne 0) {
    Throw $Message
  }
}

# $wingetPackage = 'AlgorandFoundation.AlgoKit' TODO: NC - Put this back
$wingetPackage = 'Microsoft.PowerToys'

$release = Invoke-RestMethod -uri "https://api.github.com/repos/neilcampbell/algokit-cli/releases/tags/$releaseVersion"
$installerUrl = $release | Select -ExpandProperty assets -First 1 | Where-Object -Property name -match '*windows_x64-winget.msix' | Select -ExpandProperty browser_download_url
$releaseVersion = $releaseVersion.Trim("v")

# TODO: NC - Move to a new file + fix the path stuff here
$wingetDir = New-Item -Force -ItemType Directory -Path .\build\winget
Invoke-WebRequest https://aka.ms/wingetcreate/latest -OutFile .\build\winget\wingetcreate.exe
.\build\winget\wingetcreate.exe update $wingetPackage -s -v $releaseVersion -u "$installerUrl" -t "$env:WINGET_GITHUB_TOKEN"
ThrowOnNonZeroExit "Failed to update winget package"
