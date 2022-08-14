[string]$MSI_FileHash = '7C779CD6BC1B210F322B93C05BE2A0C9F417E147BEF414244CB56B74E3206617'
$Folder_path = "c:\temp\"
$MSI_File_Name = "ZoomInstallerFull.msi"
$MSI_Full_Path = $Folder_path + $MSI_File_Name
$MSI_URL = "https://zoom.us/client/latest/ZoomInstallerFull.msi"

function DownloadZoomMSI {
    Import-Module BitsTransfer
    $Job = Start-BitsTransfer -Source $MSI_URL -Destination $MSI_Full_Path -Asynchronous
    while (($Job.JobState -eq "Transferring") -or ($Job.JobState -eq "Connecting")) `
    {
        $pct = [int](($Job.BytesTransferred * 100) / $Job.BytesTotal)
        Write-Progress -Activity "Copying file..." -CurrentOperation "$pct% complete"
        Start-Sleep 1
    }
    Switch ($Job.JobState) {
        "Transferred" { Complete-BitsTransfer -BitsJob $Job }
        "Error" { $Job | Format-List } # List the errors.
        default { "Other action" } #  Perform corrective action.
    }
}

#Download Zoom MSI
if (!(Test-Path $MSI_Full_Path)) {
    if (!(Test-Path $Folder_path)) { mkdir $Folder_path }
    DownloadZoomMSI
}
else {
    if (!((Get-FileHash $MSI_Full_Path).Hash -eq $MSI_FileHash)) {
        Remove-Item $Full_Path
        DownloadZoomMSI
    }
}

#Install Duo and reboot
Start-Process "msiexec.exe" -ArgumentList '/I C:\temp\zoominstallerfull.msi /quiet' -Wait -NoNewWindow
Start-Sleep 15

$checkinstall = (Get-WmiObject -Class Win32_Product).name | Select-String "Zoom"
if ($checkinstall) {
    Write-Host "Zoom found. Installation complete."
    exit 0
} elseif (!($checkinstall)) {
    Write-host "Zoom NOT found. Rerun installer."
    exit 1
}
