<#
    .SYNOPSIS
        This script is used to configure git-for-windows silently.
    
    .DESCRIPTION
        This script is used to set a default setup for git-for-windows.
    
    .EXAMPLE
        .\config_git.ps1
   
#>

# By nkj@internetgruppen.dk

#requires -version 5.0
#requires -runasadministrator

# put git config on a local dir - not on some funny network drive, otherwise it will be very slow and cause all kinds of weird issues
# https://www.tutorialpedia.org/blog/change-the-location-of-the-directory-in-a-windows-install-of-git-bash/#why-move-from-network-to-local

setx HOME %USERPROFILE% 

Set-StrictMode -Version 2.0
$SaveErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'SilentlyContinue'

Push-Location $env:Temp
$ProgressPreference = 'SilentlyContinue' # Much faster than Continue

try {
    $UserName = ${env:UserName}
        
    # Just in case, must be set to something, otherwise error occurs
    $env:HOME = $env:USERPROFILE

    $git = "${env:ProgramFiles}\git\bin\git.exe"

    try {
        $searcher = [adsisearcher]"(samaccountname=$env:USERNAME)"
        $email = $searcher.FindOne().Properties.mail
        $email = $email.ToLower()
        $displayname = $searcher.FindOne().Properties.displayname
    } catch {
        # look up email and display name from existing git config, if it exists
        if (Test-Path -Path $git) {
            $email = & $git config --global user.email
            # 1. Save current encoding so we don't break other tools later
            $originalEncoding = [Console]::OutputEncoding
            # 2. Tell PowerShell to interpret external command output as UTF-8
            [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

            $displayname = & $git config --global user.name

            # 3. Restore the original encoding
            [Console]::OutputEncoding = $originalEncoding
        }
        # If we still don't have email and display name, ask the user to input them
        if(-not $email -or -not $displayname){
            Write-Host 'Could not get email/username from server or old config, please check Network Connection and run again by pressing ENTER - OR:'
            Write-Host -NoNewLine 'Type your email: '
            $email = Read-Host
            if(-not $email){
                logFileConsole "Email is empty, exiting"
                exit 1
            }
            Write-Host -NoNewLine 'Type your display name: '
            $displayname = Read-Host
            if(-not $displayname){
                logFileConsole "Display name is empty, exiting"
                exit 1
            }
        }
    }

    logFileConsole "Configuring Git with name and e-mail: $($displayname) and $($email)"
    
    & $git config --global --replace-all user.name "$displayname"
    & $git config --global --replace-all user.email $email
    & $git config --system --replace-all push.default upstream
    & $git config --system --replace-all http.sslverify true
    & $git config --system --replace-all core.longpaths true
    & $git config --system --replace-all core.autocrlf input # To make sure windows files with CRLF are converted to LF on the way in to the .git database
    & $git config --system --replace-all http.sslbackend schannel
    & $git config --system --replace-all init.defaultbranch main
    & $git config --system --replace-all push.autoSetupRemote true
    & $git config --global --unset-all push.default
    & $git config --global --unset-all http.sslverify
    & $git config --global --unset-all core.longpaths
    & $git config --global --unset-all core.autocrlf
    & $git config --global --unset-all http.sslbackend
    & $git config --global --unset-all init.defaultbranch
    & $git config --global --unset-all push.autoSetupRemote
    # Set Visual Studio Code as the diff and merge tool
    & $git config --global diff.tool vscode
    & $git config --global difftool.vscode.cmd 'code --wait --diff $LOCAL $REMOTE'
    & $git config --global merge.tool vscode
    & $git config --global mergetool.vscode.cmd 'code --wait $MERGED'

    #Checking if git-LFS was installed.
    git lfs --version
    if($?){
        logFileConsole "OK: git-LFS is installed"
    }
    else{
        logFileConsole "git-LFS is NOT installed. Installed it from https://git-lfs.github.com/"
        
    }

    $ssh_public_key_file_name = "${Env:HOME}\.ssh\id_rsa.pub"
    # create a ssh key pair
    try {
        if (-Not (Test-Path -Path "$ssh_public_key_file_name"))
        {
            # create a .ssh dir if not there
            New-Item -ItemType Directory -Force -Path "${Env:HOME}\.ssh"
            # Generate a new key
            & "${Env:ProgramFiles}\git\usr\bin\ssh-keygen.exe" -q -t rsa -N '""' -f ${Env:HOME}\.ssh\id_rsa
        }

        if (Test-Path -Path "$ssh_public_key_file_name")
        {
            logFileConsole "SSH keys found, please copy contents of $ssh_public_key_file_name to SSH-keys section under your Github profile"
        } else {
            logFileConsole "SSH key generation failed - please open a Pull Request"
            exit 1
        }
    }
    
    catch {
        logFileConsole $_.Exception | format-list -force
        logFileConsole $_.InvocationInfo | format-list -force
        Write-Host -NoNewLine 'Could not generate SSH keys pair. Press any Key to close.';
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
        exit
    }
    
    $ProgressPreference = 'Continue'
    Pop-Location
}
Catch
{
    logFileConsole $_.Exception | format-list -force
    logFileConsole $_.InvocationInfo | format-list -force
    Write-Host -NoNewLine 'Something went wrong, press any key to close.';
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
}

$ErrorActionPreference = $SaveErrorActionPreference
