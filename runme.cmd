@echo off
:: Aim: all setup files must be able to run on an existing setup without causing issues

echo Launching .ps1 with elavated permissions
call powershell -Command "& { Start-Process -Wait Powershell -ArgumentList "'Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force; %~dp0%main\main.ps1 '" -verb runAs }"

echo "Main ended with exit code: (0 is fine, press any key to continue)"
echo %errorlevel%
timeout 120

::reporting

echo ---------------------------------
if exist %TEMP%\install-log.txt (
    type %TEMP%\install-log.txt
    pause
) else ( 
    echo Something went wrong. Perhaps you need admin priviledges?
    pause
)
echo ---------------------------------

echo "Press Ctrl-C if you want to keep the install files and try again.
timeout 120

:: reporting done - cleanup

if exist %userprofile%\downloads\personal-windows-provisioning-main.zip (
    del %userprofile%\downloads\personal-windows-provisioning-main.zip
)

:: finish cleanup

if exist %temp%\personal-windows-provisioning-main\runme.cmd (
    del /s /f /q %temp%\personal-windows-provisioning-main
)
