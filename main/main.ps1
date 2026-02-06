<#
    .SYNOPSIS
        This script is used to install tools and configure them for use by me.
    
    .DESCRIPTION
        This script calls a lot of small installers
    
    .EXAMPLE
        .\main\main.ps1
   
#>
#requires -version 5.0
#requires -runasadministrator
Set-StrictMode -Version 2.0
$SaveErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Stop'

<#
    .SYNOPSIS
        This function is used to output any text - both to the console and to a log file.
#>
function global:logFileConsole {
  # Any printable string
  Param($lines)
  Write-Output $lines | Tee-Object -Append -FilePath "$env:TEMP\install-log.txt"
}

# Function to check if a command exists
function CommandExists {
  param (
    [string]$command
  )
  return Get-Command $command -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
Check if a package exists in Chocolatey.

.DESCRIPTION
This function checks if a specified package exists in the Chocolatey package manager.
#>
function Test-ChocoPackageExists {
  param (
    [string]$package
  )
  $found_match = (choco list | Select-String -Pattern $name) -replace "\s+\d+.*", ""
  return -ne $null $found_match
}

function Set-Git {
  if(get-process -ErrorAction SilentlyContinue "bash") {
      throw "Bash is running. Please close 'bash' and try again."
  }
  logFileConsole "Setting up git"
  & "$LocalRootPath/git/config_git.ps1"
}

function Set-WSL2 {
  logFileConsole "Setting up WSL"
  & "$LocalRootPath/wsl2/config_wsl2.ps1"
}

function Install-VSCodeExtensions {
  logFileConsole "Installing VSCode extensions"
  & "$LocalRootPath/extensions/vscode_extensions.ps1"
}

function Install-WindowsConfigurations {
  logFileConsole "Configuring Windows"
  & "$LocalRootPath/windows/configure_windows.ps1"
}

function Install-ChocoPackages {
  param (
    [array]$packages
  )
  foreach ($package in $packages) {
    $name = $package.name
    $install = $package.install
    $params = $package.params 
    
    if ($null -eq $package.params -or $package.params -eq '') {
      $params = $null
    }
    else {
      $params = $package.params
    }
  
    if ($install) {
      if ($params) {
        logFileConsole  "Installing $name with parameters $params"
        choco install -y $name --params=$params
        choco upgrade -y $name --params=$params
      } else {
        logFileConsole  "Upgrading $name without params"
        choco upgrade -y $name
      }
    }
    else {
      if (CommandExists -command $name) {
        logFileConsole  "Un-installing $name"
        choco uninstall -y $name
      }
    }
  }
}

function Test-PendingReboot
{
    if ($rebootPending = Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -EA Ignore) { 
      logFileConsole ("Reboot pending due to Component Based Servicing: " + ($rebootPending | Out-String))
      return $true
    }
    if ($rebootRequired = Get-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -EA Ignore) { 
      logFileConsole ("Reboot required due to Windows Update: " + ($rebootRequired | Out-String))
      return $true
    }
    
    # removed checking for pending rename because "Windows Defender Advanced Threat Protection" keeps leaving trash here
    
    try 
    { 
      $util = [wmiclass]"\\.\root\ccm\clientsdk:CCM_ClientUtilities"
      $status = $util.DetermineIfRebootPending()
      if(($null -ne $status) -and $status.RebootPending)
      {
        logFileConsole ("Reboot pending due to CCM Client Utilities: " + ($status | Out-String))
        return $true
      }
    }
    catch
    {
      # ignore all other errors about CCM_ClientUtilities
    }
    
    # pipe to "$null" prevents return from creating a return object in the next line
    logFileConsole "No pending reboot detected." > $null 
    return $false
}

################
# MAIN SECTION #
################


# Set the LocalRootPath variable globally
Set-Variable -Name LocalRootPath -Value (Split-Path $PSScriptRoot -Parent) -Scope Global

$starttime = (Get-Date -Format u)
logFileConsole "Starting installation at $starttime`r`n"


try {
  if (-not ((Get-WmiObject Win32_OperatingSystem).Caption -Match "Windows 11")) {
    throw "This script only works for Windows 11"
  }

  if (Test-PendingReboot) {
    throw "Pending Reboot detected. Please reboot and try again"
  }
  
  # Check if NuGet is installed, install if missing
  if (-not (CommandExists -command "nuget")) {
    Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false
  }
  
  # Import the required modules
  Install-Module -Name powershell-yaml -Scope CurrentUser

  # Check if Chocolatey is installed, install if missing
  if (-not (CommandExists -command "choco")) {
    logFileConsole  "Chocolatey is not installed. Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
  } else {
    logFileConsole  "Upgading Chocolatey..."
    choco upgrade chocolatey
  }

  # set defaults for WSL which is pre-installed in Windows 11
  Set-WSL2
  
  # Load the settings YAML file
  $settingsFilePath = "$LocalRootPath/settings.yaml"
  $config = Get-Content $settingsFilePath -Raw | ConvertFrom-Yaml

  # Install/upgrade packages based on the package manager
  if ($config.packages.choco) {
    Install-ChocoPackages -packages $config.packages.choco
  }

  # Check if Git is in path, add to path if it isn't
  if ( -not (CommandExists -command "git")) {
    logFileConsole "Git is not in path. Adding..."
    $env:PATH += ";$env:ProgramFiles\Git\bin" 
    # make it permanent:
    setx PATH $env:PATH -m
  }
  
  # Check if Git is installed, Configure if it is
  if (CommandExists -command "git") {
    logFileConsole "Git is installed. Configuring Git..."
    Set-Git
  } else {
    throw "git not installed - please open a Pull Request"
  }

  # Check if code is in path, add to path if it isn't
  if ( -not (CommandExists -command "code")) {
    logFileConsole "(vs)code is not in path. Adding..."
    $env:PATH += ";$env:ProgramFiles\Microsoft VS Code\bin" 
    # make it permanent:
    setx PATH $env:PATH -m
  }
  
  if (CommandExists -command "code") {
    Install-VSCodeExtensions -Extensions $config.extensions.vscode
  } else {
    throw "(vs)code not installed - please open a Pull Request"
  }

  if ($config.windows) {
    Install-WindowsConfigurations
  }

  
}
catch {
  logFileConsole $_.Exception | format-list -force
  logFileConsole $_.InvocationInfo | format-list -force
  Write-Host -NoNewLine 'Something went wrong, press any key to close.';
  $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
}

$endtime = (Get-Date -Format u)
logFileConsole "Ending installation at $endtime, running since $starttime.`r`n"
$ErrorActionPreference = $SaveErrorActionPreference
