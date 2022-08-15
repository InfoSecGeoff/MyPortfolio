#Requires -Version 5
#Requires -PSEdition Desktop

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $speak
)

Add-Type -AssemblyName System.Speech
$talk = New-Object system.speech.synthesis.speechsynthesizer
$talk.speak($speak)
