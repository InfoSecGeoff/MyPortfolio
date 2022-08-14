#requires -Version 5
#requires -RunAsAdministrator
#requires -PSEdition Desktop

<#
.SYNOPSIS
Checks for and removes FIPS mode from registry

.DESCRIPTION
The federal government used to recommend configuring Windows 10 and Windows server to run in a FIPS 140-2 approved mode, commonly referred to as FIPS mode, but all it does now it prevent newer, non-federally certified encryption schemes from being accepted. This includes new schemes developed by Microsoft; FIPS mode forces the .NET framework to disallow the use of non-validated algorithms despite their origin which can lead to unexpected issues. 

.PARAMETER CheckOnly
Only checks registry for FIPS mode enabled

.PARAMETER CheckandRemove
Checks for FIPS mode being enabled and if found disables it. This requires a reboot to fully process.

.PARAMETER Reboot
Includes reboot of the machince once FIPS mode is disabled

.EXAMPLE
Disable-FIPSMode.ps1 -CheckandRemove -Reboot

.LINK
https://www.howtogeek.com/245859/why-you-shouldnt-enable-fips-compliant-encryption-on-windows/

.LINK
https://techcommunity.microsoft.com/t5/microsoft-security-baselines/why-we-amp-8217-re-not-recommending-amp-8220-fips-mode-amp-8221/ba-p/701037

#>

param (
    [switch]$CheckOnly,
    [switch]$CheckandRemove,
    [switch]$Reboot
)

$path = 'HKLM:\System\CurrentControlSet\Control\Lsa\FIPSAlgorithmPolicy'
$regpath = Get-ItemProperty -Path $path
# Check for FIPS mode
if (($regpath).enabled -eq 1) {
    Write-Host "FIPS mode is enabled on this machine"
}
elseif (($regpath).enabled -eq 0) {
    Write-Host "FIPS mode is not enabled on this machine. Exiting script."
}
# Disable FIPS mode
if ($CheckandRemove) {
    Set-ItemProperty -Path $path -Name "Enabled" -Value 0
}
# Reboot
if ($reboot) {
    Restart-Computer -Force
}
