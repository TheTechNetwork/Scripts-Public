# deploy-pac.ps1
# Installer script for PAC deployment on AVD multi-session hosts

$PacUrl = "https://example.com/path/to/pac/us-egress.pac"
$CorpDir = "C:\ProgramData\CorpProxy"
$UserScript = Join-Path $CorpDir "Set-PAC-HKCU.ps1"
$RunName = "ApplyPAC_HKCU"

New-Item -Path $CorpDir -ItemType Directory -Force | Out-Null

$script = @'
param([string]$PacUrl)
$hkcu = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
New-Item -Path $hkcu -Force | Out-Null
New-ItemProperty -Path $hkcu -Name AutoConfigURL -Value $PacUrl -PropertyType String -Force | Out-Null
New-ItemProperty -Path $hkcu -Name ProxyEnable -Value 0 -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path $hkcu -Name AutoDetect -Value 0 -PropertyType DWord -Force | Out-Null
Remove-ItemProperty -Path $hkcu -Name ProxyServer -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $hkcu -Name ProxyOverride -ErrorAction SilentlyContinue
$src = @"
using System;
using System.Runtime.InteropServices;
public class Bcast {
  [DllImport("user32.dll", SetLastError=true, CharSet=CharSet.Auto)]
  public static extern IntPtr SendMessageTimeout(IntPtr hWnd, int Msg, IntPtr wParam, string lParam,
      int fuFlags, int uTimeout, out IntPtr lpdwResult);
}
"@
Add-Type $src
[void][Bcast]::SendMessageTimeout([IntPtr]0xffff, 0x1A, [IntPtr]0,
  "Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings", 0, 3000, [ref]([IntPtr]::Zero))
'@

$script | Out-File -FilePath $UserScript -Encoding UTF8 -Force

$runKey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
$cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$UserScript`" -PacUrl `"$PacUrl`""
New-ItemProperty -Path $runKey -Name $RunName -Value $cmd -PropertyType String -Force | Out-Null

Write-Host "PAC installer deployed. Reboot required unless run during automated build."
