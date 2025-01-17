# Script to prepare Windows and installing the specified app from the MS Store
# By David Mear (July 2022)
# Updated Jan 2023 - Added better error handling for the critical components 
# Updated Mar 2023 - Provided a way to provide a custom application ID.
# Updated July 2023 - Improved the installation verification stage. 
# Updated Jan 2024 - Fixed an issue where installing applications from the WinGet repository, would show a UAC prompt. Fixed by allowing System to install the application machine-wide

# Script Pre-Reqs & Variables
    ## Install NuGet
    try {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    } catch {
        Write-Output 'Unable to install NuGet Package Provider. Script cannot continue!'; Exit 1
    }
    ## Set PSGallery Repository as Trusted
    Try {
        Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
    } Catch {
        Write-Output 'Unable to set PSGallery as trusted repository. Script cannot continue!'; Exit 1
    }
    ## Install RunAsUser Module
    Try {
        install-module RunAsUser -Force
    } Catch {
        Write-Output 'Unable to install RunAsUser Module. Script cannot continue'; Exit 1
    }
    ## Create temporary path
    Try {
        If (!(Test-Path -Path 'C:\Temp')) {
            New-Item -Path "C:\Temp" -Type Directory -Force
        }    
    } Catch {
        Write-Output 'Unable to create temp directory. Script cannot continue'; Exit 1
    }
# Install WinGet SystemWide
Try {
    #WebClient
    $dc = New-Object net.webclient
    $dc.UseDefaultCredentials = $true
    $dc.Headers.Add("user-agent", "Inter Explorer")
    $dc.Headers.Add("X-FORMS_BASED_AUTH_ACCEPTED", "f")

    #temp folder
    $InstallerFolder = $(Join-Path $env:ProgramData CustomScripts)
    if (!(Test-Path $InstallerFolder)) {
        New-Item -Path $InstallerFolder -ItemType Directory -Force -Confirm:$false
    }   
    #Check Winget Install
    Write-Host "Checking if Winget is installed" -ForegroundColor Yellow
    $TestWinget = Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq "Microsoft.DesktopAppInstaller"}
    If ([Version]$TestWinGet. Version -gt "2022.506.16.0") {
        Write-Host "WinGet is Installed" -ForegroundColor Green
    } Else {
        #Download WinGet MSIXBundle
        Write-Host "Not installed. Downloading WinGet..." 
        $WinGetURL = "https://aka.ms/getwinget"
        $dc.DownloadFile($WinGetURL, "$InstallerFolder\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle")
    
        #Install WinGet MSIXBundle 
        Try 	{
            Write-Host "Installing MSIXBundle for App Installer..." 
            Add-AppxProvisionedPackage -Online -PackagePath "$InstallerFolder\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -SkipLicense 
            Write-Host "Installed MSIXBundle for App Installer" -ForegroundColor Green
        } Catch {
            Write-Host "Failed to install MSIXBundle for App Installer..." -ForegroundColor Red
            } 
        }   
    } Catch {
        Write-Output 'Unable to install WinGet. Script cannot continue'; Exit 1
    }
    ## Output App ID to file
    if ($null -eq $env:usrAppName) {
        Write-Output 'Custom ID has been selected'
        If ($null -eq $env:usrAppID) {
            Write-Output 'Custom ID has not been provided. Please run again and provide an AppID'; Exit 1
        } else {
            $env:usrAppID | Out-File 'C:\Temp\appid.txt'
        }
    } else {
        $env:usrAppName | Out-File 'C:\Temp\appid.txt'
}
$ResolveWingetPath = Resolve-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe"
if ($ResolveWingetPath){
    $WingetPath = $ResolveWingetPath[-1].Path

}
$application = Get-Content -Path 'C:\Temp\Temp\appid.txt'

############### SCRIPT START ###############
$installScript = {$URL = 'https://github.com/microsoft/winget-cli/releases/download/v1.3.1872/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'
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
# Check which repository the application is installed from (msstore/winget)
$msstoreResult = winget search --source msstore $application
$msstoreAvailable = $msstoreResult -match $application
$wingetResult = winget search --source winget $application
$wingetAvailable = $wingetResult -match $application

# Lets get it installed
if ($msstoreAvailable) {
    Write-Output "The app ID '$application' is available in the Microsoft Store."
    & $wingetsys install --id=$application -e -h --source msstore --accept-package-agreements --accept-source-agreements | ConvertTo-Json | Out-File 'C:\Temp\Temp\WinGet.txt'
} elseif ($wingetAvailable) {
    Write-Output "The app ID '$application' is available in the WinGet repository." | ConvertTo-Json | Out-File 'C:\Temp\Temp\WinGet.txt'
} else {
    Write-Output "The app ID '$application' is not available for installation via WinGet" | ConvertTo-Json | Out-File 'C:\Temp\Temp\WinGet.txt'
}
}
############### END ###############

# Attempt install
invoke-ascurrentuser -scriptblock $installScript

# Collect Output and display to RMM
$Output = (get-content "C:\Temp\WinGet.txt" | convertfrom-json)

# Remove Log Files
Remove-Item -Path 'C:\Temp\WinGet.txt' -Force
Remove-Item -Path 'C:\Temp\appid.txt' -Force

If ($Output -Like '*is available in the WinGet repository.') {
    Set-Location $wingetpath
    $Output = .\winget.exe install --id $application --source winget --silent --scope machine
}

# Verify the install completed successfully
if ($Output -like '*Found an existing package*') {
    Write-Output 'Application already installed. Nothing to do!'; Exit
} elseif ($Output -like '*Successfully installed') {
    Write-Output 'Application installed successfully'; Exit
} else {
    $Output
    Write-Output 'Windows Store Application failed to install - Check above output for diagnostic information'; Exit 1
}
