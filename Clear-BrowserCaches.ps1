#requires -Version 2
#requires -PSEdition Desktop

<#
.SYNOPSIS
Clear all browser caches for either logged in user or all users on a machine

.DESCRIPTION
Clearing your browser caches periodically improves application performance and helps protect your privacy. 

This script will clear any browser caches found for Internet Explorer, Edge, Chrome, Chromium, Yandex, Vivaldi, Opera, and Brave. 

.PARAMETER ClearLoggedInUserCache
This only clears the browser caches of the logged in user

.PARAMETER ClearAllUsersCache
This clears all browser caches from all users on the machine

.EXAMPLE
Clear-BrowserCaches.ps1 -ClearAllUsersCache
#>

param (
    [switch]$ClearLoggedInUserCache,
    [switch]$ClearAllUsersCache
)

function Clear-BrowserCaches {
    #Delete Internet Explorer Cache
    Remove-Item -Path "C:\Users\$user\AppData\Local\Microsoft\Windows\Temporary Internet Files\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
    Remove-Item -Path "C:\Users\$user\AppData\Local\Microsoft\Windows\INetCache\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
    Remove-Item -Path "C:\Users\$user\AppData\Local\Microsoft\Windows\WebCache\* " -Recurse -Force -ErrorAction SilentlyContinue -Verbose
    Write-Host -ForegroundColor yellow "Internet Explorer Cache Removal - COMPLETE"

    #Delete Google Chrome Cache
    if (Test-Path "C:\Users\$user\AppData\Local\Google\Chrome\User Data") {
        Remove-Item -Path "C:\Users\$user\AppData\Local\Google\Chrome\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "C:\Users\$user\AppData\Local\Google\Chrome\User Data\Default\Cache2\entries\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "C:\Users\$user\AppData\Local\Google\Chrome\User Data\Default\Cookies" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "C:\Users\$user\AppData\Local\Google\Chrome\User Data\Default\Media Cache" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "C:\Users\$user\AppData\Local\Google\Chrome\User Data\Default\Cookies-Journal" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "C:\Users\$user\AppData\Local\Google\Chrome\User Data\Default\JumpListIconsOld" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "C:\Users\$user\AppData\Local\Google\Chrome\User Data\Default\ChromeDWriteFontCache" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        
        $Profiles = Get-ChildItem -Path "C:\Users\$user\AppData\Local\Google\Chrome\User Data" | Select-Object Name | Where-Object Name -Like "Profile*"
        foreach ($Account in $Profiles) {
            $Account = $Account.Name 
            Remove-Item -Path "C:\Users\$user\AppData\Local\Google\Chrome\User Data\$Account\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
            Remove-Item -Path "C:\Users\$user\AppData\Local\Google\Chrome\User Data\$Account\Cache2\entries\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose 
            Remove-Item -Path "C:\Users\$user\AppData\Local\Google\Chrome\User Data\$Account\Cookies" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
            Remove-Item -Path "C:\Users\$user\AppData\Local\Google\Chrome\User Data\$Account\Media Cache" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
            Remove-Item -Path "C:\Users\$user\AppData\Local\Google\Chrome\User Data\$Account\Cookies-Journal" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
            Remove-Item -Path "C:\Users\$user\AppData\Local\Google\Chrome\User Data\$Account\JumpListIconsOld" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        }

        Write-Host -ForegroundColor yellow "Google Chrome Cache Removal - COMPLETE"  
    }  

    
    #Delete Firefox Cache
    if (Test-Path "C:\Users\$user\AppData\Local\Mozilla\Firefox\Profiles") {
        Remove-Item -Path "C:\Users\$user\AppData\Local\Mozilla\Firefox\Profiles\*\cache\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "C:\Users\$user\AppData\Local\Mozilla\Firefox\Profiles\*\cache2\entries\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "C:\Users\$user\AppData\Local\Mozilla\Firefox\Profiles\*\thumbnails\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "C:\Users\$user\AppData\Local\Mozilla\Firefox\Profiles\*\cookies.sqlite" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "C:\Users\$user\AppData\Local\Mozilla\Firefox\Profiles\*\webappsstore.sqlite" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "C:\Users\$user\AppData\Local\Mozilla\Firefox\Profiles\*\chromeappsstore.sqlite" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "C:\Users\$user\AppData\Local\Mozilla\Firefox\Profiles\*\OfflineCache\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose

        Write-Host -ForegroundColor yellow "Firefox Cache Removal - COMPLETE"
    }
    

    #Delete Edge Cache
    if (Test-Path "C:\Users\$user\AppData\Local\Microsoft\Edge\User Data") {
        Remove-Item -Path "C:\Users\$user\AppData\Local\Microsoft\Edge\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "C:\Users\$user\AppData\Local\Microsoft\Edge\User Data\Default\Cache2\entries\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "C:\Users\$user\AppData\Local\Microsoft\Edge\User Data\Default\Cookies" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "C:\Users\$user\AppData\Local\Microsoft\Edge\User Data\Default\Media Cache" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "C:\Users\$user\AppData\Local\Microsoft\Edge\User Data\Default\Cookies-Journal" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "C:\Users\$user\AppData\Local\Microsoft\Edge\User Data\Default\JumpListIconsOld" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "C:\Users\$user\AppData\Local\Microsoft\Edge\User Data\Default\EdgeDWriteFontCache" -Recurse -Force -ErrorAction SilentlyContinue -Verbose

        $Profiles = Get-ChildItem -Path "C:\Users\$user\AppData\Local\Microsoft\Edge\User Data" | Select-Object Name | Where-Object Name -Like "Profile*"
        foreach ($Account in $Profiles) {
            $Account = $Account.Name 
            Remove-Item -Path "C:\Users\$user\AppData\Local\Microsoft\Edge\User Data\$Account\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
            Remove-Item -Path "C:\Users\$user\AppData\Local\Microsoft\Edge\User Data\$Account\Cache2\entries\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose 
            Remove-Item -Path "C:\Users\$user\AppData\Local\Microsoft\Edge\User Data\$Account\Cookies" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
            Remove-Item -Path "C:\Users\$user\AppData\Local\Microsoft\Edge\User Data\$Account\Media Cache" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
            Remove-Item -Path "C:\Users\$user\AppData\Local\Microsoft\Edge\User Data\$Account\Cookies-Journal" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
            Remove-Item -Path "C:\Users\$user\AppData\Local\Microsoft\Edge\User Data\$Account\JumpListIconsOld" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        }

        Write-Host -ForegroundColor yellow "Edge Cache Removal - COMPLETE"
    }

    #Delete Chromium Cache
    if (Test-Path "C:\Users\$user\AppData\Local\Chromium") {
        Remove-Item -Path "C:\Users\$user\AppData\Local\Chromium\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "C:\Users\$user\AppData\Local\Chromium\User Data\Default\GPUCache\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "C:\Users\$user\AppData\Local\Chromium\User Data\Default\Media Cache" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "C:\Users\$user\AppData\Local\Chromium\User Data\Default\Pepper Data" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "C:\Users\$user\AppData\Local\Chromium\User Data\Default\Application Cache" -Recurse -Force -ErrorAction SilentlyContinue -Verbose

        Write-Host -ForegroundColor yellow "Chromium Cache Removal - COMPLETE"
    }
    
    #Delete Yandex Cache
    if (Test-Path "C:\Users\$user\AppData\Local\Yandex") {
        Remove-Item -Path "C:\Users\$user\AppData\Local\Yandex\YandexBrowser\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "C:\Users\$user\AppData\Local\Yandex\YandexBrowser\User Data\Default\GPUCache\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "C:\Users\$user\AppData\Local\Yandex\YandexBrowser\User Data\Default\Media Cache\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "C:\Users\$user\AppData\Local\Yandex\YandexBrowser\User Data\Default\Pepper Data\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "C:\Users\$user\AppData\Local\Yandex\YandexBrowser\User Data\Default\Application Cache\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "C:\Users\$user\AppData\Local\Yandex\YandexBrowser\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Write-Host -ForegroundColor yellow "Yandex Cache Removal - COMPLETE"
    }

    #Delete Opera cache
    if (Test-Path "C:\Users\$user\AppData\Local\Opera Software") {
        Remove-Item -Path "C:\Users\$user\AppData\Local\Opera Software\Opera Stable\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Write-Host -ForegroundColor yellow "Opera Cache Removal - COMPLETE"
    }

    #Delete Vivaldi cache
    if (Test-Path "C:\Users\$user\AppData\Local\Vivaldi\Users Data\") {
        Remove-Item -Path "C:\Users\$user\AppData\Local\Vivaldi\User Data\Default\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Write-Host -ForegroundColor yellow "Vivaldi Cache Removal - COMPLETE"
    }

    #Delete Brave cache
    if (Test-Path "C:\users\$user\AppData\Local\BraveSoftware\Brave-Browser\") { 
        Remove-Item -Path "C:\Users\$user\AppData\Local\BraveSoftware\Brave-Browser\User Data\Default\Cache\Cache_Data" -Recurse -Force -ErrorAction SilentlyContinue -Verbose

        $Profiles = Get-ChildItem -Path "C:\Users\$user\AppData\Local\Google\Chrome\User Data" | Select-Object Name | Where-Object Name -Like "Profile*"
        foreach ($Account in $Profiles) {
            $Account = $Account.Name 
            Remove-Item -Path "C:\Users\$user\AppData\Local\BraveSoftware\Brave-Browser\User Data\$Account\Cache\Cache_Data" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        }

        Write-Host -ForegroundColor yellow "Brave Cache Removal - COMPLETE"

        #Delete User Cache
        Remove-Item -Path "C:\Users\$user\AppData\Local\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "C:\Users\$user\AppData\Local\Microsoft\Windows\WER\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "C:\Users\$user\AppData\Local\Microsoft\Windows\AppCache\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path "C:\Users\$user\AppData\Local\CrashDumps\*" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Write-Host -ForegroundColor yellow "User Cache Removal - COMPLETE"
    }
}

if ($ClearLoggedInUserCache) {
    $loggedinuser = (Get-WmiObject -Class Win32_ComputerSystem | Select-Object username).username
    if ($loggedinuser.contains('\') -eq $true) {
        $user = ($loggedinuser.split('\'))[1]
    }
    else {
        $user = $loggedinuser
    }
    Clear-BrowserCaches
}

if ($ClearAllUsersCache) {
    $users = (Get-ChildItem -Path "C:\Users").name
    foreach ($user in $users) {
        Clear-BrowserCaches
    }
}
