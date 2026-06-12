param(
    [string]$GodotExe = "C:\Users\Robbie Bedford\Downloads\Godot_v4.6.3-stable_win64.exe",
    [string]$Preset = "Android Debug",
    [string]$ApkPath = "export/dead-shift-debug.apk"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $GodotExe)) {
    throw "Godot executable not found: $GodotExe"
}

$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $ProjectRoot

function Invoke-GodotStep {
    param(
        [string]$Name,
        [string[]]$Arguments
    )

    Write-Host "==> $Name"
    & $GodotExe @Arguments
    $exitCode = if ($null -eq $LASTEXITCODE) { 0 } else { $LASTEXITCODE }
    if ($exitCode -ne 0) {
        throw "$Name failed with exit code $exitCode"
    }
}

Invoke-GodotStep "Load project" @("--headless", "--path", ".", "--quit")
Invoke-GodotStep "Run gameplay smoke test" @("--headless", "--path", ".", "-s", "tests\SmokeTest.gd")
Invoke-GodotStep "Run phone viewport UI test" @("--headless", "--path", ".", "-s", "tests\SceneUiTest.gd")
Invoke-GodotStep "Run Android config test" @("--headless", "--path", ".", "-s", "tests\ProjectConfigTest.gd")

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $ApkPath) | Out-Null
Invoke-GodotStep "Export Android debug APK" @("--headless", "--path", ".", "--export-debug", $Preset, $ApkPath)

if (-not (Test-Path -LiteralPath $ApkPath)) {
    throw "APK export completed but file was not found: $ApkPath"
}

$apk = Get-Item -LiteralPath $ApkPath
Write-Host ""
Write-Host "Dead Shift local verification passed."
Write-Host ("APK: {0}" -f $apk.FullName)
Write-Host ("Size: {0:N1} MB" -f ($apk.Length / 1MB))
