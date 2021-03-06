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

Start-Process -FilePath "forePatchGuest.exe" -WorkingDirectory "C:\forePatchGuest" -ArgumentList "restore" -Wait -ErrorAction SilentlyContinue
Start-Process -FilePath "forePatchGuest.exe" -WorkingDirectory "C:\forePatchGuest" -ErrorAction SilentlyContinue

# Close Geto
Disable-ScheduledTask -TaskName WMCLTS -ErrorAction SilentlyContinue
Stop-Service -Name WMCLTSVC -Force -ErrorAction SilentlyContinue
Stop-Process -Name WmClt* -Force -ErrorAction SilentlyContinue

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
Set-Content -Path "C:\Windows\System32\drivers\etc\hosts" -Value "" -Force

#Set-Content -Path "C:\Mining\PhoenixMiner_5.4c_Windows\reboot.bat" -Value "shutdown -s -t 1" -Force

Stop-Process -Name iexplore -Force -ErrorAction SilentlyContinue
Stop-Process -Name chrome -Force -ErrorAction SilentlyContinue
Stop-Process -Name MicrosoftEdge -Force -ErrorAction SilentlyContinue

# forePatchGuest
if($null -ne (Get-Process -Name forePatchGuest -ErrorAction SilentlyContinue))
{
  $TimerForePatch = New-Object -TypeName Timers.Timer
  $TimerForePatch.Interval = 60 * 60000
  Register-ObjectEvent -InputObject $TimerForePatch -EventName Elapsed `
    –SourceIdentifier TimerForePatch -Action { 
      $forePatchGuest = Get-Process -Name forePatchGuest -ErrorAction SilentlyContinue
      if($null -ne $forePatchGuest)
      {
        $forePath = $forePatchGuest.Path
        Start-Process -FilePath $forePath -ArgumentList "restore" -Wait -ErrorAction SilentlyContinue
        Start-Process -FilePath $forePath -ErrorAction SilentlyContinue
      }
    }
  $TimerForePatch.Start()
}

# remove Keyboard
$DevconPath = Join-Path -Path (Get-ScriptDirectory) -ChildPath "devcon.exe"
if(-not (Test-Path $DevconPath))
{
  Invoke-WebRequest "http://mining.pclucas.com/util/devcon.exe" -OutFile $DevconPath
}
Start-Process -FilePath $DevconPath -ArgumentList "remove =keyboard"

# timer RestartLowSpeed
$TimerRestartLowSpeed = New-Object -TypeName Timers.Timer
$TimerRestartLowSpeed.Interval = 3 * 60000
Register-ObjectEvent -InputObject $TimerRestartLowSpeed -EventName Elapsed `
  –SourceIdentifier TimerRestartLowSpeed -Action { 
    $Response = "127.0.0.1:3333" | Connect-TcpHost | Put-TcpHost -query '{"id":0,"jsonrpc":"2.0","method":"miner_getstat1"}' | Read-TcpHost | Disconnect-TcpHost
    $Query = ConvertFrom-Json $Response.Query.Data[1]
    $RunningTime = [int]$Query.result[1]
    $MiningSpeed = [int]$Query.result[3]
    Write-Host "마이닝실행시간(분): $RunningTime, 마이닝속도: $MiningSpeed, 마이닝ID: $($Users[$CurrentIndex % $Users.Count].ID)"
    if(($RunningTime -gt 1) -and ($MiningSpeed -le 1000))
    {
        $workingDir = Join-Path -Path (Get-ScriptDirectory) -ChildPath "PhoenixMiner_5.4c_Windows"
        Write-Host "재실행: $workingDir\start.bat"
        Start-Process -FilePath "start.bat" -WorkingDirectory $workingDir
    }
  }
$TimerRestartLowSpeed.Start()

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
set name=%COMPUTERNAME%
PhoenixMiner.exe -pool asia.ethash-hub.miningpoolhub.com:20535 -wal $miningId.%name% -pass x -proto 1 -cdm 1
"@
$phoenixStartPath = Join-Path -Path $(Get-ScriptDirectory) -ChildPath "PhoenixMiner_5.4c_Windows\start.bat"
Write-Host "PhoenixMiner Path: $phoenixStartPath" 
Set-Content -Path $phoenixStartPath -Value $contetnPhoenix -Force -Encoding Ascii
Write-Host "Start PhoenixMiner" 
Start-Process -FilePath "start.bat" -WorkingDirectory $(Join-Path -Path $(Get-ScriptDirectory) -ChildPath "PhoenixMiner_5.4c_Windows")

Write-Host "Close Logfile" 
$LogFile | Disable-LogFile
