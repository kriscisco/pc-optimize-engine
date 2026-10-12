# Module 04: GPU & Package TDP Headroom Balancer
# Sets integrated GPU to Balanced (Index 1) so 100% of Package TDP is available for CPU cores during boot/apps.

param()

$ErrorActionPreference = "SilentlyContinue"

Write-Host "--> [GPU BALANCE] Menyetel Intel/AMD GPU Power Plan ke Balanced..." -ForegroundColor Yellow

$SUB_GFX  = "44f3beca-a7c0-460e-9df2-bb8b99e0cba6"
$GFX_PLAN = "3619c3f2-afb2-4afc-b0e9-e7fef372de36"

# Skema yang perlu diatur
$schemes = @(
    "10728b17-d7bd-4ca1-990c-b4f7c030f8cd", # Tier 1 (Boost)
    "381b4222-f694-41f0-9685-ff5bb260df2e"  # Tier 2 (Balanced)
)

foreach ($sc in $schemes) {
    powercfg /setacvalueindex $sc $SUB_GFX $GFX_PLAN 1
    powercfg /setdcvalueindex $sc $SUB_GFX $GFX_PLAN 1
}

# Tier 3 (Power Saver) disetel ke Maximum Battery Life (0)
powercfg /setdcvalueindex "c8abfc09-e09e-496b-8db2-d4dee1997578" $SUB_GFX $GFX_PLAN 0

# Terapkan pada skema aktif saat ini
powercfg /setactive SCHEME_CURRENT

Write-Host "--> [GPU BALANCE] GPU dikonfigurasi ke Balanced (300 MHz saat idle, 1050 MHz saat game/editing)." -ForegroundColor Green
