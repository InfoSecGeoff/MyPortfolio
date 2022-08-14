#requires -Version 5
#requires -PSEdition Desktop

<#
.SYNOPSIS
Install Duo Agent for Windows Logon (RDP) using keys from Integration page 

.DESCRIPTION
This script takes the suggested GPO deployment method of Duo agents and adapts it to run locally via RMM. 
It requires your Duo integration key (IKEY), secret key (SKEY), and API hostname (Hostkey)

.EXAMPLE
UniversalDuoInstaller.ps1 -SKEY 'xxxxxxxxx' -IKEY 'xxxxxxxxxx' -Hostkey 'xxxxxxxxxxxx.xxx.com'

.LINK
https://duo.com/docs/winlogon-gpo
#>

param(
    [string]$SKEY,
    [string]$IKEY,
    [string]$Hostkey
)


[string]$MSI_FileHash = 'cc2eb10706d573c4483d2535e0162743455932af794427c3f0e64931e302b00a'
$Folder_path = "c:\Temp\Duo\"
$MSI_File_Name = "DuoWinLogon_MSIs_Policies_and_Documentation-latest.zip"
$MSI_Full_Path = $Folder_path + $MSI_File_Name
$MSI_URL = "https://dl.duosecurity.com/DuoWinLogon_MSIs_Policies_and_Documentation-latest.zip"

$msi_arguments = @(
    "/qn"
    "/i"
    ('"{0}" REBOOT=ReallySuppress DONT_PROMPT_REBOOT=1 IKEY="{1}" SKEY="{2}" HOST="{3}"' -f 'C:\temp\duo\DuoWindowsLogon64.msi', $IKEY, $SKEY, $Hostkey)
)

function DownloadDuoMSI {
    Import-Module BitsTransfer
    $Job = Start-BitsTransfer -Source $MSI_URL -Destination $MSI_Full_Path -Asynchronous
    while (($Job.JobState -eq "Transferring") -or ($Job.JobState -eq "Connecting")) `
    {
        $pct = [int](($Job.BytesTransferred * 100) / $Job.BytesTotal)
        Write-Progress -Activity "Copying file..." -CurrentOperation "$pct% complete"
        Start-Sleep 1;
    }
    Switch ($Job.JobState) {
        "Transferred" { Complete-BitsTransfer -BitsJob $Job }
        "Error" { $Job | Format-List } # List the errors.
        default { "Other action" } #  Perform corrective action.
    }
}

#Download Duo MSI
if (!(Test-Path $MSI_Full_Path)) {
    if (!(Test-Path $Folder_path)) { mkdir $Folder_path }
    DownloadDuoMSI
}
else {
    if (!((Get-FileHash $MSI_Full_Path).Hash -eq $MSI_FileHash)) {
        Remove-Item $Full_Path
        DownloadDuoMSI
    }
}

#Install Duo and reboot
Expand-Archive -Path $MSI_Full_Path -Destination $Folder_path
Start-Process "msiexec.exe" -ArgumentList $msi_arguments -Wait -NoNewWindow
Start-Sleep 10

$checkinstall = (Get-WmiObject -Class Win32_Product).name | Select-String "Duo"
if ($checkinstall) {
    Write-Host "Duo found. Please reboot machine to finish."
    Remove-Item -Path $Folder_path -Recurse
    exit 0
}
elseif (!($checkinstall)) {
    Write-Host "Duo NOT found. Please rerun installation."
    exit 1
}
