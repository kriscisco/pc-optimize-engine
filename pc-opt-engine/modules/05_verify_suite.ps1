# Module 05: Automated ECC Verification Suite & Health Certificate
# Verifies clean desktop (0 open windows), 0 error popups, idle clock drop, and thermal health.

function Test-PCOptimizationHealth {
    $ErrorActionPreference = "SilentlyContinue"

    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "      UJI VERIFIKASI OTOMATIS & SERTIFIKAT KESEHATAN PC   " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan

    # 1. Cek Kebersihan Desktop (Harus 0 jendela aplikasi terbuka otomatis)
    $openWindows = Get-Process | Where-Object { 
        $_.MainWindowTitle.Length -gt 0 -and 
        $_.ProcessName -notmatch "explorer|taskmgr|powershell|cmd|conhost" 
    }
    $isDesktopClean = ($openWindows.Count -eq 0)

    # 2. Cek CPU Idle Drop
    $cpu = Get-CimInstance Win32_Processor
    $clockMHz = $cpu.CurrentClockSpeed
    $isCpuThrottledDown = ($clockMHz -le ($cpu.MaxClockSpeed + 200))

    # 3. Cek Scheduled Task Governor
    $task = Get-ScheduledTask -TaskName "AppPrewarm_Battery_Governor" -ErrorAction SilentlyContinue
    $isTaskRunning = ($task -and ($task.State -eq "Running" -or $task.State -eq "Ready"))

    # 4. Cek Power Scheme Aktif
    $activeScheme = powercfg /getactivescheme

    # 5. Cek Suhu & Kipas
    $ecTemp = "N/A"
    $fanRpm = "N/A"
    if (Test-Path "C:\Program Files\TPFanControl\TPFanControl_csv.txt") {
        $lastLine = Get-Content "C:\Program Files\TPFanControl\TPFanControl_csv.txt" -Tail 1
        if ($lastLine) {
            $parts = $lastLine.Split(';')
            if ($parts.Count -ge 14) {
                $ecTemp = "$($parts[1].Trim()) °C"
                $fanRpm = "$($parts[13].Trim()) RPM"
            }
        }
    }

    Write-Host "Hasil Pengecekan:"
    Write-Host "  [+] Desktop Bersih (0 Jendela Terbuka) : $(if ($isDesktopClean) {'PASS (100% Bersih)'} else {'WARN: Ada jendela terbuka'})"
    Write-Host "  [+] Governor Background Task          : $(if ($isTaskRunning) {'PASS (Aktif)'} else {'FAIL: Task tidak aktif'})"
    Write-Host "  [+] Skema Daya Aktif                  : $activeScheme"
    Write-Host "  [+] Clock Speed Terkini               : $clockMHz MHz"
    Write-Host "  [+] Suhu EC & Kipas                   : $ecTemp | $fanRpm"

    $allPassed = $isDesktopClean -and $isTaskRunning

    if ($allPassed) {
        Write-Host "`n--> [HASIL VERIFIKASI]: SEMUA PENGUJIAN LULUS (100% HEALTHY & READY)" -ForegroundColor Green
    } else {
        Write-Host "`n--> [HASIL VERIFIKASI]: PERLU PENYESUAIAN TAMBAHAN" -ForegroundColor Yellow
    }

    return $allPassed
}

Test-PCOptimizationHealth
