function RegImport {
    param (
        $message,
        $path
    )
    Write-Output $message
    if (!$global:Params.ContainsKey("Sysprep")) {
        reg import "$PSScriptRoot\Regfiles\$path"  
    } else {
        $defaultUserPath = $env:USERPROFILE -Replace ('\\' + $env:USERNAME + '$'), '\Default\NTUSER.DAT'
        reg load "HKU\Default" $defaultUserPath | Out-Null
        reg import "$PSScriptRoot\Regfiles\Sysprep\$path"  
        reg unload "HKU\Default" | Out-Null
    }
    Write-Output ""
}

function RestartExplorer {
    if ($global:Params.ContainsKey("Sysprep")) {
        return
    }
    Write-Output "> Restarting Windows Explorer process to apply all changes... (This may cause some flickering)"
    if ($global:Params.ContainsKey("DisableMouseAcceleration")) {
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
