#requires -PSEdition Desktop
#requires -Version 5

<#
.SYNOPSIS
Enable DNS Scavenging on Windows DNS servers

.DESCRIPTION
Enabling DNS Scanvenging is Microsoft best practices and is also recommended by RMM vendors before their products are configured. Scavenging removes outdated DNS recoures which means DHCP will not detect duplicate devices thanks to multiple (stale) DNS entries. Note that this will clear any DNS records not statically set which can cause downtime if your environment is not carefully analyzed beforehand. This script delete all DNS records that are has half as old as the oldest DNS record.

You only need to run this on the primary domain controller as changes will replicate to other DCs.

.LINK
https://social.technet.microsoft.com/wiki/contents/articles/21724.how-dns-aging-and-scavenging-works.aspx
#>

if (((Get-CimInstance Win32_OperatingSystem).name) -match "Server 2008") {
    throw "This is a manual process for Server 2008. Please configure scavenging via GUI." ; return
}

if (((Get-CimInstance Win32_OperatingSystem).ProductType) -ne 2) {
    throw "This machine is not a domain controller. Please run this script on a domain controller." ; return
}

if (((Get-DnsServerScavenging).ScavengingState) -eq $True) {
    throw "Scavenging is already configured on this server." ; return
}

$LeaseTimes = @()
$DHCPLease = (Get-DhcpServerv4Scope).LeaseDuration
foreach ($lease in $DHCPLease) {
    $LeaseTimes += $lease.days
}
$LowestLeaseTime = $LeaseTimes | Sort-Object -Descending | Select-Object -Last 1

#Return all static DNS A records
Write-Host "Note: The following DNS records are statically set. Any records that are not statically set will eventually be cleared. This could lead to downtime if records are not correctly set." -ForegroundColor Red
$zonenames = (Get-DNSServerZone).ZoneName
foreach ($zone in $zonenames) {
    Get-DnsServerResourceRecord -ZoneName $zone | Where-Object { $_.TimeStamp -eq $Null -and $_.RecordType -eq 'A'`
        | Select-Object -Property HostName, RecordType -ExpandProperty RecordData 
    }
}

$HalfofLeaseTime = $LowestLeaseTime / 2
try {
    Set-DnsServerScavenging -RefreshInterval $HalfofLeaseTime -NoRefreshInterval $HalfofLeaseTime -Force
}
catch {
    $_.Exception
}
