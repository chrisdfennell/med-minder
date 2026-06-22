param(
    [string]$Device = "fenix7",
    [switch]$Run,
    [switch]$Export
)

# App identity (keep in sync with manifest.xml)
$AppName = "MedMinder"
$AppId = "b2c9a1e4-5d3f-4a76-9c1b-0e8f7a6d2c54"

# Load local build configuration or create default if missing
$configFile = Join-Path $PSScriptRoot "build_config.json"
if (Test-Path $configFile) {
    $config = Get-Content $configFile | ConvertFrom-Json
    $JavaHome = $config.JavaHome
    $SdkDir = $config.SdkDir
} else {
    $JavaHome = "C:\Program Files\Android\openjdk\jdk-21.0.8"
    $SdkDir = "C:\Users\christopher.fennell\AppData\Roaming\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-9.2.0-2026-06-09-92a1605b2"
    $configObj = [ordered]@{
        JavaHome = $JavaHome
        SdkDir = $SdkDir
    }
    $configObj | ConvertTo-Json | Out-File -Encoding utf8 $configFile
}

# 1. Setup Java Environment
$env:JAVA_HOME = $JavaHome
$env:PATH = (Join-Path $JavaHome "bin") + ";" + $env:PATH

# 2. Define Garmin SDK Paths
$sdkBin = Join-Path $SdkDir "bin"

# 3. Create output directory if it doesn't exist
if (!(Test-Path -Path "bin")) {
    New-Item -ItemType Directory -Path "bin" | Out-Null
}

# 4. Build the project
$monkeyc = Join-Path $sdkBin "monkeyc.bat"
$junglePath = Join-Path $PSScriptRoot "monkey.jungle"
$keyPath = Join-Path $PSScriptRoot "developer_key.der"

if ($Export) {
    Write-Host "Packaging application for Connect IQ Store (.iq)..." -ForegroundColor Cyan
    $outputPath = Join-Path $PSScriptRoot "bin\$AppName.iq"
    & $monkeyc -e -f $junglePath -o $outputPath -y $keyPath
} else {
    Write-Host "Building for device: $Device..." -ForegroundColor Cyan
    $outputPath = Join-Path $PSScriptRoot "bin\$AppName.prg"
    & $monkeyc -f $junglePath -o $outputPath -y $keyPath -d $Device
}

if ($LASTEXITCODE -ne 0) {
    Write-Error "Compilation failed with exit code $LASTEXITCODE."
    exit $LASTEXITCODE
}

if ($Export) {
    Write-Host "Package Succeeded! Output: bin\$AppName.iq" -ForegroundColor Green
} else {
    Write-Host "Build Succeeded! Output: bin\$AppName.prg" -ForegroundColor Green
}

# 5. Launch in Simulator if requested
if ($Run) {
    Write-Host "Checking if Simulator is running..." -ForegroundColor Cyan
    $simProcess = Get-Process -Name "simulator" -ErrorAction SilentlyContinue
    if (!$simProcess) {
        Write-Host "Starting Connect IQ Simulator..." -ForegroundColor Cyan
        $simulator = Join-Path $sdkBin "simulator.exe"
        Start-Process -FilePath $simulator
        Start-Sleep -Seconds 4 # Give it a moment to boot
    } else {
        Write-Host "Simulator is already running." -ForegroundColor Cyan
    }

    Write-Host "Deploying to $Device in simulator (copying to space-free path to support settings)..." -ForegroundColor Cyan
    $tempDir = "C:\Garmin_Temp"
    if (!(Test-Path -Path $tempDir)) {
        New-Item -ItemType Directory -Path $tempDir | Out-Null
    }
    $tempPrg = Join-Path $tempDir "$AppName.prg"
    Copy-Item $outputPath $tempPrg -Force

    # If app settings have been exported, stage the JSON under every name the
    # simulator's App Settings Editor might look for.
    $settingsSrc = Join-Path $PSScriptRoot "bin\$AppName-settings.json"
    $settingsNames = @(
        "$AppName-settings.json",
        "$AppName.json",
        "$AppId.json",
        "$AppId-settings.json"
    )
    foreach ($name in $settingsNames) {
        if (Test-Path $settingsSrc) {
            Copy-Item $settingsSrc (Join-Path $tempDir $name) -Force
        }
    }

    $monkeydo = Join-Path $sdkBin "monkeydo.bat"
    & $monkeydo $tempPrg $Device

    # Copy settings JSON files directly to the simulator's settings directories
    # to ensure the App Settings Editor can locate the schema.
    $simTempDir = Join-Path $env:TEMP "com.garmin.connectiq\GARMIN"
    if (Test-Path -Path $simTempDir) {
        $simSettingsDirs = @(
            (Join-Path $simTempDir "Settings"),
            (Join-Path $simTempDir "APPS\SETTINGS")
        )
        foreach ($dir in $simSettingsDirs) {
            if (!(Test-Path -Path $dir)) {
                New-Item -ItemType Directory -Path $dir | Out-Null
            }
            foreach ($name in $settingsNames) {
                if (Test-Path $settingsSrc) {
                    Copy-Item $settingsSrc (Join-Path $dir $name) -Force
                }
            }
        }
    }
}
