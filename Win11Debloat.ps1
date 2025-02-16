#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess)]
param (
    [switch]$Silent,
    [switch]$Sysprep,
    [switch]$RunAppConfigurator,
    [switch]$RunDefaults,
    [switch]$RunWin11Defaults,
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
    [switch]$DisableBingSearches,
    [switch]$DisableBing,
    [switch]$DisableDesktopSpotlight,
    [switch]$DisableLockscrTips,
    [switch]$DisableLockscreenTips,
    [switch]$DisableWindowsSuggestions,
    [switch]$DisableSuggestions,
    [switch]$ShowHiddenFolders,
    [switch]$ShowKnownFileExt,
    [switch]$HideDupliDrive,
    [switch]$TaskbarAlignLeft,
    [switch]$HideSearchTb,
    [switch]$ShowSearchIconTb,
    [switch]$ShowSearchLabelTb,
    [switch]$ShowSearchBoxTb,
    [switch]$HideTaskview,
    [switch]$DisableStartRecommended,
    [switch]$DisableCopilot,
    [switch]$DisableRecall,
    [switch]$DisableWidgets,
    [switch]$HideWidgets,
    [switch]$DisableChat,
    [switch]$HideChat,
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
    [switch]$DisableOnedrive,
    [switch]$HideOnedrive,
    [switch]$Disable3dObjects,
    [switch]$Hide3dObjects,
    [switch]$DisableMusic,
    [switch]$HideMusic,
    [switch]$DisableIncludeInLibrary,
    [switch]$HideIncludeInLibrary,
    [switch]$DisableGiveAccessTo,
    [switch]$HideGiveAccessTo,
    [switch]$DisableShare,
    [switch]$HideShare
)

# Import modules
Import-Module "$PSScriptRoot/Modules/AppRemoval.psm1"
Import-Module "$PSScriptRoot/Modules/RegistryOperations.psm1"
Import-Module "$PSScriptRoot/Modules/UserInterface.psm1"
Import-Module "$PSScriptRoot/Modules/Configuration.psm1"
Import-Module "$PSScriptRoot/Modules/Utilities.psm1"
Import-Module "$PSScriptRoot/Modules/StartMenu.psm1"

# Show error if current powershell environment is limited by security policies
if ($ExecutionContext.SessionState.LanguageMode -ne "FullLanguage") {
    Write-Host "Error: Win11Debloat is unable to run on your system, powershell execution is restricted by security policies" -ForegroundColor Red
    Write-Output ""
    Write-Output "Press enter to exit..."
    Read-Host | Out-Null
    Exit
}

# If the number of keys in SPParams equals the number of keys in Params then no modifications/changes were selected
#  or added by the user, and the script can exit without making any changes.
if ($SPParamCount -eq $global:Params.Keys.Count) {
    Write-Output "The script completed without making any changes."

    AwaitKeyToExit
}
else {
    # Execute all selected/provided parameters
    switch ($global:Params.Keys) {
        'RemoveApps' {
            $appsList = ReadAppslistFromFile "$PSScriptRoot/Appslist.txt" 
            Write-Output "> Removing default selection of $($appsList.Count) apps..."
            RemoveApps $appsList
            continue
        }
        'RemoveAppsCustom' {
            if (-not (Test-Path "$PSScriptRoot/CustomAppsList")) {
                Write-Host "> Error: Could not load custom apps list from file, no apps were removed" -ForegroundColor Red
                Write-Output ""
                continue
            }
            $appsList = ReadAppslistFromFile "$PSScriptRoot/CustomAppsList"
            Write-Output "> Removing $($appsList.Count) apps..."
            RemoveApps $appsList
            continue
        }
        'RemoveCommApps' {
            Write-Output "> Removing Mail, Calendar and People apps..."
            $appsList = 'Microsoft.windowscommunicationsapps', 'Microsoft.People'
            RemoveApps $appsList
            continue
        }
        'RemoveW11Outlook' {
            $appsList = 'Microsoft.OutlookForWindows'
            Write-Output "> Removing new Outlook for Windows app..."
            RemoveApps $appsList
            continue
        }
        'RemoveDevApps' {
            $appsList = 'Microsoft.PowerAutomateDesktop', 'Microsoft.RemoteDesktop', 'Windows.DevHome'
            Write-Output "> Removing developer-related related apps..."
            RemoveApps $appsList
            continue
        }
        'RemoveGamingApps' {
            $appsList = 'Microsoft.GamingApp', 'Microsoft.XboxGameOverlay', 'Microsoft.XboxGamingOverlay'
            Write-Output "> Removing gaming related apps..."
            RemoveApps $appsList
            continue
        }
        "ForceRemoveEdge" {
            ForceRemoveEdge
            continue
        }
        'DisableDVR' {
            RegImport "> Disabling Xbox game/screen recording..." "Disable_DVR.reg"
            continue
        }
        'DisableTelemetry' {
            RegImport "> Disabling telemetry, diagnostic data, activity history, app-launch tracking and targeted ads..." "Disable_Telemetry.reg"
            continue
        }
        {$_ -in "DisableSuggestions", "DisableWindowsSuggestions"} {
            RegImport "> Disabling tips, tricks, suggestions and ads across Windows..." "Disable_Windows_Suggestions.reg"
            continue
        }
        'DisableDesktopSpotlight' {
            RegImport "> Disabling the 'Windows Spotlight' desktop background option..." "Disable_Desktop_Spotlight.reg"
            continue
        }
        {$_ -in "DisableLockscrTips", "DisableLockscreenTips"} {
            RegImport "> Disabling tips & tricks on the lockscreen..." "Disable_Lockscreen_Tips.reg"
            continue
        }
        {$_ -in "DisableBingSearches", "DisableBing"} {
            RegImport "> Disabling bing web search, bing AI & cortana in Windows search..." "Disable_Bing_Cortana_In_Search.reg"
            $appsList = 'Microsoft.BingSearch'
            RemoveApps $appsList
            continue
        }
        'DisableCopilot' {
            RegImport "> Disabling & removing Windows Copilot..." "Disable_Copilot.reg"
            $appsList = 'Microsoft.Copilot'
            RemoveApps $appsList
            continue
        }
        'DisableRecall' {
            RegImport "> Disabling Windows Recall snapshots..." "Disable_AI_Recall.reg"
            continue
        }
        'RevertContextMenu' {
            RegImport "> Restoring the old Windows 10 style context menu..." "Disable_Show_More_Options_Context_Menu.reg"
            continue
        }
        'DisableMouseAcceleration' {
            RegImport "> Turning off Enhanced Pointer Precision..." "Disable_Enhance_Pointer_Precision.reg"
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
            RegImport "> Disabling and hiding the start menu recommended section..." "Disable_Start_Recommended.reg"
            continue
        }
        'TaskbarAlignLeft' {
            RegImport "> Aligning taskbar buttons to the left..." "Align_Taskbar_Left.reg"
            continue
        }
        'HideSearchTb' {
            RegImport "> Hiding the search icon from the taskbar..." "Hide_Search_Taskbar.reg"
            continue
        }
        'ShowSearchIconTb' {
            RegImport "> Changing taskbar search to icon only..." "Show_Search_Icon.reg"
            continue
        }
        'ShowSearchLabelTb' {
            RegImport "> Changing taskbar search to icon with label..." "Show_Search_Icon_And_Label.reg"
            continue
        }
        'ShowSearchBoxTb' {
            RegImport "> Changing taskbar search to search box..." "Show_Search_Box.reg"
            continue
        }
        'HideTaskview' {
            RegImport "> Hiding the taskview button from the taskbar..." "Hide_Taskview_Taskbar.reg"
            continue
        }
        {$_ -in "HideWidgets", "DisableWidgets"} {
            RegImport "> Disabling the widget service and hiding the widget icon from the taskbar..." "Disable_Widgets_Taskbar.reg"
            continue
        }
        {$_ -in "HideChat", "DisableChat"} {
            RegImport "> Hiding the chat icon from the taskbar..." "Disable_Chat_Taskbar.reg"
            continue
        }
        'ExplorerToHome' {
            RegImport "> Changing the default location that File Explorer opens to `Home`..." "Launch_File_Explorer_To_Home.reg"
            continue
        }
        'ExplorerToThisPC' {
            RegImport "> Changing the default location that File Explorer opens to `This PC`..." "Launch_File_Explorer_To_This_PC.reg"
            continue
        }
        'ExplorerToDownloads' {
            RegImport "> Changing the default location that File Explorer opens to `Downloads`..." "Launch_File_Explorer_To_Downloads.reg"
            continue
        }
        'ExplorerToOneDrive' {
            RegImport "> Changing the default location that File Explorer opens to `OneDrive`..." "Launch_File_Explorer_To_OneDrive.reg"
            continue
        }
        'ShowHiddenFolders' {
            RegImport "> Unhiding hidden files, folders and drives..." "Show_Hidden_Folders.reg"
            continue
        }
        'ShowKnownFileExt' {
            RegImport "> Enabling file extensions for known file types..." "Show_Extensions_For_Known_File_Types.reg"
            continue
        }
        'HideHome' {
            RegImport "> Hiding the home section from the File Explorer navigation pane..." "Hide_Home_from_Explorer.reg"
            continue
        }
        'HideGallery' {
            RegImport "> Hiding the gallery section from the File Explorer navigation pane..." "Hide_Gallery_from_Explorer.reg"
            continue
        }
        'HideDupliDrive' {
            RegImport "> Hiding duplicate removable drive entries from the File Explorer navigation pane..." "Hide_duplicate_removable_drives_from_navigation_pane_of_File_Explorer.reg"
            continue
        }
        {$_ -in "HideOnedrive", "DisableOnedrive"} {
            RegImport "> Hiding the OneDrive folder from the File Explorer navigation pane..." "Hide_Onedrive_Folder.reg"
            continue
        }
        {$_ -in "Hide3dObjects", "Disable3dObjects"} {
            RegImport "> Hiding the 3D objects folder from the File Explorer navigation pane..." "Hide_3D_Objects_Folder.reg"
            continue
        }
        {$_ -in "HideMusic", "DisableMusic"} {
            RegImport "> Hiding the music folder from the File Explorer navigation pane..." "Hide_Music_folder.reg"
            continue
        }
        {$_ -in "HideIncludeInLibrary", "DisableIncludeInLibrary"} {
            RegImport "> Hiding 'Include in library' in the context menu..." "Disable_Include_in_library_from_context_menu.reg"
            continue
        }
        {$_ -in "HideGiveAccessTo", "DisableGiveAccessTo"} {
            RegImport "> Hiding 'Give access to' in the context menu..." "Disable_Give_access_to_context_menu.reg"
            continue
        }
        {$_ -in "HideShare", "DisableShare"} {
            RegImport "> Hiding 'Share' in the context menu..." "Disable_Share_from_context_menu.reg"
            continue
        }
    }

    RestartExplorer

    Write-Output ""
    Write-Output ""
    Write-Output ""
    Write-Output "Script completed successfully!"

    AwaitKeyToExit
}
