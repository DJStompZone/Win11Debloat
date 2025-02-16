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


$global:rootPath = $PSScriptRoot

if ((Get-AppxPackage -Name "*Microsoft.DesktopAppInstaller*") -and ((winget -v) -replace 'v','' -gt 1.4)) {
    $global:wingetInstalled = $true
}
else {
    $global:wingetInstalled = $false

    # Show warning that requires user confirmation, Suppress confirmation if Silent parameter was passed
    if (-not $Silent) {
        Write-Warning "Winget is not installed or outdated. This may prevent Win11Debloat from removing certain apps."
        Write-Output ""
        Write-Output "Press any key to continue anyway..."
        $null = [System.Console]::ReadKey()
    }
}

# Get current Windows build version to compare against features
$WinVersion = Get-ItemPropertyValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' CurrentBuild

$global:Params = $PSBoundParameters
$global:FirstSelection = $true
$SPParams = 'WhatIf', 'Confirm', 'Verbose', 'Silent', 'Sysprep', 'Debug'
$SPParamCount = 0

# Count how many SPParams exist within Params
# This is later used to check if any options were selected
foreach ($Param in $SPParams) {
    if ($global:Params.ContainsKey($Param)) {
        $SPParamCount++
    }
}

# Hide progress bars for app removal, as they block Win11Debloat's output
if (-not ($global:Params.ContainsKey("Verbose"))) {
    $ProgressPreference = 'SilentlyContinue'
}
else {
    Read-Host "Verbose mode is enabled, press enter to continue"
    $ProgressPreference = 'Continue'
}

if ($global:Params.ContainsKey("Sysprep")) {
    $defaultUserPath = $env:USERPROFILE -Replace ('\\' + $env:USERNAME + '$'), '\Default\NTUSER.DAT'

    # Exit script if default user directory or NTUSER.DAT file cannot be found
    if (-not (Test-Path "$defaultUserPath")) {
        Write-Host "Error: Unable to start Win11Debloat in Sysprep mode, cannot find default user folder at '$defaultUserPath'" -ForegroundColor Red
        AwaitKeyToExit
        Exit
    }
    # Exit script if run in Sysprep mode on Windows 10
    if ($WinVersion -lt 22000) {
        Write-Host "Error: Win11Debloat Sysprep mode is not supported on Windows 10" -ForegroundColor Red
        AwaitKeyToExit
        Exit
    }
}

# Remove SavedSettings file if it exists and is empty
if ((Test-Path "$rootPath/SavedSettings") -and ([String]::IsNullOrWhiteSpace((Get-content "$rootPath/SavedSettings")))) {
    Remove-Item -Path "$rootPath/SavedSettings" -recurse
}

# Only run the app selection form if the 'RunAppConfigurator' parameter was passed to the script
if ($RunAppConfigurator) {
    PrintHeader "App Configurator"

    $result = ShowAppSelectionForm

    # Show different message based on whether the app selection was saved or cancelled
    if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
        Write-Host "App configurator was closed without saving." -ForegroundColor Red
    }
    else {
        Write-Output "Your app selection was saved to the 'CustomAppsList' file in the root folder of the script."
    }

    AwaitKeyToExit
    Exit
}

# Change script execution based on provided parameters or user input
if ((-not $global:Params.Count) -or $RunDefaults -or $RunWin11Defaults -or $RunSavedSettings -or ($SPParamCount -eq $global:Params.Count)) {
    if ($RunDefaults -or $RunWin11Defaults) {
        $Mode = '1'
    }
    elseif ($RunSavedSettings) {
        if(-not (Test-Path "$rootPath/SavedSettings")) {
            PrintHeader 'Custom Mode'
            Write-Host "Error: No saved settings found, no changes were made" -ForegroundColor Red
            AwaitKeyToExit
            Exit
        }

        $Mode = '4'
    }
    else {
        # Show menu and wait for user input, loops until valid input is provided
        Do { 
            $ModeSelectionMessage = "Please select an option (1/2/3/0)" 

            PrintHeader 'Menu'

            Write-Output "(1) Default mode: Apply the default settings"
            Write-Output "(2) Custom mode: Modify the script to your needs"
            Write-Output "(3) App removal mode: Select & remove apps, without making other changes"

            # Only show this option if SavedSettings file exists
            if (Test-Path "$rootPath/SavedSettings") {
                Write-Output "(4) Apply saved custom settings from last time"
                
                $ModeSelectionMessage = "Please select an option (1/2/3/4/0)" 
            }

            Write-Output ""
            Write-Output "(0) Show more information"
            Write-Output ""
            Write-Output ""

            $Mode = Read-Host $ModeSelectionMessage

            # Show information based on user input, Suppress user prompt if Silent parameter was passed
            if ($Mode -eq '0') {
                # Get & print script information from file
                PrintFromFile "$rootPath/Assets/Menus/Info"

                Write-Output ""
                Write-Output "Press any key to go back..."
                $null = [System.Console]::ReadKey()
            }
            elseif (($Mode -eq '4')-and -not (Test-Path "$rootPath/SavedSettings")) {
                $Mode = $null
            }
        }

        while ($Mode -ne '1' -and $Mode -ne '2' -and $Mode -ne '3' -and $Mode -ne '4') 
    }

    # Add execution parameters based on the mode
    switch ($Mode) {
        # Default mode, loads defaults after confirmation
        '1' { 
            # Print the default settings & require userconfirmation, unless Silent parameter was passed
            if (-not $Silent) {
                PrintFromFile "$rootPath/Assets/Menus/DefaultSettings"

                Write-Output ""
                Write-Output "Press enter to execute the script or press CTRL+C to quit..."
                Read-Host | Out-Null
            }

            $DefaultParameterNames = 'RemoveApps','DisableTelemetry','DisableBing','DisableLockscreenTips','DisableSuggestions','ShowKnownFileExt','DisableWidgets','HideChat','DisableCopilot'

            PrintHeader 'Default Mode'

            # Add default parameters if they don't already exist
            foreach ($ParameterName in $DefaultParameterNames) {
                if (-not $global:Params.ContainsKey($ParameterName)){
                    $global:Params.Add($ParameterName, $true)
                }
            }

            # Only add this option for Windows 10 users, if it doesn't already exist
            if ((get-ciminstance -query "select caption from win32_operatingsystem where caption like '%Windows 10%'") -and (-not $global:Params.ContainsKey('Hide3dObjects'))) {
                $global:Params.Add('Hide3dObjects', $Hide3dObjects)
            }
        }

        # Custom mode, show & add options based on user input
        '2' { 
            DisplayCustomModeOptions
        }

        # App removal, remove apps based on user selection
        '3' {
            PrintHeader "App Removal"

            $result = ShowAppSelectionForm

            if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
                Write-Output "You have selected $($global:SelectedApps.Count) apps for removal"
                AddParameter 'RemoveAppsCustom' "Remove $($global:SelectedApps.Count) apps:"

                # Suppress prompt if Silent parameter was passed
                if (-not $Silent) {
                    Write-Output ""
                    Write-Output "Press enter to remove the selected apps or press CTRL+C to quit..."
                    Read-Host | Out-Null
                    PrintHeader "App Removal"
                }
            }
            else {
                Write-Host "Selection was cancelled, no apps have been removed" -ForegroundColor Red
                Write-Output ""
            }
        }

        # Load custom options selection from the "SavedSettings" file
        '4' {
            PrintHeader 'Custom Mode'
            Write-Output "Win11Debloat will make the following changes:"

            # Get & print default settings info from file
            Foreach ($line in (Get-Content -Path "$rootPath/SavedSettings" )) { 
                # Remove any spaces before and after the line
                $line = $line.Trim()
            
                # Check if the line contains a comment
                if (-not ($line.IndexOf('#') -eq -1)) {
                    $parameterName = $line.Substring(0, $line.IndexOf('#'))

                    # Print parameter description and add parameter to Params list
                    if ($parameterName -eq "RemoveAppsCustom") {
                        if (-not (Test-Path "$rootPath/CustomAppsList")) {
                            # Apps file does not exist, skip
                            continue
                        }
                        
                        $appsList = ReadAppslistFromFile "$rootPath/CustomAppsList"
                        Write-Output "- Remove $($appsList.Count) apps:"
                        Write-Host $appsList -ForegroundColor DarkGray
                    }
                    else {
                        Write-Output $line.Substring(($line.IndexOf('#') + 1), ($line.Length - $line.IndexOf('#') - 1))
                    }

                    if (-not $global:Params.ContainsKey($parameterName)){
                        $global:Params.Add($parameterName, $true)
                    }
                }
            }

            if (-not $Silent) {
                Write-Output ""
                Write-Output ""
                Write-Output "Press enter to execute the script or press CTRL+C to quit..."
                Read-Host | Out-Null
            }

            PrintHeader 'Custom Mode'
        }
    }
}
else {
    PrintHeader 'Custom Mode'
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

    Write-Output ""
    Write-Output ""
    Write-Output ""
    Write-Output "Script completed successfully!"

    AwaitKeyToExit
}