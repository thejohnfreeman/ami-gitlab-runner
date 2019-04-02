$keysFile = [IO.Path]::Combine($env:ProgramData, 'ssh', 'authorized_keys')
Remove-Item -Recurse -Force -Path $keysFile

Enable-ScheduledTask 'Download Key Pair'

echo 'InitializeInstance'
& Powershell.exe C:/ProgramData/Amazon/EC2-Windows/Launch/Scripts/InitializeInstance.ps1 -Schedule
if ($LASTEXITCODE -ne 0) {
    throw('Failed to InitializeInstance')
}

ssh -V
docker --version

echo 'SysprepInstance'
& Powershell.exe C:/ProgramData/Amazon/EC2-Windows/Launch/Scripts/SysprepInstance.ps1 -NoShutdown
if ($LASTEXITCODE -ne 0) {
    throw('Failed to SysprepInstance')
}
