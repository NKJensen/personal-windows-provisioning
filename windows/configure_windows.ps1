# configure-windows.ps1

# Import the required modules
Install-Module -Name powershell-yaml -Scope CurrentUser

$settingsFilePath = "$LocalRootPath/settings.yaml"

# Read and parse the YAML file
$config = Get-Content $settingsFilePath -Raw | ConvertFrom-Yaml

# Apply language setting
Set-WinUILanguageOverride -Language $config.windows.language

# Apply region setting
Set-WinUserLanguageList -LanguageList $config.windows.region -Force

# Optionally, set the system locale (which can affect some apps)
Set-WinSystemLocale -SystemLocale $config.windows.language

# Apply font size setting (example for console font size)
Set-ItemProperty -Path 'HKCU:\Console\' -Name 'FontSize' -Value $config.windows.fontSize

# Apply cursor speed setting
Set-ItemProperty -Path 'HKCU:\Control Panel\Mouse' -Name 'MouseSensitivity' -Value $config.windows.cursorSpeed

# Apply notifications setting
if ($config.windows.notifications) {
    Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings' -Name 'NOC_GLOBAL_SETTING_TOASTS_ENABLED'
}
else {
    # Disable system notifications
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications' -Name 'ToastEnabled' -Value 0
    
    # Disable app notifications
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings' -Name 'NOC_GLOBAL_SETTING_TOASTS_ENABLED' -Value 0
    logFileConsole "Notifications disabled."
}

# Apply time format setting
Set-ItemProperty -Path 'HKCU:\Control Panel\International' -Name 'sShortTime' -Value $config.windows.timeFormat.shortTime
Set-ItemProperty -Path 'HKCU:\Control Panel\International' -Name 'sLongTime' -Value $config.windows.timeFormat.longTime

logFileConsole "Windows Configuration applied successfully."