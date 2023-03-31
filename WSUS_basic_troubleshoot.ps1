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

Write-Host -ForegroundColor Yellow "step 1.2"
cleanmgr /sageset:11


Write-Host -ForegroundColor Yellow "step 1.3 - started services"
foreach ($service in $services) {
    Start-Service -Name $service -Verbose
}


Write-Host -ForegroundColor Yellow "step 2"
msdt.exe /id WindowsUpdateDiagnostic

Write-Host -ForegroundColor Yellow "step 3"
Write-Host -ForegroundColor Yellow "Sending report to update server"
if ([Environment]::OSVersion.Version.Major -ge 10) {
    usoclient.exe StartScan
} else {
    wuauclt.exe /resetauthorization
    wuauclt /detectnow /reportnow
}

Write-Host -ForegroundColor Yellow "reboot your computer and check updates again"
