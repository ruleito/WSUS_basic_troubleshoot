$services = "wuauserv","BITS","CryptSvc"

foreach ($service in $services) {
    Set-Service -Name $service -StartupType Automatic
    Start-Service -Name $service
}

Write-Host -ForegroundColor Yellow "step 1"


Write-Host -ForegroundColor Yellow "step 1.1"

foreach ($service in $services) {
    Stop-Service -Name $service -Verbose -Force
}
Set-Location $env:systemroot
Rename-Item -Path "C:\Windows\SoftwareDistribution" -NewName "C:\Windows\SoftwareDistribution.old"
Rename-Item -Path "%windir%\system32\catroot2" -NewName "catroot2.old"
Rename-Item -Path "%ALLUSERSPROFILE%\application data\Microsoft\Network\downloader" -NewName "downloader.old"


Write-Host -ForegroundColor Yellow "step 1.2"
cleanmgr /sageset:11

Write-Host -ForegroundColor Yellow "step 1.3: re-register a machine with the WSUS Server"
Get-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" | Remove-ItemProperty -Name "AccountDomainSid"   -verbose
Get-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" | Remove-ItemProperty -Name "PingID" -verbose
Get-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" | Remove-ItemProperty -Name "SusClientId" -verbose
Get-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" | Remove-ItemProperty -Name "SusClientIDValidation" -Verbose
Remove-Item -Path "C:\WINDOWS\SoftwareDistribution" -Recurse -Force -Confirm:$False

Write-Host -ForegroundColor Yellow "step 1.4 - started services"
foreach ($service in $services) {
    Start-Service -Name $service -Verbose
}


Write-Host -ForegroundColor Yellow "step 2: send reports"
sc start wuauserv
wuauclt /resetauthorization /detectnow
wuauclt /reportnow

Write-Host -ForegroundColor Yellow "step 3: Repair a corrupted BITS configuration"
sc config bits binpath= "%systemroot%\system32\svchost.exe –k netsvcs"
sc config bits depend= RpcSs/EventSystem
sc config bits start= delayed-auto
sc config bits type= interact type=own
sc config bits error= normal
sc config bits obj= LocalSystem
sc privs bits privileges= SeCreateGlobalPrivilege/SeImpersonatePrivilege/SeTcbPrivilege/SeAssignPrimaryTokenPrivilege/SeIncreateQuotaPrivilege
sc sidtype bits unrestricted
sc failure bits reset= 86400 actions=restart/60000/restart/120000

Write-Host -ForegroundColor Yellow "step 4"
Write-Host -ForegroundColor Yellow "Sending report to update server"
if ([Environment]::OSVersion.Version.Major -ge 10) {
    usoclient.exe refreshsettings
    usoclient.exe StartScan
} else {
    wuauclt.exe /resetauthorization
    wuauclt.exe /detectnow /reportnow
}

Write-Host -ForegroundColor Yellow "reboot your computer and check updates again"
