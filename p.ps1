$ErrorActionPreference = 'SilentlyContinue'
$Root = "$env:APPDATA\Microsoft\Windows\SysCache"
$Orig = "$Root\orig.dat"
$k1 = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System'
$k2 = 'HKCU:\Software\Policies\Microsoft\Windows\System'

$o = $null
if (Test-Path $Orig) { try { $o = Get-Content $Orig -Raw | ConvertFrom-Json } catch {} }

Remove-Item ([Environment]::GetFolderPath('Startup') + '\WindowsSecurityHealth.vbs') -Force
Remove-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' 'SecurityHealthSystray'
schtasks /delete /tn "SysCacheUpdate" /f
Remove-ItemProperty $k1 'DisableTaskMgr'; Remove-ItemProperty $k1 'DisableRegistryTools'
Remove-ItemProperty $k2 'DisableCMD'
Remove-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender' 'DisableAntiSpyware'
Remove-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection' 'DisableRealtimeMonitoring'

Set-ItemProperty 'HKCU:\Control Panel\Mouse' 'SwapMouseButtons' 0
Set-ItemProperty 'HKCU:\Control Panel\Mouse' 'MouseSensitivity' "$($o.MouseSens ?? '10')"
Set-ItemProperty 'HKCU:\Control Panel\Keyboard' 'KeyboardDelay' "$($o.KeyDelay ?? '1')"
Set-ItemProperty 'HKCU:\Control Panel\Keyboard' 'KeyboardSpeed' "$($o.KeySpeed ?? '31')"
Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'HideIcons' 0
Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'HideFileExt' 0
Set-ItemProperty 'HKCU:\Control Panel\Desktop' 'ScreenSaveTimeOut' "$($o.ScrnTime ?? '600')"
Set-ItemProperty 'HKCU:\Control Panel\Desktop' 'ScreenSaveActive' '1'
Set-ItemProperty 'HKCU:\Control Panel\Desktop' 'Wallpaper' "$($o.Wallpaper ?? '')"
Set-ItemProperty 'HKCU:\Control Panel\International' 'sTimeFormat' "$($o.TimeFmt ?? 'HH:mm:ss')"
Set-ItemProperty 'HKCU:\Control Panel\International' 'sShortTime' "$($o.ShortTime ?? 'HH:mm')"
if ($o.TZ) { tzutil /s $o.TZ }
rundll32.exe user32.dll,UpdatePerUserSystemParameters

Remove-Item "$env:USERPROFILE\Desktop\*.txt" -Force
Stop-Process -Name explorer -Force
Start-Sleep -Milliseconds 800
Remove-Item "$Root" -Recurse -Force
Remove-Item "$env:APPDATA\svc.ps1" -Force
Get-Process powershell | Stop-Process
