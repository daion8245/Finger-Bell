$apiPort = 8765
$androidSdk = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
$adbExe = Join-Path $androidSdk 'platform-tools\adb.exe'
if (-not (Test-Path -LiteralPath $adbExe)) {
    Write-Warning 'Android SDK platform-tools were not found. Set ANDROID_HOME to your Android SDK.'
    return
}

$deviceLines = & $adbExe devices
if ($LASTEXITCODE -ne 0) {
    Write-Warning 'adb devices failed. Check the Android device connection.'
    return
}

# The Flutter plugin does not pass its selected device to before-launch tasks.
foreach ($line in $deviceLines) {
    if ($line -match '^\s*(\S+)\s+device\s*$') {
        $device = $Matches[1]
        & $adbExe -s $device reverse "tcp:$apiPort" "tcp:$apiPort"
        if ($LASTEXITCODE -ne 0) { Write-Warning "Failed to forward port $apiPort on '$device'." }
    }
}
