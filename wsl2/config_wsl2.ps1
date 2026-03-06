<#
    .SYNOPSIS
        This script configures wsl2 which is pre-installed in Windows 11
    
    .DESCRIPTION
        Set default distro

    .EXAMPLE
        .\config_wsl2.ps1
   
#>
#requires -version 5.0
Set-StrictMode -Version 2.0

# By nkj@internetgruppen.dk
try {
    $output = & wsl --install -d Ubuntu --no-launch --web-download 2>&1
    logFileConsole $output}
Catch
{
    logFileConsole $_.Exception | format-list -force
    logFileConsole $_.InvocationInfo | format-list -force
    Write-Host -NoNewLine 'Something went wrong, press any key to close.';
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
}
