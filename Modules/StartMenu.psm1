function ReplaceStartMenuForAllUsers {
    param (
        $startMenuTemplate = "$global:rootPath/Start/start2.bin"
    )
    Write-Output "> Removing all pinned apps from the start menu for all users..."
    if (-not (Test-Path $startMenuTemplate)) {
        Write-Host "Error: Unable to clear start menu, start2.bin file missing from script folder" -ForegroundColor Red
        Write-Output ""
        return
    }
    $userPathString = $env:USERPROFILE -Replace ('\\' + $env:USERNAME + '$'), "\*\AppData\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState"
    $usersStartMenuPaths = get-childitem -path $userPathString
    ForEach ($startMenuPath in $usersStartMenuPaths) {
        ReplaceStartMenu "$($startMenuPath.Fullname)\start2.bin" $startMenuTemplate
    }
    $defaultStartMenuPath = $env:USERPROFILE -Replace ('\\' + $env:USERNAME + '$'), '\Default\AppData\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState'
    if (-not(Test-Path $defaultStartMenuPath)) {
        new-item $defaultStartMenuPath -ItemType Directory -Force | Out-Null
        Write-Output "Created LocalState folder for default user profile"
    }
    Copy-Item -Path $startMenuTemplate -Destination $defaultStartMenuPath -Force
    Write-Output "Replaced start menu for the default user profile"
    Write-Output ""
}

function ReplaceStartMenu {
    param (
        $startMenuBinFile = "$env:LOCALAPPDATA\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState\start2.bin",
        $startMenuTemplate = "$global:rootPath/Start/start2.bin"
    )
    $userName = $env:USERNAME
    if (-not (Test-Path $startMenuTemplate)) {
        Write-Host "Error: Unable to clear start menu, start2.bin file missing from script folder" -ForegroundColor Red
        return
    }
    if (-not (Test-Path $startMenuBinFile)) {
        Write-Host "Error: Unable to clear start menu for user $userName, start2.bin file could not found" -ForegroundColor Red
        return
    }
    $backupBinFile = $startMenuBinFile + ".bak"
    Move-Item -Path $startMenuBinFile -Destination $backupBinFile -Force
    Copy-Item -Path $startMenuTemplate -Destination $startMenuBinFile -Force
    Write-Output "Replaced start menu for user $userName"
}
