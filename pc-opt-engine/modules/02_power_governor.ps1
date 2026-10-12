# Module 02: Hardware-Adaptive Battery & Power Governor
# Deploys 3-Tier Hardware P-State scaling (Intel Speed Shift EPP / AMD ACPI) with 90s Startup Turbo Window.

param(
    [switch]$InstallService,
    [switch]$RunOnce
)

$ErrorActionPreference = "SilentlyContinue"

Write-Host "--> [POWER GOVERNOR] Mengonfigurasi Dynamic Governor & Hardware P-States..." -ForegroundColor Yellow

# GUID Definitions
$GUID_TIER1_BOOST    = "10728b17-d7bd-4ca1-990c-b4f7c030f8cd" # Dynamic Boost Performance
$GUID_TIER2_BALANCED = "381b4222-f694-41f0-9685-ff5bb260df2e" # Balanced
$GUID_TIER3_SAVER    = "c8abfc09-e09e-496b-8db2-d4dee1997578" # Power Saver

$SUB_PROC   = "54533251-82be-4824-96c1-47b60b740d00"
$PERFEPP    = "36687f9e-e3a5-4dbf-b1dc-15eb381c6863"
$PROCMIN    = "893dee8e-2bef-41e0-89c6-b55d0929964c"
$PROCMAX    = "bc5038f7-23e0-4960-96da-33abaf5935ec"
$SUB_GFX    = "44f3beca-a7c0-460e-9df2-bb8b99e0cba6"
$GFX_PLAN   = "3619c3f2-afb2-4afc-b0e9-e7fef372de36"
$SUB_PCIE   = "501a4d13-42af-4429-9fd1-a8218c268e20"
$PCIE_ASPM  = "ee12f906-d277-404b-b6da-e5fa1a576df5"

# 1. Unhide PERFEPP (Energy Performance Preference) di Registry
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\$SUB_PROC\$PERFEPP" -Name "Attributes" -Value 2 -Force -ErrorAction SilentlyContinue

# 2. Pastikan Skema Power Saver Ada
$schemesText = (powercfg /l) -join "`n"
if ($schemesText -notmatch "$GUID_TIER3_SAVER" -and $schemesText -notmatch "Power saver") {
    Write-Host "    [SETUP] Menduplikasi skema Power Saver standar..." -ForegroundColor Cyan
    powercfg -duplicatescheme a1841308-3541-4fab-bc81-f71556f20b4a | Out-Null
}

# 3. Setup Nilai Parameter 3-Tier di Powercfg
# Tier 1: EPP=0, Min=5%, Max=100%, GPU=1 (Balanced), PCIe=1
powercfg /setacvalueindex $GUID_TIER1_BOOST $SUB_PROC $PERFEPP 0
powercfg /setdcvalueindex $GUID_TIER1_BOOST $SUB_PROC $PERFEPP 0
powercfg /setacvalueindex $GUID_TIER1_BOOST $SUB_PROC $PROCMIN 5
powercfg /setdcvalueindex $GUID_TIER1_BOOST $SUB_PROC $PROCMIN 5
powercfg /setacvalueindex $GUID_TIER1_BOOST $SUB_PROC $PROCMAX 100
powercfg /setdcvalueindex $GUID_TIER1_BOOST $SUB_PROC $PROCMAX 100
powercfg /setacvalueindex $GUID_TIER1_BOOST $SUB_GFX  $GFX_PLAN 1
powercfg /setdcvalueindex $GUID_TIER1_BOOST $SUB_GFX  $GFX_PLAN 1
powercfg /setacvalueindex $GUID_TIER1_BOOST $SUB_PCIE $PCIE_ASPM 1
powercfg /setdcvalueindex $GUID_TIER1_BOOST $SUB_PCIE $PCIE_ASPM 1

# Tier 2: EPP=50, Min=5%, Max=100%, GPU=1, PCIe=2
powercfg /setacvalueindex $GUID_TIER2_BALANCED $SUB_PROC $PERFEPP 50
powercfg /setdcvalueindex $GUID_TIER2_BALANCED $SUB_PROC $PERFEPP 50
powercfg /setacvalueindex $GUID_TIER2_BALANCED $SUB_PROC $PROCMIN 5
powercfg /setdcvalueindex $GUID_TIER2_BALANCED $SUB_PROC $PROCMIN 5
powercfg /setacvalueindex $GUID_TIER2_BALANCED $SUB_PROC $PROCMAX 100
powercfg /setdcvalueindex $GUID_TIER2_BALANCED $SUB_PROC $PROCMAX 100
powercfg /setacvalueindex $GUID_TIER2_BALANCED $SUB_GFX  $GFX_PLAN 1
powercfg /setdcvalueindex $GUID_TIER2_BALANCED $SUB_GFX  $GFX_PLAN 1
powercfg /setacvalueindex $GUID_TIER2_BALANCED $SUB_PCIE $PCIE_ASPM 2
powercfg /setdcvalueindex $GUID_TIER2_BALANCED $SUB_PCIE $PCIE_ASPM 2

# Tier 3: EPP=85, Min=5%, Max=85%, GPU=0, PCIe=2
powercfg /setdcvalueindex $GUID_TIER3_SAVER $SUB_PROC $PERFEPP 85
powercfg /setdcvalueindex $GUID_TIER3_SAVER $SUB_PROC $PROCMIN 5
powercfg /setdcvalueindex $GUID_TIER3_SAVER $SUB_PROC $PROCMAX 85
powercfg /setdcvalueindex $GUID_TIER3_SAVER $SUB_GFX  $GFX_PLAN 0
powercfg /setdcvalueindex $GUID_TIER3_SAVER $SUB_PCIE $PCIE_ASPM 2

# Refresh active plan
powercfg /setactive $GUID_TIER1_BOOST

# 4. Daftarkan Scheduled Task Governor di Windows
$TaskName = "AppPrewarm_Battery_Governor"
$TargetDir = "C:\ProgramData\AppPrewarm"
if (-not (Test-Path $TargetDir)) { New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null }

$DaemonScriptPath = Join-Path $TargetDir "battery_governor.ps1"
$SourceDaemon = Join-Path $PSScriptRoot "..\..\battery_governor.ps1"
if (-not (Test-Path $SourceDaemon)) {
    $SourceDaemon = "C:\ProgramData\AppPrewarm\battery_governor.ps1"
}
if ((Test-Path $SourceDaemon) -and ($SourceDaemon -ne $DaemonScriptPath)) {
    Copy-Item -Path $SourceDaemon -Destination $DaemonScriptPath -Force
}

Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -NoProfile -File `"$DaemonScriptPath`" -Loop -IntervalSeconds 30"
$TriggerBoot = New-ScheduledTaskTrigger -AtStartup
$TriggerLogon = New-ScheduledTaskTrigger -AtLogOn
$Principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Days 0)

Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger @($TriggerBoot, $TriggerLogon) -Principal $Principal -Settings $Settings -Force | Out-Null
Start-ScheduledTask -TaskName $TaskName

Write-Host "--> [POWER GOVERNOR] Berhasil dipasang & aktif (Status: Running under SYSTEM)." -ForegroundColor Green
