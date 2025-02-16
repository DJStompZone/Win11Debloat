param (
    [switch]$Silent,
    [switch]$Verbose,
    [switch]$Sysprep,
    [switch]$RunAppConfigurator,
    [switch]$RunDefaults, [switch]$RunWin11Defaults,
    [switch]$RunSavedSettings,
    [switch]$RemoveApps, 
    [switch]$RemoveAppsCustom,
    [switch]$RemoveGamingApps,
    [switch]$RemoveCommApps,
    [switch]$RemoveDevApps,
    [switch]$RemoveW11Outlook,
    [switch]$ForceRemoveEdge,
    [switch]$DisableDVR,
    [switch]$DisableTelemetry,
    [switch]$DisableBingSearches, [switch]$DisableBing,
    [switch]$DisableDesktopSpotlight,
    [switch]$DisableLockscrTips, [switch]$DisableLockscreenTips,
    [switch]$DisableWindowsSuggestions, [switch]$DisableSuggestions,
    [switch]$ShowHiddenFolders,
    [switch]$ShowKnownFileExt,
    [switch]$HideDupliDrive,
    [switch]$TaskbarAlignLeft,
    [switch]$HideSearchTb, [switch]$ShowSearchIconTb, [switch]$ShowSearchLabelTb, [switch]$ShowSearchBoxTb,
    [switch]$HideTaskview,
    [switch]$DisableStartRecommended,
    [switch]$DisableCopilot,
    [switch]$DisableRecall,
    [switch]$DisableWidgets, [switch]$HideWidgets,
    [switch]$DisableChat, [switch]$HideChat,
    [switch]$ClearStart,
    [switch]$ClearStartAllUsers,
    [switch]$RevertContextMenu,
    [switch]$DisableMouseAcceleration,
    [switch]$HideHome,
    [switch]$HideGallery,
    [switch]$ExplorerToHome,
    [switch]$ExplorerToThisPC,
    [switch]$ExplorerToDownloads,
    [switch]$ExplorerToOneDrive,
    [switch]$DisableOnedrive, [switch]$HideOnedrive,
    [switch]$Disable3dObjects, [switch]$Hide3dObjects,
    [switch]$DisableMusic, [switch]$HideMusic,
    [switch]$DisableIncludeInLibrary, [switch]$HideIncludeInLibrary,
    [switch]$DisableGiveAccessTo, [switch]$HideGiveAccessTo,
    [switch]$DisableShare, [switch]$HideShare
)

$global:rootPath = $PSScriptRoot

# Import modules
Import-Module "$PSScriptRoot/Modules/AppRemoval.psm1"
Import-Module "$PSScriptRoot/Modules/RegistryOperations.psm1"
Import-Module "$PSScriptRoot/Modules/UserInterface.psm1"
Import-Module "$PSScriptRoot/Modules/Configuration.psm1"
Import-Module "$PSScriptRoot/Modules/Utilities.psm1"
Import-Module "$PSScriptRoot/Modules/StartMenu.psm1"

# Show error if current powershell environment does not have LanguageMode set to FullLanguage 
if ($ExecutionContext.SessionState.LanguageMode -ne "FullLanguage") {
   Write-Host "Error: Win11Debloat is unable to run on your system. Powershell execution is restricted by security policies" -ForegroundColor Red
   Write-Output ""
   Write-Output "Press enter to exit..."
   Read-Host | Out-Null
   Exit
}

Clear-Host
Write-Output "-------------------------------------------------------------------------------------------"
Write-Output " Win11Debloat Script - Get"
Write-Output "-------------------------------------------------------------------------------------------"

Write-Output "> Downloading Win11Debloat..."

# Download latest version of Win11Debloat from github as zip archive
Invoke-WebRequest http://github.com/DJStompZone/win11debloat/archive/master.zip -OutFile "$env:TEMP/win11debloat-temp.zip"

# Remove old script folder if it exists, except for CustomAppsList and SavedSettings files
if (Test-Path "$env:TEMP/Win11Debloat/Win11Debloat-master") {
    Write-Output ""
    Write-Output "> Cleaning up old Win11Debloat folder..."
    Get-ChildItem -Path "$env:TEMP/Win11Debloat/Win11Debloat-master" -Exclude CustomAppsList,SavedSettings | Remove-Item -Recurse -Force
}

Write-Output ""
Write-Output "> Unpacking..."

# Unzip archive to Win11Debloat folder
Expand-Archive "$env:TEMP/win11debloat-temp.zip" "$env:TEMP/Win11Debloat"

# Remove archive
Remove-Item "$env:TEMP/win11debloat-temp.zip"

# Make list of arguments to pass on to the script
$arguments = $($PSBoundParameters.GetEnumerator() | ForEach-Object {"-$($_.Key)"})

Write-Output ""
Write-Output "> Running Win11Debloat..."

# Run Win11Debloat script with the provided arguments
$debloatProcess = Start-Process powershell.exe -PassThru -ArgumentList "-executionpolicy bypass -File $env:TEMP\Win11Debloat\Win11Debloat-master\Win11Debloat.ps1 $arguments" -Verb RunAs

# Wait for the process to finish before continuing
if ($null -ne $debloatProcess) {
    $debloatProcess.WaitForExit()
}

# Call functions from modules
if ($RunAppConfigurator) {
    PrintHeader "App Configurator"
    $result = ShowAppSelectionForm
    if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
        Write-Host "App configurator was closed without saving." -ForegroundColor Red
    } else {
        Write-Output "Your app selection was saved to the 'CustomAppsList' file in the root folder of the script."
    }
    AwaitKeyToExit
    Exit
}

switch ($global:Params.Keys) {
    'RemoveApps' {
        $appsList = ReadAppslistFromFile "$rootPath/Appslist.txt" 
        Write-Output "> Removing default selection of $($appsList.Count) apps..."
        RemoveApps -appsList $appsList -wingetInstalled $global:wingetInstalled -winVersion $WinVersion
        continue
    }
    'RemoveAppsCustom' {
        if (-not (Test-Path "$rootPath/CustomAppsList")) {
            Write-Host "> Error: Could not load custom apps list from file, no apps were removed" -ForegroundColor Red
            Write-Output ""
            continue
        }
        
        $appsList = ReadAppslistFromFile "$rootPath/CustomAppsList"
        Write-Output "> Removing $($appsList.Count) apps..."
        RemoveApps -appsList $appsList -wingetInstalled $global:wingetInstalled -winVersion $WinVersion
        continue
    }
    'RemoveCommApps' {
        Write-Output "> Removing Mail, Calendar and People apps..."
        
        $appsList = 'Microsoft.windowscommunicationsapps', 'Microsoft.People'
        RemoveApps -appsList $appsList -wingetInstalled $global:wingetInstalled -winVersion $WinVersion
        continue
    }
    'RemoveW11Outlook' {
        $appsList = 'Microsoft.OutlookForWindows'
        Write-Output "> Removing new Outlook for Windows app..."
        RemoveApps -appsList $appsList -wingetInstalled $global:wingetInstalled -winVersion $WinVersion
        continue
    }
    'RemoveDevApps' {
        $appsList = 'Microsoft.PowerAutomateDesktop', 'Microsoft.RemoteDesktop', 'Windows.DevHome'
        Write-Output "> Removing developer-related related apps..."
        RemoveApps -appsList $appsList -wingetInstalled $global:wingetInstalled -winVersion $WinVersion
        continue
    }
    'RemoveGamingApps' {
        $appsList = 'Microsoft.GamingApp', 'Microsoft.XboxGameOverlay', 'Microsoft.XboxGamingOverlay'
        Write-Output "> Removing gaming related apps..."
        RemoveApps -appsList $appsList -wingetInstalled $global:wingetInstalled -winVersion $WinVersion
        continue
    }
    "ForceRemoveEdge" {
        ForceRemoveEdge
        continue
    }
    'DisableDVR' {
        RegImport -message "> Disabling Xbox game/screen recording..." -path "Disable_DVR.reg" -sysprep $global:Params.ContainsKey("Sysprep") -rootPath $rootPath
        continue
    }
    'DisableTelemetry' {
        RegImport -message "> Disabling telemetry, diagnostic data, activity history, app-launch tracking and targeted ads..." -path "Disable_Telemetry.reg" -sysprep $global:Params.ContainsKey("Sysprep") -rootPath $rootPath
        continue
    }
    {$_ -in "DisableSuggestions", "DisableWindowsSuggestions"} {
        RegImport -message "> Disabling tips, tricks, suggestions and ads across Windows..." -path "Disable_Windows_Suggestions.reg" -sysprep $global:Params.ContainsKey("Sysprep") -rootPath $rootPath
        continue
    }
    'DisableDesktopSpotlight' {
        RegImport -message "> Disabling the 'Windows Spotlight' desktop background option..." -path "Disable_Desktop_Spotlight.reg" -sysprep $global:Params.ContainsKey("Sysprep") -rootPath $rootPath
        continue
    }
    {$_ -in "DisableLockscrTips", "DisableLockscreenTips"} {
        RegImport -message "> Disabling tips & tricks on the lockscreen..." -path "Disable_Lockscreen_Tips.reg" -sysprep $global:Params.ContainsKey("Sysprep") -rootPath $rootPath
        continue
    }
    {$_ -in "DisableBingSearches", "DisableBing"} {
        RegImport -message "> Disabling bing web search, bing AI & cortana in Windows search..." -path "Disable_Bing_Cortana_In_Search.reg" -sysprep $global:Params.ContainsKey("Sysprep") -rootPath $rootPath
        
        # Also remove the app package for bing search
        $appsList = 'Microsoft.BingSearch'
        RemoveApps -appsList $appsList -wingetInstalled $global:wingetInstalled -winVersion $WinVersion
        continue
    }
    'DisableCopilot' {
        RegImport -message "> Disabling & removing Windows Copilot..." -path "Disable_Copilot.reg" -sysprep $global:Params.ContainsKey("Sysprep") -rootPath $rootPath

        # Also remove the app package for bing search
        $appsList = 'Microsoft.Copilot'
        RemoveApps -appsList $appsList -wingetInstalled $global:wingetInstalled -winVersion $WinVersion
        continue
    }
    'DisableRecall' {
        RegImport -message "> Disabling Windows Recall snapshots..." -path "Disable_AI_Recall.reg" -sysprep $global:Params.ContainsKey("Sysprep") -rootPath $rootPath
        continue
    }
    'RevertContextMenu' {
        RegImport -message "> Restoring the old Windows 10 style context menu..." -path "Disable_Show_More_Options_Context_Menu.reg" -sysprep $global:Params.ContainsKey("Sysprep") -rootPath $rootPath
        continue
    }
    'DisableMouseAcceleration' {
        RegImport -message "> Turning off Enhanced Pointer Precision..." -path "Disable_Enhance_Pointer_Precision.reg" -sysprep $global:Params.ContainsKey("Sysprep") -rootPath $rootPath
        continue
    }
    'ClearStart' {
        Write-Output "> Removing all pinned apps from the start menu for user $env:USERNAME..."
        ReplaceStartMenu
        Write-Output ""
        continue
    }
    'ClearStartAllUsers' {
        ReplaceStartMenuForAllUsers
        continue
    }
    'DisableStartRecommended' {
        RegImport -message "> Disabling and hiding the start menu recommended section..." -path "Disable_Start_Recommended.reg" -sysprep $global:Params.ContainsKey("Sysprep") -rootPath $rootPath
        continue
    }
    'TaskbarAlignLeft' {
        RegImport -message "> Aligning taskbar buttons to the left..." -path "Align_Taskbar_Left.reg" -sysprep $global:Params.ContainsKey("Sysprep") -rootPath $rootPath
        continue
    }
    'HideSearchTb' {
        RegImport -message "> Hiding the search icon from the taskbar..." -path "Hide_Search_Taskbar.reg" -sysprep $global:Params.ContainsKey("Sysprep") -rootPath $rootPath
        continue
    }
    'ShowSearchIconTb' {
        RegImport -message "> Changing taskbar search to icon only..." -path "Show_Search_Icon.reg" -sysprep $global:Params.ContainsKey("Sysprep") -rootPath $rootPath
        continue
    }
    'ShowSearchLabelTb' {
        RegImport -message "> Changing taskbar search to icon with label..." -path "Show_Search_Icon_And_Label.reg" -sysprep $global:Params.ContainsKey("Sysprep") -rootPath $rootPath
        continue
    }
    'ShowSearchBoxTb' {
        RegImport -message "> Changing taskbar search to search box..." -path "Show_Search_Box.reg" -sysprep $global:Params.ContainsKey("Sysprep") -rootPath $rootPath
        continue
    }
    'HideTaskview' {
        RegImport -message "> Hiding the taskview button from the taskbar..." -path "Hide_Taskview_Taskbar.reg" -sysprep $global:Params.ContainsKey("Sysprep") -rootPath $rootPath
        continue
    }
    {$_ -in "HideWidgets", "DisableWidgets"} {
        RegImport -message "> Disabling the widget service and hiding the widget icon from the taskbar..." -path "Disable_Widgets_Taskbar.reg" -sysprep $global:Params.ContainsKey("Sysprep") -rootPath $rootPath
        continue
    }
    {$_ -in "HideChat", "DisableChat"} {
        RegImport -message "> Hiding the chat icon from the taskbar..." -path "Disable_Chat_Taskbar.reg" -sysprep $global:Params.ContainsKey("Sysprep") -rootPath $rootPath
        continue
    }
    'ExplorerToHome' {
        RegImport -message "> Changing the default location that File Explorer opens to `Home`..." -path "Launch_File_Explorer_To_Home.reg" -sysprep $global:Params.ContainsKey("Sysprep") -rootPath $rootPath
        continue
    }
    'ExplorerToThisPC' {
        RegImport -message "> Changing the default location that File Explorer opens to `This PC`..." -path "Launch_File_Explorer_To_This_PC.reg" -sysprep $global:Params.ContainsKey("Sysprep") -rootPath $rootPath
        continue
    }
    'ExplorerToDownloads' {
        RegImport -message "> Changing the default location that File Explorer opens to `Downloads`..." -path "Launch_File_Explorer_To_Downloads.reg" -sysprep $global:Params.ContainsKey("Sysprep") -rootPath $rootPath
        continue
    }
    'ExplorerToOneDrive' {
        RegImport -message "> Changing the default location that File Explorer opens to `OneDrive`..." -path "Launch_File_Explorer_To_OneDrive.reg" -sysprep $global:Params.ContainsKey("Sysprep") -rootPath $rootPath
        continue
    }
    'ShowHiddenFolders' {
        RegImport -message "> Unhiding hidden files, folders and drives..." -path "Show_Hidden_Folders.reg" -sysprep $global:Params.ContainsKey("Sysprep") -rootPath $rootPath
        continue
    }
    'ShowKnownFileExt' {
        RegImport -message "> Enabling file extensions for known file types..." -path "Show_Extensions_For_Known_File_Types.reg" -sysprep $global:Params.ContainsKey("Sysprep") -rootPath $rootPath
        continue
    }
    'HideHome' {
        RegImport -message "> Hiding the home section from the File Explorer navigation pane..." -path "Hide_Home_from_Explorer.reg" -sysprep $global:Params.ContainsKey("Sysprep") -rootPath $rootPath
        continue
    }
    'HideGallery' {
        RegImport -message "> Hiding the gallery section from the File Explorer navigation pane..." -path "Hide_Gallery_from_Explorer.reg" -sysprep $global:Params.ContainsKey("Sysprep") -rootPath $rootPath
        continue
    }
    'HideDupliDrive' {
        RegImport -message "> Hiding duplicate removable drive entries from the File Explorer navigation pane..." -path "Hide_duplicate_removable_drives_from_navigation_pane_of_File_Explorer.reg" -sysprep $global:Params.ContainsKey("Sysprep") -rootPath $rootPath
        continue
    }
    {$_ -in "HideOnedrive", "DisableOnedrive"} {
        RegImport -message "> Hiding the OneDrive folder from the File Explorer navigation pane..." -path "Hide_Onedrive_Folder.reg" -sysprep $global:Params.ContainsKey("Sysprep") -rootPath $rootPath
        continue
    }
    {$_ -in "Hide3dObjects", "Disable3dObjects"} {
        RegImport -message "> Hiding the 3D objects folder from the File Explorer navigation pane..." -path "Hide_3D_Objects_Folder.reg" -sysprep $global:Params.ContainsKey("Sysprep") -rootPath $rootPath
        continue
    }
    {$_ -in "HideMusic", "DisableMusic"} {
        RegImport -message "> Hiding the music folder from the File Explorer navigation pane..." -path "Hide_Music_folder.reg" -sysprep $global:Params.ContainsKey("Sysprep") -rootPath $rootPath
        continue
    }
    {$_ -in "HideIncludeInLibrary", "DisableIncludeInLibrary"} {
        RegImport -message "> Hiding 'Include in library' in the context menu..." -path "Disable_Include_in_library_from_context_menu.reg" -sysprep $global:Params.ContainsKey("Sysprep") -rootPath $rootPath
        continue
    }
    {$_ -in "HideGiveAccessTo", "DisableGiveAccessTo"} {
        RegImport -message "> Hiding 'Give access to' in the context menu..." -path "Disable_Give_access_to_context_menu.reg" -sysprep $global:Params.ContainsKey("Sysprep") -rootPath $rootPath
        continue
    }
    {$_ -in "HideShare", "DisableShare"} {
        RegImport -message "> Hiding 'Share' in the context menu..." -path "Disable_Share_from_context_menu.reg" -sysprep $global:Params.ContainsKey("Sysprep") -rootPath $rootPath
        continue
    }
}

RestartExplorer

# Remove all remaining script files, except for CustomAppsList and SavedSettings files
if (Test-Path "$env:TEMP/Win11Debloat/Win11Debloat-master") {
    Write-Output ""
    Write-Output "> Cleaning up..."

    # Cleanup, remove Win11Debloat directory
    Get-ChildItem -Path "$env:TEMP/Win11Debloat/Win11Debloat-master" -Exclude CustomAppsList,SavedSettings | Remove-Item -Recurse -Force
}

Write-Output ""
Write-Output ""
Write-Output ""
Write-Output "Script completed successfully!"

AwaitKeyToExit
