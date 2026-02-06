<#
    .SYNOPSIS
        This script sets up vscode extensions.
    
    .DESCRIPTION
        You can add extra extensions. See the current list of extensions using this command:

        code --list-extensions
    
    .EXAMPLE
        .\vscode-extensions.ps1
   
#>
#requires -version 5.0
Set-StrictMode -Version 2.0

# By NKJensen and Frey Clante
try {
    # Script for batch installing Visual Studio Code extensions
    if (-not (CommandExists -command "code")) {
        throw "VsCode is not installed, run main.ps1 before running this script!"
    }

    # Import the YAML module
    Install-Module -Name powershell-yaml -Scope CurrentUser

    # Read and parse the YAML file
    $config = Get-Content "$LocalRootPath/settings.yaml" -Raw | ConvertFrom-Yaml

    $extensions = $config.extensions.vscode

    $cmd = "code --list-extensions"
    Invoke-Expression $cmd -OutVariable output | Out-Null
    $installed = $output -split "\s"

    foreach ($ext in $extensions) {
        if ($installed.Contains($ext.id)) {
            logFileConsole $ext.id+" already installed."
        } else {
            logFileConsole "Installing "+$ext.id+" ..."
            code --install-extension $ext.id
        }
    }
}
Catch
{
    logFileConsole $_.Exception | format-list -force
    logFileConsole $_.InvocationInfo | format-list -force
    Write-Host -NoNewLine 'Something went wrong, press any key to close.';
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
}
