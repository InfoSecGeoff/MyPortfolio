#requires -Version 5
#requires -PSEdition Desktop
#requires -RunAsAdministrator

<#
.SYNOPSIS
Disables CEIP In Windows 10 Enterprise

.DESCRIPTION
Enabled by default on Windows 10 Enterprise boxes, the Customer Experience Improvement Plan (CEIP) sends anonymized telemetry data back to Microsoft.
It is best to err on the side of caution, especially if you have compliance concerns, and disable CEIP in registry and scheduled tasks. Minimize attack surfaces by removing all unnecessary outbound traffic. 

.LINK
https://endurtech.com/how-to-disable-windows-10-customer-experience-improvement-program
#>


# disable registry CEIP
$parentpath = "HKLM:\SOFTWARE\Policies\Microsoft\SQMClient"
$childpath = $parentpath + '\Windows'
if (!(Test-Path $parentpath )) {
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\" -Name SQMClient
    New-Item -Path "$parentpath" -Name Windows
    Set-ItemProperty -Path "$childpath" -Name CEIPEnable -Value 0 
}
elseif (!(Test-Path $childpath)) {
    New-Item -Path "$parentpath" -Name Windows
    Set-ItemProperty -Path "$childpath" -Name CEIPEnable -Value 0 
}
else {
    Set-ItemProperty -Path "$childpath" -Name CEIPEnable -Value 0
}

# remove scheduled tasks related to CEIP
Unregister-ScheduledTask -TaskName 'Consolidator' -Confirm:$false
Unregister-ScheduledTask -TaskName 'UsbCeip' -Confirm:$false
