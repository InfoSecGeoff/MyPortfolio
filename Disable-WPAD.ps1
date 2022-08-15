#requires -PSEdition Desktop
#requires -Version 5
#requires -RunAsAdministrator

<#
.SYNOPSIS
Disables the use of WPAD 

.DESCRIPTION
This script is an aggregate of multiple sources on disabling WPAD from browsers as well as the OS on Windows boxes. WPAD has multiple documented poisoning attacks yet is still enabled by default on all Windows machines. 

It is unlikely your environment is actually making use of automatic proxy discovery. This is an easy win for your SOC to implement on all machines. Once WPAD is disabled you will have to manually configure any future proxies.

.PARAMETER reboot
This will reboot the machine after registry changes are complete. Your registry changes may not take effect until after the machine has been rebooted.

.LINK
https://www.cisa.gov/uscert/ncas/alerts/TA16-144A
https://edico.no/tech/the-dangers-of-wpad-and-llmnr-protect-your-network/

#>

param (
    [switch]$reboot = $false
)

# Stops the WinHTTP WPAD service from querying fro wpad
$WpadPath1 = "HKLM:\SYSTEM\CurrentControlSet\Services\WinHttpAutoProxySvc\"
if ($WpadPath1) {
    Set-ItemProperty -Path $WpadPath1 -Name Start -Value 4 -ErrorAction SilentlyContinue
}

#this only works with Windows 10 and Server 2019
$WpadPath2 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp\"
if ($WpadPath2) {
    Set-ItemProperty -Path $WpadPath2 -Name DisableWpad -Value 1 -ErrorAction SilentlyContinue
}

$WpadPath3 = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
if ($WpadPath3) {
    Set-ItemProperty -Path $WpadPath3 ProxyEnable -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $WpadPath3 ProxyServer -Value "" -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $WpadPath3 AutoConfigURL -Value "" -ErrorAction SilentlyContinue
}

# remove WPAD from Global Query Block List, however this must be replaced with an A record for wpad at 127.0.0.1 after a reboot.
$WpadPath4 = "HKLM:\System\CurrentControlSet\Services\DNS\Parameters"
if ($WpadPath4) {
    Remove-ItemProperty -Path $WpadPath4 GlobalQueryBlockList -Value 'wpad' -ErrorAction SilentlyContinue 
}

# stop WPAD service
$WpadService = Get-Service -Name "WinHttpAutoProxySvc"
if ($Wpadservice -ne $null) {
    if ($WpadService.Status -eq "Running") {
        $ServicePID = (Get-WmiObject win32_service | Where-Object { $_.name -eq 'WinHttpAutoProxySvc' }).processID
        Stop-Process $ServicePID -Force
    }
    else {
        Write-Host "WPAD not running"
    }
    Set-Service "WinHttpAutoProxySvc" -StartupType Disabled
}


if ($reboot) {
    Restart-Computer -Force
}
