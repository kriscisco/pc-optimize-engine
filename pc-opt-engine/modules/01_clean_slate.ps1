# Module 01: Clean Slate & Conflict Elimination
# Removes duplicate startup entries, eliminates error popups, and disables background hogs.

param(
    [switch]$Verbose
)

$ErrorActionPreference = "SilentlyContinue"

Write-Host "--> [CLEAN SLATE] Memeriksa dan membersihkan konflik startup & background..." -ForegroundColor Yellow

# 1. Hilangkan Duplikasi Autorun Registry vs Task Scheduler (mencegah Error 183 TPFanControl dsb)
$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
)

$schedTasks = (Get-ScheduledTask -ErrorAction SilentlyContinue).TaskName

foreach ($rp in $regPaths) {
    if (Test-Path $rp) {
        $props = Get-ItemProperty -Path $rp
        foreach ($propName in $props.PSObject.Properties.Name) {
            if ($propName -match "^(PS|_)") { continue }
            
            # Jika aplikasi sudah terdaftar di Task Scheduler dengan hak akses lebih tinggi, bersihkan dari Run key
            if ($schedTasks -contains $propName -or $schedTasks -contains "${propName}_Tray" -or $propName -eq "TPFanControl") {
                Write-Host "    [FIX] Menghapus duplicate autorun di $rp : $propName" -ForegroundColor Cyan
                Remove-ItemProperty -Path $rp -Name $propName -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

# 2. Bersihkan Startup Folder dari junk link (Send to OneNote, dll)
$startupFolders = @(
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
    "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
)

$blacklistLinks = @("Send to OneNote.lnk", "OneNote.lnk", "Rainmeter.lnk", "HWiNFO.lnk", "HWiNFO64.lnk")
foreach ($sf in $startupFolders) {
    if (Test-Path $sf) {
        foreach ($bl in $blacklistLinks) {
            $targetPath = Join-Path $sf $bl
            if (Test-Path $targetPath) {
                Write-Host "    [CLEAN] Menghapus startup shortcut: $targetPath" -ForegroundColor Cyan
                Remove-Item -Path $targetPath -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

# 3. Kunci dan Matikan Background Service Penguras Disk/Bandwidth (DoSvc - Delivery Optimization)
$doSvc = Get-Service -Name "DoSvc" -ErrorAction SilentlyContinue
if ($doSvc -and $doSvc.StartType -ne "Disabled") {
    Write-Host "    [OPT] Mengunci Delivery Optimization (DoSvc) ke Disabled..." -ForegroundColor Cyan
    Stop-Service -Name "DoSvc" -Force -ErrorAction SilentlyContinue
    Set-Service -Name "DoSvc" -StartupType Disabled -ErrorAction SilentlyContinue
}

Write-Host "--> [CLEAN SLATE] Selesai dengan aman (Zero Error Popups)." -ForegroundColor Green
