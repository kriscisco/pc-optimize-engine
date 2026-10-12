<#
.SYNOPSIS
    Universal Adaptive PC Optimization Engine (Master Runner)
.DESCRIPTION
    Runs deterministic hardware-adaptive optimization across Windows PCs:
    - Intel Speed Shift EPP / AMD ACPI dynamic battery governor
    - Standby Memory Priming (Zero GUI windows)
    - Conflict elimination (removes duplicate autorun popups)
    - Package TDP headroom balancing (iGPU Balanced)
    - Automated ECC-style verification
.PARAMETER Detect
    Only performs hardware detection and outputs the planned recipe (Read-Only).
.PARAMETER Auto
    Automatically applies all optimization modules and runs verification.
.PARAMETER Verify
    Runs the automated health check and verification suite only.
#>

param(
    [switch]$Detect,
    [switch]$Auto,
    [switch]$Verify
)

$ErrorActionPreference = "SilentlyContinue"
$ScriptDir = $PSScriptRoot
$ModulesDir = Join-Path $ScriptDir "modules"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   UNIVERSAL ADAPTIVE PC OPTIMIZATION ENGINE (v2.0)       " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Panggil Modul 00: Fingerprinting
$fingerprintScript = Join-Path $ModulesDir "00_fingerprint.ps1"
if (-not (Test-Path $fingerprintScript)) {
    Write-Host "[ERROR] Modul fingerprinting tidak ditemukan di $fingerprintScript" -ForegroundColor Red
    exit 1
}

. $fingerprintScript
$hw = Get-PCHardwareFingerprint

Write-Host "Profil Hardware Terdeteksi:" -ForegroundColor Yellow
Write-Host "  Model PC       : $($hw.Manufacturer) $($hw.Model)"
Write-Host "  Form Factor    : $($hw.FormFactor) ($($hw.BatteryCount) Baterai Terdeteksi)"
Write-Host "  Prosesor (CPU) : $($hw.CPU_Vendor) - $($hw.CPU_Model)"
Write-Host "  Konfigurasi    : $($hw.CoresThreads)"
Write-Host "  Memori (RAM)   : $($hw.RAM_Total_GB) GB (Batas Aman Prewarm: $($hw.RAM_Budget_MB) MB)"
Write-Host "  Kartu Grafis   : $($hw.GPU_Model)"
Write-Host "  Sistem Operasi : $($hw.OS_Version) (Build $($hw.OS_Build))"

if ($Detect) {
    Write-Host "`n[MODE DETEKSI]: Hardware berhasil diidentifikasi. Tidak ada perubahan yang diterapkan." -ForegroundColor Green
    Write-Host "Untuk menerapkan optimasi penuh secara otomatis, jalankan:" -ForegroundColor Cyan
    Write-Host "  powershell -ExecutionPolicy Bypass -File .\optimize.ps1 -Auto`n" -ForegroundColor White
    exit 0
}

if ($Verify) {
    $verifyScript = Join-Path $ModulesDir "05_verify_suite.ps1"
    if (Test-Path $verifyScript) { & $verifyScript }
    exit 0
}

# 2. Mode Auto: Eksekusi Seluruh Modul Berurutan
Write-Host "`n[MODE AUTO]: Memulai Eksekusi Adaptif..." -ForegroundColor Green

# Step 1: Clean Slate
$cleanScript = Join-Path $ModulesDir "01_clean_slate.ps1"
if (Test-Path $cleanScript) { & $cleanScript }

# Step 2: Power Governor
$govScript = Join-Path $ModulesDir "02_power_governor.ps1"
if (Test-Path $govScript) { & $govScript }

# Step 3: GPU Balance
$gpuScript = Join-Path $ModulesDir "04_gpu_balance.ps1"
if (Test-Path $gpuScript) { & $gpuScript }

# Step 4: RAM Standby Priming
$ramScript = Join-Path $ModulesDir "03_ram_prewarm.ps1"
if (Test-Path $ramScript) { & $ramScript -TopAppsCount 15 }

# Step 5: Verification Suite
Write-Host "`nMenjalankan Pengujian Verifikasi Akhir..." -ForegroundColor Cyan
$verifyScript = Join-Path $ModulesDir "05_verify_suite.ps1"
if (Test-Path $verifyScript) { . $verifyScript }

Write-Host "==========================================================" -ForegroundColor Green
Write-Host "   OPTIMISASI SELESAI & SISTEM SIAP DIGUNAKAN!            " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
