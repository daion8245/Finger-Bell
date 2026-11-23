[CmdletBinding()]
param(
    [string]$Device = '',
    [string]$Emulator = 'Medium_Phone_API_37.0',
    [ValidateRange(1024, 65535)]
    [int]$ApiPort = 8765,
    [switch]$BuildOnly,
    [switch]$NoResident
)

$ErrorActionPreference = 'Stop'
$appDirectory = Join-Path $PSScriptRoot 'packages\app'
$configPath = Join-Path $PSScriptRoot '.env.local.json'

$flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
$flutterExe = if ($flutterCommand) { $flutterCommand.Source } else { 'C:\flutter\bin\flutter.bat' }
if (-not (Test-Path -LiteralPath $flutterExe)) { throw 'Flutter SDK was not found. Add flutter\bin to PATH.' }
if (-not $BuildOnly) {
    $androidSdk = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
    $adbExe = Join-Path $androidSdk 'platform-tools\adb.exe'
    if (-not (Test-Path -LiteralPath $adbExe)) { throw 'Android SDK platform-tools were not found.' }

    if ([string]::IsNullOrWhiteSpace($Device)) {
        $adbLines = & $adbExe devices
        if ($LASTEXITCODE -ne 0) { throw 'adb devices failed.' }
        $readyDevices = @(
            $adbLines | ForEach-Object {
                if ($_ -match '^\s*(\S+)\s+device\s*$') { $Matches[1] }
            }
        )
        if ($readyDevices.Count -eq 1) {
            $Device = $readyDevices[0]
        } elseif ($readyDevices.Count -eq 0) {
            $Device = 'emulator-5554'
        } else {
            throw ("Multiple Android devices are connected: {0}. Specify -Device <id>." -f ($readyDevices -join ', '))
        }
    }
}

# Only Android is prepared by this launcher; desktop builds keep their own settings.
$previousWindowsFlag = $env:FLUTTER_WINDOWS
$previousLinuxFlag = $env:FLUTTER_LINUX
try {
    $env:FLUTTER_WINDOWS = 'false'
    $env:FLUTTER_LINUX = 'false'
    Push-Location $appDirectory
    try {
        & $flutterExe pub get
        if ($LASTEXITCODE -ne 0) { throw 'Flutter dependency setup failed.' }

        if (-not $BuildOnly) {
            $connectedDevices = & $adbExe devices
            if ($LASTEXITCODE -ne 0) { throw 'adb devices failed.' }
            $deviceState = $connectedDevices | Select-String ('^' + [regex]::Escape($Device) + '\s+(\S+)')
            if (-not $deviceState) {
                if (-not $Device.StartsWith('emulator-')) {
                    throw "Android device '$Device' is not connected."
                }
                & $flutterExe emulators --launch $Emulator
                if ($LASTEXITCODE -ne 0) { throw "Could not launch emulator '$Emulator'." }
            } elseif ($deviceState.Matches[0].Groups[1].Value -eq 'unauthorized') {
                throw "Android device '$Device' is unauthorized. Approve USB debugging on the device and retry."
            }

            $bootDeadline = [DateTime]::UtcNow.AddMinutes(3)
            do {
                try {
                    $bootState = & $adbExe -s $Device shell getprop sys.boot_completed 2>$null
                } catch {
                    $bootState = ''
                }
                if (($bootState -join '').Trim() -eq '1') { break }
                if ([DateTime]::UtcNow -ge $bootDeadline) { throw "Timed out waiting for '$Device' to boot." }
                Start-Sleep -Seconds 2
            } while ($true)

            # Forward the device's localhost API port to the backend on this PC.
            & $adbExe -s $Device reverse "tcp:$ApiPort" "tcp:$ApiPort"
            if ($LASTEXITCODE -ne 0) { throw 'adb reverse failed.' }
        }

        $defineArguments = @()
        # Use the local API URL when configured, or fall back to localhost.
        $useConfig = $false
        if (Test-Path -LiteralPath $configPath) {
            try {
                $useConfig = [bool](Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json).FINGERBELL_API_URL
            } catch {
                $useConfig = $false
            }
        }
        if ($useConfig) {
            $defineArguments += "--dart-define-from-file=$configPath"
        } else {
            $defineArguments += "--dart-define=FINGERBELL_API_URL=http://127.0.0.1:$ApiPort"
        }
        $total = [Diagnostics.Stopwatch]::StartNew()
        foreach ($app in @(
            @{ Flavor = 'fingerbell'; Target = 'lib/main.dart'; Package = 'kr.fingersnap.fingerbell' },
            @{ Flavor = 'sms'; Target = 'lib/main_sms.dart'; Package = 'kr.fingersnap.fingerbell.sms' },
            @{ Flavor = 'call'; Target = 'lib/main_call.dart'; Package = 'kr.fingersnap.fingerbell.call' }
        )) {
            $build = [Diagnostics.Stopwatch]::StartNew()
            & $flutterExe build apk --debug --no-pub --flavor $app.Flavor -t $app.Target @defineArguments
            if ($LASTEXITCODE -ne 0) { throw "Build failed: $($app.Flavor)" }
            Write-Host ('BUILD {0}: {1:N2}s' -f $app.Flavor, $build.Elapsed.TotalSeconds)
            if ($BuildOnly) { continue }

            $apk = Join-Path $appDirectory "build\app\outputs\flutter-apk\app-$($app.Flavor)-debug.apk"
            & $adbExe -s $Device install -r $apk
            if ($LASTEXITCODE -ne 0) { throw "Install failed: $($app.Package)" }
        }
        if ($BuildOnly) {
            Write-Host ('BUILD total: {0:N2}s' -f $total.Elapsed.TotalSeconds)
            return
        }
        Write-Host ('BUILD+INSTALL total: {0:N2}s' -f $total.Elapsed.TotalSeconds)
        & $adbExe -s $Device shell am start -n 'kr.fingersnap.fingerbell/kr.fingersnap.fingerbell.MainActivity'
        if ($LASTEXITCODE -ne 0) { throw 'FingerBell launch failed.' }
        if (-not $NoResident) {
            & $flutterExe attach -d $Device --app-id kr.fingersnap.fingerbell
            if ($LASTEXITCODE -ne 0) { throw 'Flutter attach failed.' }
        }
    } finally {
        Pop-Location
    }
} finally {
    $env:FLUTTER_WINDOWS = $previousWindowsFlag
    $env:FLUTTER_LINUX = $previousLinuxFlag
}
