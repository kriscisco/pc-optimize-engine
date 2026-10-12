# Module 03: Silent Standby Memory Priming (RAM Prewarm)
# Caches top 10-15 applications into physical RAM Standby List without opening GUI windows.

param(
    [int]$TopAppsCount = 15,
    [switch]$RunNow
)

$ErrorActionPreference = "SilentlyContinue"

Write-Host "--> [RAM PREWARM] Menyiapkan Standby Memory Priming (Zero-Window Cache)..." -ForegroundColor Yellow

$os = Get-CimInstance Win32_OperatingSystem
$memGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
$budgetMB = [math]::Min([math]::Round($memGB * 1024 * 0.45), 8192)

Write-Host "    [INFO] Total RAM: $memGB GB | Kuota Maksimal Prewarm: $budgetMB MB" -ForegroundColor Cyan

# Blacklist aplikasi yang tidak boleh di-cache atau autostart
$Blacklist = @("RAINMETER", "PUBLISHER", "ONENOTE", "HWINFO", "HWINFO64", "NOTEPAD", "TASKMGR", "CMD", "POWERSHELL")

# Ambil aplikasi dari Prefetch Windows
$prefetchDir = "C:\Windows\Prefetch"
$topCandidates = @()

if (Test-Path $prefetchDir) {
    $pfFiles = Get-ChildItem -Path $prefetchDir -Filter "*.pf" | Sort-Object LastWriteTime -Descending
    foreach ($pf in $pfFiles) {
        $baseName = ($pf.BaseName -split "-")[0].ToUpper()
        if ($Blacklist -contains $baseName) { continue }
        if ($baseName -match "SETUP|INSTALL|UPDATE|UNINSTALL|SVCHOST|CONHOST|DLLHOST") { continue }
        
        # Cari lokasi executable
        $foundExe = $null
        $searchPaths = @(
            "C:\Program Files",
            "C:\Program Files (x86)",
            "$env:LOCALAPPDATA\Programs"
        )
        
        foreach ($sp in $searchPaths) {
            if (Test-Path $sp) {
                $check = Get-ChildItem -Path $sp -Filter "$baseName.exe" -Recurse -Depth 3 -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($check) { $foundExe = $check.FullName; break }
            }
        }
        
        if ($foundExe -and ($topCandidates | Where-Object { $_.Path -eq $foundExe }).Count -eq 0) {
            $fileSize = (Get-Item $foundExe).Length
            $topCandidates += [PSCustomObject]@{
                Name = $baseName
                Path = $foundExe
                SizeMB = [math]::Round($fileSize / 1MB, 2)
            }
        }
        if ($topCandidates.Count -ge $TopAppsCount) { break }
    }
}

Write-Host "    [LIST] Menemukan $($topCandidates.Count) aplikasi teratas untuk di-cache." -ForegroundColor Cyan

# Priming Cache murni dengan membaca byte ke memori (Tanpa Start-Process / 0 Jendela Terbuka!)
$cachedBytes = 0
$cachedCount = 0

foreach ($app in $topCandidates) {
    try {
        if (Test-Path $app.Path) {
            # Baca binary langsung ke memori (Windows otomatis menaruhnya di Standby Cache)
            $bytes = [System.IO.File]::ReadAllBytes($app.Path)
            $cachedBytes += $bytes.Length
            $cachedCount++
            $bytes = $null
        }
    } catch {}
}

$cachedTotalMB = [math]::Round($cachedBytes / 1MB, 2)
Write-Host "--> [RAM PREWARM] Selesai: $cachedCount aplikasi ($cachedTotalMB MB) ter-cache di RAM fisik (Layar Bersih 100%)." -ForegroundColor Green
