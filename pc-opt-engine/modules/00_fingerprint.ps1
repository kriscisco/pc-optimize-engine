# Module 00: Hardware & Form-Factor Fingerprinting
# Detects PC architecture, battery configuration, RAM budget, and platform class.

function Get-PCHardwareFingerprint {
    $ErrorActionPreference = "SilentlyContinue"

    $cs   = Get-CimInstance Win32_ComputerSystem
    $os   = Get-CimInstance Win32_OperatingSystem
    $proc = Get-CimInstance Win32_Processor
    $gpus = Get-CimInstance Win32_VideoController
    $bats = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue

    $memGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
    # Safe Prewarm Budget: maximum 45% of physical RAM, capped at 8192 MB
    $budgetMB = [math]::Min([math]::Round($memGB * 1024 * 0.45), 8192)

    $isHandheld = ($cs.Model -match "ROG Ally|Legion Go|Claw|GPD|AOKZOE|AYANEO")
    $isThinkPad = ($cs.Model -match "ThinkPad")
    $isIntel    = ($proc.Manufacturer -match "Intel")
    $isAMD      = ($proc.Manufacturer -match "AMD")

    $formFactor = if ($isHandheld) {
        "Handheld_Gaming"
    } elseif ($bats.Count -ge 2) {
        "Laptop_DualBattery"
    } elseif ($bats.Count -eq 1) {
        "Laptop_SingleBattery"
    } else {
        "Desktop_AC"
    }

    $gpuNames = ($gpus | ForEach-Object { $_.Name }) -join ", "

    [PSCustomObject]@{
        Manufacturer   = $cs.Manufacturer
        Model          = $cs.Model
        FormFactor     = $formFactor
        CPU_Vendor     = if ($isIntel) { "Intel" } elseif ($isAMD) { "AMD" } else { "Generic" }
        CPU_Model      = $proc.Name.Trim()
        CoresThreads   = "$($proc.NumberOfCores)C / $($proc.NumberOfLogicalProcessors)T"
        RAM_Total_GB   = $memGB
        RAM_Budget_MB  = $budgetMB
        GPU_Model      = $gpuNames
        Is_ThinkPad    = $isThinkPad
        Is_Handheld    = $isHandheld
        BatteryCount   = if ($bats) { $bats.Count } else { 0 }
        OS_Version     = $os.Caption
        OS_Build       = $os.BuildNumber
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    Get-PCHardwareFingerprint
}
