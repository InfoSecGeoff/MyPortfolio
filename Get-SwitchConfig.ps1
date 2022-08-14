#requires -version 3
#requires -RunAsAdministrator
#requires -PSEdition Desktop

<#
.SYNOPSIS
  Backing up the switch configs of HPE, Aruba, Cisco, Unifi, Fortinet, Dell and Cisco Small Business switches by utilizing Posh-SSH.
.DESCRIPTION
This script is designed to back up the running config on HPE, Aruba, Cisco, Unifi, Fortinet, Dell and Cisco Small Business switches through the use of Posh-SSH. It will store the configuration locally in the C:\AME\SwitchConfigs folder then upload to ITGlue via API.=

Known Problems:
- Switch having blank passwords
- Undocumented/incorrect SSH credentials
- Undocumented/incorrect enable passwords
- SSH not being enabled or SSH not being a feature of the switch
- PSGallery being blocked by firewall/IPS
- old version of Powershell installed on probe that doesn't suport posh-ssh
- no probe on site/serverless environment
- console user configured but not ssh user
- switch only authenticates with ssh keys not username/password
- console logging messages, if enabled, can interrupt ssh write stream. recommend using no logging console command from global config
- some HP switches cannot do show run only a show tech which generates a massive, unuseable amount of debug data
- switch config has a short ssh session timeout specified
- ssh throttling after too many errors or too many operations at once triggering security measures
- switch set to allow traffic from specific addresses and the probe isn't one of them
- possible read/write stream limiting in place either on switch or posh-ssh (??? hypothesis)
- switches having a config password on top of an enable password; this can be added to a later version if needed
- add in automated download and update of .net to minimum required 4.7 or higher

To Do:
- Build out and test Cisco Small Business switches
- Build out installer for .net 4.7 or greater with chocolatey
- Build out logging function and add to trimlogfunction
- Add checks to HP script for show run vs show running config vs show config
- Build out error handling for unrecognized commands OR just blast every possible terminal length blindly where there is confusion?
- fix error handling on Get-Config, need to be more specific than just catching that error class

.INPUTS
  
  $SwitchIP - The IP address of the target switch
  $SwitchMAC - The MAC address of the target switch
  $Username - Switch username needed for auth (found in ITGlue)
  $Password - Switch password neeeded for auth (found in ITGlue)
  $Port - Port connecting to but almost always port 22
  $SwitchName - Hostname of the switch
  $Manufacturer - The company who makes the switch
  $EnablePW - If there is an enable password defined it goes here (found in ITGlue)

.EXAMPLE
  Get-SwitchConfig.ps1 -SwitchIP 192.168.1.22 -Username user -Password password -Manufacturer HP

.NOTES
  Version:        1.0
  Lead Author:    KentuckyJohnOliver
  Contributors:   yosoybigmac, ZT
  Publish Date:   2/27/2022
  Purpose/Change: Initial script development
#>


[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$DebugPreference = "Continue"

# Params

param (
    [Parameter(Mandatory = $true)]
    $SwitchIP,
    [Parameter(Mandatory = $true)]
    $Username,
    [Parameter(Mandatory = $true)]
    $Password,
    [int]$port = 22,
    [string]$SwitchName,
    [Parameter(Mandatory = $true)]
    [ValidateSet("Unifi", "Fortinet", "Dell", "Cisco", "CiscoSmallBusiness", "Aruba", "HP")]
    $Manufacturer,
    [string]$EnablePW
)

$SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
$MyCreds = [System.Management.Automation.PSCredential]::new($Username, $SecurePassword)
$date = Get-Date -Format yyyy_MM_dd_HH_mm
if (!($switchname -eq $null)) {
    $Outputfolder = "C:\Temp\SwitchConfigs\$SwitchName-$manufacturer"
    $Outputfilepath = "$Outputfolder\$SwitchName-$manufacturer-$date.txt"
    $filename = "$SwitchName-$manufacturer-$date.txt"
}
else {
    $Outputfolder = "C:\Temp\SwitchConfigs\$manufacturer"
    $Outputfilepath = "$Outputfolder\$manufacturer-$date.txt"
    $filename = "$manufacturer-$date.txt"
}

$ConfigPath = "C:\Temp\SwitchConfigs\"
$Log = $outputfilepath
$RunningWrites = @()
$SessionID = ((Get-SSHSession).sessionid)

# PREREQS

Write-Debug "Running prereq checks..."
Write-Debug "Checking for minimum required version of .net"
if (!(Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full").Release -ge 460798) {
    Write-Host "Need to update .net to 4.7 or higher"
}
else {
    Write-Host ".NET prereq met"
}
Write-Debug "Checking for default repositories..."
if (!(Get-PSRepository -Name PSGallery)) {
    Register-PSRepository -Default -Verbose
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
}
else {
    Write-Host "Repository exists"
}
Write-Debug "Looking for NuGet"
try {
    if (((Get-PackageProvider).name) -match "NuGet") {
        Write-Host "NuGet found!"
    }
    else {
        Write-Host "NuGet not found! Installing..."
        Install-PackageProvider -Name NuGet -Force
    }
}
catch [System.Management.Automation.ErrorRecord] {
    Write-Host "NuGet not found. Install Nuget."
}
catch {
    throw "Error on trying to retrieve NuGet. Without NuGet, Posh-SSH cannot be installed. Terminating script." ; return
}

Write-Debug "Looking for PoshSSH"
if (!(Get-Module -Name "Posh-SSH")) {
    Install-Module -Name "Posh-SSH" -Force
    Import-Module -Name "Posh-SSH" -ErrorAction Stop
}
else {
    Import-Module -Name "Posh-SSH" -ErrorAction Stop
}
Write-Debug "Looking for switch config folder"
if (!(Test-Path -Path $Outputfolder)) {
    if (!($switchname -eq $null)) {
        New-Item -ItemType Directory -Path 'C:\temp\SwitchConfigs' -Name "$SwitchName-$manufacturer"
    }
    else {
        New-Item -ItemType Directory -Path 'C:\temp\SwitchConfigs' -Name "$manufacturer"
    } 
} 

# FUNCTIONS

function Remove-SSHSessions {
    Write-Debug "Running Remove-SSHSessions"
    try {
        $sessions = Get-SSHSession
        foreach ($session in $sessions) {
            Remove-SSHSession $session.SessionID
        }
    }
    catch {
        $Errmsg = 'Could not delete ssh sessions'
        $Errmsg += $_.Exception.Message
        Write-Error $Errmsg
    }
}

function Start-InitialConnection {
    Write-Debug "Running Start-InitialConnection"
    try {
        $global:Session = New-SSHSession -ComputerName $SwitchIP -Port $port -Credential $MyCreds -AcceptKey:$true -KeepAliveInterval 240 -ConnectionTimeout 50 -Verbose -ErrorAction Stop
        Start-Sleep 4
        [int]$global:SessionID = ((Get-SSHSession).sessionid)
        Start-Sleep 2
        $global:Stream = New-SSHShellStream -SessionId $SessionID
        Start-Sleep 4
    }
    catch [System.Net.Sockets.SocketException] {
        Remove-SSHSession -SessionId $SessionID -ErrorAction stop
        Start-Sleep 2
        $Errmsg = 'The SSH Connection did not succeed. Please make sure SSH is fully enabled on the switch and the SSH credentials are correct.'
        $Errmsg += $_.Exception.Message
        Write-Error $Errmsg ; return
    }
    catch {
        Remove-SSHSession -SessionId $SessionID -ErrorAction stop
        Start-Sleep 2
        $Errmsg = 'An unspecified error occured. Verifiy the IP address to the switch is correct.'
        $Errmsg += $_.Exception.Message
        Write-Error $Errmsg ; return
    }
}

function Connect-Stream {
    Write-Debug "Running connect-stream"
    $Stream = New-SSHShellStream -SessionId $SessionID
    <#
    #TODO this error handling is wrecking things and causing multiple initial connections to run
    try {
        $global:Stream = New-SSHShellStream -SessionId $SessionID
    } catch [Microsoft.PowerShell.Commands.WriteErrorException] {
        $Errmsg = "Session does not exist for stream to be established. Reestablishing session. `n"
        $Errmsg += $_.Exception.Message
        Write-Error $Errmsg
        Start-InitialConnection
    } catch [System.Management.Automation.RuntimeException] {
        $Errmsg = "Null value. Restarting session. This needs to be changed. `n"
        $Errmsg += $_.Exception.Message
        Write-Error $Errmsg
        Start-InitialConnection
    } #>
}

function Check-UsernameTwicePrompt {
    # Belongs in at least in Cisco Small Business, Aruba, and HP
    Write-Debug "Check-usernametwiceprompt"
    try {
        $usercount = ($result -match "User" | Measure-Object).count
        if ($usercount -ge 2) {
            Write-Host "Two instances of username found in stream. Writing two usernames to stream"
            Connect-Stream
            $RunningWrites += $Stream.Write("$Username`n"), (Start-Sleep 2), $Stream.Write("$Username`n"), (Start-Sleep 2)
            $RunningWrites
            $doubleusers = $true
            
        }
        elseif ($usercount -eq 1) {
            Write-Host "One instance of username found in stream. Proceeding."
            $doubleusers = $false
            $RunningWrites += $Stream.Write("$Username`n"), (Start-Sleep 2)
            $RunningWrites
        }
    }
    catch [System.Management.Automation.MethodInvocationException] {
        $sessions = (Get-SSHSession).connected | Where-Object { $_.connected -eq 'False' }
        if ($sessions) {
            Remove-SSHSessions
            Start-InitialConnection
        }
    }
}

function Check-PasswordPrompt {
    Write-Debug "Running check-passwordprompt"
    try {
        if ($result.contains('Password')) {
            Connect-Stream
            $RunnningWrites += $stream.write("$Password`n"), (Start-Sleep 2)
            $RunningWrites
        }
        elseif (!($result.contains('Password'))) {
            Write-Host "No password found on console. Moving on to enable mode check."
        }
    }
    catch [System.Management.Automation.MethodInvocationException] {
        $Errmsg = 'Object reading has closed stream. Re-enabling stream.'
        $Errmsg += $_.Exception.Message
        Write-Error $Errmsg
        Connect-Stream
    }    
}

function Check-EnablePrompt {
    Write-Debug "Running Check-EnablePrompt"
    if ($result.contains('#')) {
        Write-Host "Enable mode already in use. Moving on."
        $RunningWrites
    }
    elseif (!($result.contains('#'))) {
        $RunningWrites += ($stream.write("enable`n")), (Start-Sleep 2), ($stream.write("$enablepw`n")), (Start-Sleep 2)
        $RunningWrites
    }
}

function Set-TerminalLength {
    Write-Debug "Running Set-TerminalLength..."
    try {
        #TODO build out error handling for unrecognized commands OR just blast every possible terminal length blindly where there is confusion?
        switch ($Manufacturer) {
            'Unifi' {
                $Stream.write("terminal length 0`n")
                Start-Sleep 2
            }
            'Fortinet' {
                $Stream.write("set output more`n")
                Start-Sleep 2
            }
            'Dell' {
                $Stream.Write("terminal length 0`n")
                Start-Sleep 2
            }
            'Cisco' {
                $Stream.Write("terminal length 0`n")
                Start-Sleep 2
            }
            'CiscoSmallBusiness' {
                $Stream.Write("terminal datadump`n")
                Start-Sleep 2
            }
            'Aruba' {
                $Stream.Write("terminal length 1000`n")
                Start-Sleep 2
            }
            'HP' {
                $Stream.Write("terminal length 1000`n")
                Start-Sleep 2
            }
        }
    }
    catch [System.Management.Automation.MethodInvocationException] {
        $Errmsg = 'Object reading has closed stream. Re-enabling stream.'
        $Errmsg += $_.Exception.Message
        Write-Error $Errmsg
        $Stream = New-SSHShellStream -SessionId $SessionID
    }
}

function Get-Config {
    Write-Debug "Running Get-Config"
    try {
        switch ($Manufacturer) {
            'Unifi' {
                Write-Debug "Running Unifi config commands"
                $Stream.Write("cat /tmp/running.cfg`n")
                Start-Sleep 10
            }
            'Fortinet' {
                Write-Debug "Running $Manufacturer config commands"
                $Stream.write("show full-configuration`n")
                Start-Sleep 15
            }
            'Dell' {
                Write-Debug "Running $Manufacturer config commands"
                $Stream.Write("show run`n")
                Start-Sleep 10
            }
            'Cisco' {
                Write-Debug "Running $Manufacturer config commands"
                $Stream.Write("show run`n")
                Start-Sleep 15
            }
            'HP' {
                Write-Debug "Running $Manufacturer config commands"
                $Stream.Write("show run`n")
                Start-Sleep 15
            }
            'CiscoSmallBusiness' {
                Write-Debug "Running $Manufacturer config commands"
                $Stream.Write("show run`n")
                Start-Sleep 15
            }
            'Aruba' {
                Write-Debug "Running $Manufacturer config commands"
                $Stream.Write("show run`n")
                Start-Sleep 15
            }
        }
        Out-File -FilePath $Outputfilepath -InputObject $Stream.Read()
        Start-Sleep 5
        Remove-SSHSessions
    }
    catch [System.Management.Automation.MethodInvocationException] {
        $Errmsg = 'Object reading has closed stream. Re-enabling stream.'
        $Errmsg += $_.Exception.Message
        Write-Error $Errmsg
        Connect-Stream
        #TODO fix this error handling, need to be more specific than just catching that error class
    }    
}

function trimlogs ($log) {
    Write-Debug "Running trimlogs"
    $string = Get-Content $log
    $startregexquery = switch ($Manufacturer) {
        'Unifi' { 'cat /tmp/running.cfg$' }
        'Cisco' { 'show run$' }
        'HP' { '\w{2}\.\w{2}\.\w{2}\.\w{2}:\d{2}$' }
        'Aruba' { '\w{2}\.\w{2}\.\w{2}\.\w{2}:\d{2}$' }
        'Dell' { 'show run$' }
        'Fortinet' { 'show full-configuration$' }
        'CiscoSmallBusiness' { 'show run$' }
    }
    $endregexquery = switch ($Manufacturer) {
        'Unifi' { '^exit$' }
        'Cisco' { '^end$' }
        'HP' { '\x1b' }
        'Aruba' { '\x1b' }
        'Dell' { '^exit$' }
        'Fortinet' { '^exit$' }
        'CiscoSmallBusiness' { '^exit$' }
    }
    $startregex = Get-Content $log | Select-String -Pattern "$startregexquery"
    $endregex = Get-Content $log | Select-String -Pattern "$endregexquery"
    Write-Debug "Trimming log"
    if ($startregex) {
        $index = $string.indexof($startregex)
        $textafterindex = $string[($index + 1)..$string.count]
        Set-Content -Path $log -Value $textafterindex -Force
        $string = Get-Content -Path $log
        if ($endregex) {
            $index = $string.indexof($endregex[-1])
            $textbeforeindex = $string[0..($index - 1)]
            Set-Content -Path $log -Value $textbeforeindex -Force
        }
    }     
}

function Set-NoLogging {

    $stream.write("conf t`n")
    $result = $stream.read()
    $stream.write("no logging console`n")
    $result = $stream.read()
    $stream.write("exit`n")
    $result = $stream.read()

}

# BODY

Start-InitialConnection
$Stream.Write("$Username`n")
$result = $stream.read()
Check-UsernameTwicePrompt
$result = $stream.read()
Check-PasswordPrompt
$result = $stream.read()
Check-EnablePrompt
Set-NoLogging
Set-TerminalLength
Get-Config
trimlogs($log)
Remove-SSHSessions

$OldHashes = Get-ChildItem $ConfigPath -Recurse | Get-FileHash -Algorithm MD5
$NewHash = Get-FileHash -Path $Log -Algorithm MD5

$files = Get-ChildItem -Path $Outputfolder -Recurse
Write-Debug "Comparing MD5 hashes from existing and previous files."
If (($OldHashes.Hash -contains $NewHash.Hash) -and ($files.count -ne 1)) {

    Write-Debug "MD5 stayed the same."
    Write-Host "No change in configuration file."
    $output = "Uploaded"
    
}
else {

    Write-Debug "MD5 does not match, generating json for upload."
    $Content = [convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes((Get-Content $log -Raw)))
    $body = @{
        type       = "flexible-assets"
        attributes = @{
            traits = @{
                'filename' = $($filename)
                'file'     = @{
                    'content'   = $Content
                    'file_name' = $($filename)
                }
            }
        }
    } | ConvertTo-Json -Depth 100 

    $request = Invoke-WebRequest -Uri $uri -Method POST -UseBasicParsing -Body $body
    if ($request.Content -eq "Creating" -or $request.Content -eq "Updating") {
        Write-Host $request.Content
        Write-Debug $request.Content
        $output = "Uploaded"
    }
    else {
        Write-Host $request.RawContent
        Write-Debug $request.RawContent
        $output = "Failed"
    }

}

$files = Get-ChildItem -Path $Outputfolder -Recurse 
Write-Debug "Checking if stored configurations exceed 3."
If ($files.Count -gt 3) {
    Write-Debug "Deleting oldest copy of config."
    $files | Sort-Object -Property $_.LastWriteTime | Select-Object -First 1 | Remove-Item -Force
}
else {
    Write-Debug "No files deleted."
}

$output
