function AddParameter {
    param (
        $parameterName,
        $message
    )
    if (-not $global:Params.ContainsKey($parameterName)) {
        $global:Params.Add($parameterName, $true)
    }
    if (!(Test-Path "$PSScriptRoot/SavedSettings")) {
        $null = New-Item "$PSScriptRoot/SavedSettings"
    } elseif ($global:FirstSelection) {
        $null = Clear-Content "$PSScriptRoot/SavedSettings"
    }
    $global:FirstSelection = $false
    $entry = "$parameterName#- $message"
    Add-Content -Path "$PSScriptRoot/SavedSettings" -Value $entry
}

function DisplayCustomModeOptions {
    $WinVersion = Get-ItemPropertyValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' CurrentBuild
    PrintHeader 'Custom Mode'
    Do {
        Write-Host "Options:" -ForegroundColor Yellow
        Write-Host " (n) Don't remove any apps" -ForegroundColor Yellow
        Write-Host " (1) Only remove the default selection of bloatware apps from 'Appslist.txt'" -ForegroundColor Yellow
        Write-Host " (2) Remove default selection of bloatware apps, as well as mail & calendar apps, developer apps and gaming apps"  -ForegroundColor Yellow
        Write-Host " (3) Select which apps to remove and which to keep" -ForegroundColor Yellow
        $RemoveAppsInput = Read-Host "Remove any pre-installed apps? (n/1/2/3)" 
        if ($RemoveAppsInput -eq '3') {
            $result = ShowAppSelectionForm
            if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
                Write-Output ""
                Write-Host "Cancelled application selection, please try again" -ForegroundColor Red
                $RemoveAppsInput = 'c'
            }
            Write-Output ""
        }
    } while ($RemoveAppsInput -ne 'n' -and $RemoveAppsInput -ne '0' -and $RemoveAppsInput -ne '1' -and $RemoveAppsInput -ne '2' -and $RemoveAppsInput -ne '3') 
    switch ($RemoveAppsInput) {
        '1' {
            AddParameter 'RemoveApps' 'Remove default selection of bloatware apps'
        }
        '2' {
            AddParameter 'RemoveApps' 'Remove default selection of bloatware apps'
            AddParameter 'RemoveCommApps' 'Remove the Mail, Calendar, and People apps'
            AddParameter 'RemoveW11Outlook' 'Remove the new Outlook for Windows app'
            AddParameter 'RemoveDevApps' 'Remove developer-related apps'
            AddParameter 'RemoveGamingApps' 'Remove the Xbox App and Xbox Gamebar'
            AddParameter 'DisableDVR' 'Disable Xbox game/screen recording'
        }
        '3' {
            Write-Output "You have selected $($global:SelectedApps.Count) apps for removal"
            AddParameter 'RemoveAppsCustom' "Remove $($global:SelectedApps.Count) apps:"
            Write-Output ""
            if ($( Read-Host -Prompt "Disable Xbox game/screen recording? Also stops gaming overlay popups (y/n)" ) -eq 'y') {
                AddParameter 'DisableDVR' 'Disable Xbox game/screen recording'
            }
        }
    }
    Write-Output ""
    if ($( Read-Host -Prompt "Disable telemetry, diagnostic data, activity history, app-launch tracking and targeted ads? (y/n)" ) -eq 'y') {
        AddParameter 'DisableTelemetry' 'Disable telemetry, diagnostic data, activity history, app-launch tracking & targeted ads'
    }
    Write-Output ""
    if ($( Read-Host -Prompt "Disable tips, tricks, suggestions and ads in start, settings, notifications, explorer, desktop and lockscreen? (y/n)" ) -eq 'y') {
        AddParameter 'DisableSuggestions' 'Disable tips, tricks, suggestions and ads in start, settings, notifications and File Explorer'
        AddParameter 'DisableDesktopSpotlight' 'Disable the Windows Spotlight desktop background option.'
        AddParameter 'DisableLockscreenTips' 'Disable tips & tricks on the lockscreen'
    }
    Write-Output ""
    if ($( Read-Host -Prompt "Disable & remove bing web search, bing AI & cortana in Windows search? (y/n)" ) -eq 'y') {
        AddParameter 'DisableBing' 'Disable & remove bing web search, bing AI & cortana in Windows search'
    }
    if ($WinVersion -ge 22621){
        Write-Output ""
        if ($( Read-Host -Prompt "Disable & remove Windows Copilot? This applies to all users (y/n)" ) -eq 'y') {
            AddParameter 'DisableCopilot' 'Disable and remove Windows Copilot'
        }
        Write-Output ""
        if ($( Read-Host -Prompt "Disable Windows Recall snapshots? This applies to all users (y/n)" ) -eq 'y') {
            AddParameter 'DisableRecall' 'Disable Windows Recall snapshots'
        }
    }
    if ($WinVersion -ge 22000){
        Write-Output ""
        if ($( Read-Host -Prompt "Restore the old Windows 10 style context menu? (y/n)" ) -eq 'y') {
            AddParameter 'RevertContextMenu' 'Restore the old Windows 10 style context menu'
        }
    }
    Write-Output ""
    if ($( Read-Host -Prompt "Turn off Enhance Pointer Precision, also known as mouse acceleration? (y/n)" ) -eq 'y') {
        AddParameter 'DisableMouseAcceleration' 'Turn off Enhance Pointer Precision (mouse acceleration)'
    }
    if ((get-ciminstance -query "select caption from win32_operatingsystem where caption like '%Windows 10%'") -or $global:Params.ContainsKey('RevertContextMenu')){
        Write-Output ""
        if ($( Read-Host -Prompt "Do you want to disable any context menu options? (y/n)" ) -eq 'y') {
            Write-Output ""
            if ($( Read-Host -Prompt "   Hide the 'Include in library' option in the context menu? (y/n)" ) -eq 'y') {
                AddParameter 'HideIncludeInLibrary' "Hide the 'Include in library' option in the context menu"
            }
            Write-Output ""
            if ($( Read-Host -Prompt "   Hide the 'Give access to' option in the context menu? (y/n)" ) -eq 'y') {
                AddParameter 'HideGiveAccessTo' "Hide the 'Give access to' option in the context menu"
            }
            Write-Output ""
            if ($( Read-Host -Prompt "   Hide the 'Share' option in the context menu? (y/n)" ) -eq 'y') {
                AddParameter 'HideShare' "Hide the 'Share' option in the context menu"
            }
        }
    }
    if ($WinVersion -ge 22621){
        Write-Output ""
        if ($( Read-Host -Prompt "Do you want to make any changes to the start menu? (y/n)" ) -eq 'y') {
            Write-Output ""
            if ($global:Params.ContainsKey("Sysprep")) {
                if ($( Read-Host -Prompt "Remove all pinned apps from the start menu for all existing and new users? (y/n)" ) -eq 'y') {
                    AddParameter 'ClearStartAllUsers' 'Remove all pinned apps from the start menu for existing and new users'
                }
            } else {
                Do {
                    Write-Host "   Options:" -ForegroundColor Yellow
                    Write-Host "    (n) Don't remove any pinned apps from the start menu" -ForegroundColor Yellow
                    Write-Host "    (1) Remove all pinned apps from the start menu for this user only ($env:USERNAME)" -ForegroundColor Yellow
                    Write-Host "    (2) Remove all pinned apps from the start menu for all existing and new users"  -ForegroundColor Yellow
                    $ClearStartInput = Read-Host "   Remove all pinned apps from the start menu? (n/1/2)" 
                } while ($ClearStartInput -ne 'n' -and $ClearStartInput -ne '0' -and $ClearStartInput -ne '1' -and $ClearStartInput -ne '2') 
                switch ($ClearStartInput) {
                    '1' {
                        AddParameter 'ClearStart' "Remove all pinned apps from the start menu for this user only"
                    }
                    '2' {
                        AddParameter 'ClearStartAllUsers' "Remove all pinned apps from the start menu for all existing and new users"
                    }
                }
            }
            Write-Output ""
            if ($( Read-Host -Prompt "   Disable & hide the recommended section in the start menu? This applies to all users (y/n)" ) -eq 'y') {
                AddParameter 'DisableStartRecommended' 'Disable & hide the recommended section in the start menu.'
            }
        }
    }
    Write-Output ""
    if ($( Read-Host -Prompt "Do you want to make any changes to the taskbar and related services? (y/n)" ) -eq 'y') {
        if ($WinVersion -ge 22000){
            Write-Output ""
            if ($( Read-Host -Prompt "   Align taskbar buttons to the left side? (y/n)" ) -eq 'y') {
                AddParameter 'TaskbarAlignLeft' 'Align taskbar icons to the left'
            }
            Do {
                Write-Output ""
                Write-Host "   Options:" -ForegroundColor Yellow
                Write-Host "    (n) No change" -ForegroundColor Yellow
                Write-Host "    (1) Hide search icon from the taskbar" -ForegroundColor Yellow
                Write-Host "    (2) Show search icon on the taskbar" -ForegroundColor Yellow
                Write-Host "    (3) Show search icon with label on the taskbar" -ForegroundColor Yellow
                Write-Host "    (4) Show search box on the taskbar" -ForegroundColor Yellow
                $TbSearchInput = Read-Host "   Hide or change the search icon on the taskbar? (n/1/2/3/4)" 
            } while ($TbSearchInput -ne 'n' -and $TbSearchInput -ne '0' -and $TbSearchInput -ne '1' -and $TbSearchInput -ne '2' -and $TbSearchInput -ne '3' -and $TbSearchInput -ne '4') 
            switch ($TbSearchInput) {
                '1' {
                    AddParameter 'HideSearchTb' 'Hide search icon from the taskbar'
                }
                '2' {
                    AddParameter 'ShowSearchIconTb' 'Show search icon on the taskbar'
                }
                '3' {
                    AddParameter 'ShowSearchLabelTb' 'Show search icon with label on the taskbar'
                }
                '4' {
                    AddParameter 'ShowSearchBoxTb' 'Show search box on the taskbar'
                }
            }
            Write-Output ""
            if ($( Read-Host -Prompt "   Hide the taskview button from the taskbar? (y/n)" ) -eq 'y') {
                AddParameter 'HideTaskview' 'Hide the taskview button from the taskbar'
            }
        }
        Write-Output ""
        if ($( Read-Host -Prompt "   Disable the widgets service and hide the icon from the taskbar? (y/n)" ) -eq 'y') {
            AddParameter 'DisableWidgets' 'Disable the widget service & hide the widget (news and interests) icon from the taskbar'
        }
        if ($WinVersion -le 22621){
            Write-Output ""
            if ($( Read-Host -Prompt "   Hide the chat (meet now) icon from the taskbar? (y/n)" ) -eq 'y') {
                AddParameter 'HideChat' 'Hide the chat (meet now) icon from the taskbar'
            }
        }
    }
    Write-Output ""
    if ($( Read-Host -Prompt "Do you want to make any changes to File Explorer? (y/n)" ) -eq 'y') {
        Do {
            Write-Output ""
            Write-Host "   Options:" -ForegroundColor Yellow
            Write-Host "    (n) No change" -ForegroundColor Yellow
            Write-Host "    (1) Open File Explorer to 'Home'" -ForegroundColor Yellow
            Write-Host "    (2) Open File Explorer to 'This PC'" -ForegroundColor Yellow
            Write-Host "    (3) Open File Explorer to 'Downloads'" -ForegroundColor Yellow
            Write-Host "    (4) Open File Explorer to 'OneDrive'" -ForegroundColor Yellow
            $ExplSearchInput = Read-Host "   Change the default location that File Explorer opens to? (n/1/2/3/4)" 
        } while ($ExplSearchInput -ne 'n' -and $ExplSearchInput -ne '0' -and $ExplSearchInput -ne '1' -and $ExplSearchInput -ne '2' -and $ExplSearchInput -ne '3' -and $ExplSearchInput -ne '4') 
        switch ($ExplSearchInput) {
            '1' {
                AddParameter 'ExplorerToHome' "Change the default location that File Explorer opens to 'Home'"
            }
            '2' {
                AddParameter 'ExplorerToThisPC' "Change the default location that File Explorer opens to 'This PC'"
            }
            '3' {
                AddParameter 'ExplorerToDownloads' "Change the default location that File Explorer opens to 'Downloads'"
            }
            '4' {
                AddParameter 'ExplorerToOneDrive' "Change the default location that File Explorer opens to 'OneDrive'"
            }
        }
        Write-Output ""
        if ($( Read-Host -Prompt "   Show hidden files, folders and drives? (y/n)" ) -eq 'y') {
            AddParameter 'ShowHiddenFolders' 'Show hidden files, folders and drives'
        }
        Write-Output ""
        if ($( Read-Host -Prompt "   Show file extensions for known file types? (y/n)" ) -eq 'y') {
            AddParameter 'ShowKnownFileExt' 'Show file extensions for known file types'
        }
        if ($WinVersion -ge 22000){
            Write-Output ""
            if ($( Read-Host -Prompt "   Hide the Home section from the File Explorer sidepanel? (y/n)" ) -eq 'y') {
                AddParameter 'HideHome' 'Hide the Home section from the File Explorer sidepanel'
            }
            Write-Output ""
            if ($( Read-Host -Prompt "   Hide the Gallery section from the File Explorer sidepanel? (y/n)" ) -eq 'y') {
                AddParameter 'HideGallery' 'Hide the Gallery section from the File Explorer sidepanel'
            }
        }
        Write-Output ""
        if ($( Read-Host -Prompt "   Hide duplicate removable drive entries from the File Explorer sidepanel so they only show under This PC? (y/n)" ) -eq 'y') {
            AddParameter 'HideDupliDrive' 'Hide duplicate removable drive entries from the File Explorer sidepanel'
        }
        if (get-ciminstance -query "select caption from win32_operatingsystem where caption like '%Windows 10%'"){
            Write-Output ""
            if ($( Read-Host -Prompt "Do you want to hide any folders from the File Explorer sidepanel? (y/n)" ) -eq 'y') {
                Write-Output ""
                if ($( Read-Host -Prompt "   Hide the OneDrive folder from the File Explorer sidepanel? (y/n)" ) -eq 'y') {
                    AddParameter 'HideOnedrive' 'Hide the OneDrive folder in the File Explorer sidepanel'
                }
                Write-Output ""
                if ($( Read-Host -Prompt "   Hide the 3D objects folder from the File Explorer sidepanel? (y/n)" ) -eq 'y') {
                    AddParameter 'Hide3dObjects' "Hide the 3D objects folder under 'This pc' in File Explorer" 
                }
                Write-Output ""
                if ($( Read-Host -Prompt "   Hide the music folder from the File Explorer sidepanel? (y/n)" ) -eq 'y') {
                    AddParameter 'HideMusic' "Hide the music folder under 'This pc' in File Explorer"
                }
            }
        }
    }
    if (-not $Silent) {
        Write-Output ""
        Write-Output ""
        Write-Output ""
        Write-Output "Press enter to confirm your choices and execute the script or press CTRL+C to quit..."
        Read-Host | Out-Null
    }
    PrintHeader 'Custom Mode'
}
