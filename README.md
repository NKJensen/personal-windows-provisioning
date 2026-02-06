# personal-windows-provisioning
A boot-strap setup for new Windows 11 PC's to be used by me.

Usage:
Find the Green "CODE" button, click the "Local" tab, click "Download ZIP".

Open the zip file (Listed in "Downloads" or "Overførsler")

Mark the directory "personal-windows-provisioning-main" and copy

Enter 
```
%TEMP%
```
in the address bar

Paste from the clipboard.

You should see a directory called "personal-windows-provisioning-main" in the temp directory now.

Open a command box (WIN-R)

Run this command first: (Admin rights are needed)

```
powershell -Command "& { Start-Process -Wait Powershell -ArgumentList "'Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force; dir -s $env:TEMP\personal-windows-provisioning-main\*.* | Unblock-File '" -verb runAs }"
```
And this second command:

```
"%temp%\personal-windows-provisioning-main\runme.cmd"
```

After a while, your PC will be loaded with a nice set of tools - ready to go.

That's it - and please remember to send bug reports or simply tell me.
