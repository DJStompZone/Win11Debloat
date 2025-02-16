function RegImport {
    param (
        $message,
        $path,
        $sysprep,
        $rootPath
    )
    Write-Output $message
    # Write-Debug "`$rootPath = $rootPath"
    # Write-Debug "`$path = $path"
    # Write-Debug "`$sysprep = $sysprep"
    # Write-Debug ""
    $PathActuallyExists = Test-Path "$rootPath\Regfiles\$path"
    if (-not $PathActuallyExists) {
        Write-Warning "Registry file $path does not exist!"
    }
    $RootPathActuallyExists = Test-Path $rootPath
    if (-not $RootPathActuallyExists) {
        Write-Warning "Root path $rootPath does not exist!"
    }
    if (-not $sysprep) {
        reg import "$rootPath\Regfiles\$path"  
    } else {
        $defaultUserPath = $env:USERPROFILE -Replace ('\\' + $env:USERNAME + '$'), '\Default\NTUSER.DAT'
        reg load "HKU\Default" $defaultUserPath | Out-Null
        reg import "$rootPath\Regfiles\Sysprep\$path"  
        reg unload "HKU\Default" | Out-Null
    }
    Write-Output ""
}

function RestartExplorer {
    param (
        $sysprep,
        $disableMouseAcceleration
    )
    if ($sysprep) {
        return
    }
    Write-Output "> Restarting Windows Explorer process to apply all changes... (This may cause some flickering)"
    if ($disableMouseAcceleration) {
        Write-Host "Warning: The Enhance Pointer Precision setting has been changed, this setting will only take effect after a reboot" -ForegroundColor Yellow
    }
    if ([Environment]::Is64BitProcess -eq [Environment]::Is64BitOperatingSystem) {
        Stop-Process -processName: Explorer -Force
    } else {
        Write-Warning "Unable to restart Windows Explorer process, please manually reboot your PC to apply all changes."
    }
}

function RegExport {
    param (
        $path,
        $outputFile
    )
    reg export $path $outputFile /y
}

function RegDelete {
    param (
        $path
    )
    reg delete $path /f
}
