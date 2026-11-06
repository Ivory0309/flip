$ErrorActionPreference = 'SilentlyContinue'
$Root = "$env:APPDATA\Microsoft\Windows\SysCache"
$k1 = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System'
$k2 = 'HKCU:\Software\Policies\Microsoft\Windows\System'

Remove-Item "$Root\*" -Recurse -Force
Remove-Item ([Environment]::GetFolderPath('Startup') + '\WindowsSecurityHealth.vbs') -Force
Remove-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' 'SecurityHealthSystray'
schtasks /delete /tn "SysCacheUpdate" /f
Remove-ItemProperty $k1 'DisableTaskMgr'; Remove-ItemProperty $k1 'DisableRegistryTools'
Remove-ItemProperty $k2 'DisableCMD'
Set-ItemProperty 'HKCU:\Control Panel\Mouse' 'SwapMouseButtons' 0
Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'HideIcons' 0
Set-ItemProperty 'HKCU:\Control Panel\Desktop' 'ScreenSaveTimeOut' 600
Remove-Item "$env:USERPROFILE\Desktop\*.txt" -Force
Stop-Process -Name explorer -Force
Get-Process powershell | Stop-Process
