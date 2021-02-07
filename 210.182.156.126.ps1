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

#Import Module
$modulePath = Join-Path -Path $(Get-ScriptDirectory) -ChildPath "PowerShellLogging"

Import-Module -Name $modulePath
$LogFile = Enable-LogFile -Path $(Join-Path -Path $(Get-ScriptDirectory) -ChildPath "logs\StartMining.txt")
Write-Host "Import Module: $modulePath" 

Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Stop-Process -Name foreLauncher -Force -ErrorAction SilentlyContinue
Stop-Process -Name explorer -ErrorAction SilentlyContinue

Start-Process -FilePath "forePatchGuest.exe" -WorkingDirectory "C:\forePatchGuest" -ArgumentList "restore" -Wait -ErrorAction SilentlyContinue
Start-Process -FilePath "forePatchGuest.exe" -WorkingDirectory "C:\forePatchGuest" -ErrorAction SilentlyContinue

# Close Pica
Stop-Process -Name pmclient -Force -ErrorAction SilentlyContinue
Stop-Process -Name pmLC -Force -ErrorAction SilentlyContinue
Stop-Service -Name pmsys -Force -ErrorAction SilentlyContinue

Stop-Process -Name iexplore -Force -ErrorAction SilentlyContinue
Stop-Process -Name chrome -Force -ErrorAction SilentlyContinue
Stop-Process -Name MicrosoftEdge -Force -ErrorAction SilentlyContinue

# Start Mining\MSI Afterburner
$objProfile = ConvertFrom-Json $strProfile
$contentCfg = @"
[Startup]
Format=2
PowerLimit=$($objProfile.PowerLimit)
ThermalLimit=$($objProfile.ThermalLimit)
ThermalPrioritize=0
CoreClkBoost=$($objProfile.CoreClkBoost)
MemClkBoost=$($objProfile.MemClkBoost)
FanMode=$($objProfile.FanMode)
FanSpeed=$($objProfile.FanSpeed)
"@
Write-Host $contentCfg
$vga = Get-WmiObject -class Win32_VideoController -Property Name, PNPDeviceID | Where-Object {$_.Name -like "*NVIDIA*"}
Write-Host "NVIDIA Name: $($vga.Name)" 
Write-Host "Cfg Path: $burnerCfgPath" 
$burnerCfgPath = Join-Path -Path $(Get-ScriptDirectory) -ChildPath "MSI Afterburner\Profiles\$($vga.PNPDeviceID.Split('\')[1])&BUS_1&DEV_0&FN_0.cfg"
Set-Content -Path $burnerCfgPath -Value $contentCfg -Force -Encoding Ascii
Write-Host "Start MSI Afterburner" 
Start-Process -FilePath "MSIAfterburner.exe" -WorkingDirectory $(Join-Path -Path $(Get-ScriptDirectory) -ChildPath "MSI Afterburner")

# Start Mining\PhoenixMiner_5.4c_Windows
$contetnPhoenix = @"
setx GPU_FORCE_64BIT_PTR 0
setx GPU_MAX_HEAP_SIZE 100
setx GPU_USE_SYNC_OBJECTS 1
setx GPU_MAX_ALLOC_PERCENT 100
setx GPU_SINGLE_ALLOC_PERCENT 100
set name=%COMPUTERNAME%
PhoenixMiner.exe -pool asia.ethash-hub.miningpoolhub.com:20535 -wal $miningId.%name% -pass x -proto 1 -cdm 2
"@
$phoenixStartPath = Join-Path -Path $(Get-ScriptDirectory) -ChildPath "PhoenixMiner_5.4c_Windows\start.bat"
Write-Host "PhoenixMiner Path: $phoenixStartPath" 
Set-Content -Path $phoenixStartPath -Value $contetnPhoenix -Force -Encoding Ascii
Write-Host "Start PhoenixMiner" 
Start-Process -FilePath "start.bat" -WorkingDirectory $(Join-Path -Path $(Get-ScriptDirectory) -ChildPath "PhoenixMiner_5.4c_Windows")

Write-Host "Close Logfile" 
$LogFile | Disable-LogFile
