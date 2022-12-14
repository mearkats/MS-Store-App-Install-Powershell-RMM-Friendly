# Script to prepare Windows and installing the specified app from the MS Store
# By David Mear (July 2022)

# Script Pre-Reqs & Variables
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force #Install NuGet
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
install-module RunAsUser 
$ErrorActionPreference = "SilentlyContinue"
New-Item -Path "C:\Temp" -Type Directory
$env:usrAppName | Out-File 'C:\Temp\appid.txt'

############### SCRIPT START ###############
$installScript = { $URL = 'https://github.com/microsoft/winget-cli/releases/download/v1.3.1872/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'
$destination = 'C:\Temp\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'
$wingetversion = winget --version 
$wingetversion = $wingetversion.split('.')[1].Trim()
$application = Get-Content -Path 'C:\Temp\appid.txt'

# Check Version
if ($wingetversion -lt 3) {
  Write-Output 'WinGet is not on the right version... lets fix that!..'
  Invoke-WebRequest -Uri $URL -OutFile $destination -UseBasicParsing
  if (!(Test-Path -Path $destination)) {
      Write-Output 'Download did not succeed for WinGet - Exiting'
      Exit 1
  }
  Add-AppxPackage -Path $destination
}

$WingetCmd = Get-Command winget.exe -ErrorAction SilentlyContinue

if ($WingetCmd){
$wingetsys = $WingetCmd.Source
} elseif (Test-Path  "$env:ProgramW6432\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\AppInstallerCLI.exe"){
    $wingetsys = Resolve-Path  "$env:ProgramW6432\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\AppInstallerCLI.exe" | Select-Object -ExpandProperty Path
} elseif (Test-Path  "$env:ProgramW6432\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\winget.exe"){
    $wingetsys = Resolve-Path  "$env:ProgramW6432\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\winget.exe" | Select-Object -ExpandProperty Path
} else {
    Write-Host "WinGet not Installed."
    return
}

# Lets get it installed!
& $wingetsys install --id=$application -e -h --accept-package-agreements --accept-source-agreements | ConvertTo-Json | Out-File 'C:\Temp\WinGet.txt'
}
############### END ###############

# Attempt install
invoke-ascurrentuser -scriptblock $installScript

# Collect Output and display to RMM
$Output = (get-content "C:\Temp\WinGet.txt" | convertfrom-json)
$Output

# Remove Log Files
Remove-Item -Path 'C:\Temp\WinGet.txt' -Force
Remove-Item -Path 'C:\Temp\appid.txt' -Force

# Verify the install completed successfully
if ($Output -LIKE '*Successfully installed') {
    Write Output 'Windows Store Application installed successfully'; Exit
} else {
    Write-Output 'Windows Store Application failed to install - Check above output for diagnostic information'; Exit 1
}
