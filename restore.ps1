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
Remove-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender' 'DisableAntiSpyware'
Remove-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection' 'DisableRealtimeMonitoring'
Set-ItemProperty 'HKCU:\Control Panel\Mouse' 'SwapMouseButtons' 0
Set-ItemProperty 'HKCU:\Control Panel\Mouse' 'MouseSensitivity' '10'
Set-ItemProperty 'HKCU:\Control Panel\Keyboard' 'KeyboardDelay' '1'
Set-ItemProperty 'HKCU:\Control Panel\Keyboard' 'KeyboardSpeed' '31'
Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'HideIcons' 0
Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'HideFileExt' 0
Set-ItemProperty 'HKCU:\Control Panel\Desktop' 'ScreenSaveTimeOut' 600
Set-ItemProperty 'HKCU:\Control Panel\Desktop' 'Wallpaper' ''
Set-ItemProperty 'HKCU:\Control Panel\International' 'sTimeFormat' 'HH:mm:ss'
Set-ItemProperty 'HKCU:\Control Panel\International' 'sShortTime' 'HH:mm'
rundll32.exe user32.dll,UpdatePerUserSystemParameters
Remove-Item "$env:USERPROFILE\Desktop\*.txt" -Force
Stop-Process -Name explorer -Force
Get-Process powershell | Stop-Process
