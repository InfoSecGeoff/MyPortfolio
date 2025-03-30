<#
.SYNOPSIS
    Checks WAV files for 16-bit 44.1kHz format and converts non-compliant files for import into the Roland SP-404 sampler.

.DESCRIPTION
    This PowerShell script scans a specified folder for WAV audio files and analyzes each file to determine
    if it meets the standard 16-bit 44.1kHz format required by the original SP-404. Files that don't meet this specification are converted
    using FFmpeg. The script provides options for recursive folder scanning, backing up original files, and
    customizing the output location. FFmpeg must be installed and available in your PATH for this script to function.

.PARAMETER FolderPath
    Required. The path to the folder containing WAV files to check and potentially convert.

.PARAMETER Recursive
    Optional. When specified, the script will scan subfolders recursively for WAV files.

.PARAMETER OutputFolder
    Optional. The path to store converted files. If not specified, a "Converted" subfolder will be created
    in the source folder.

.PARAMETER BackupOriginals
    Optional. When specified, creates a backup copy of files before converting them.

.PARAMETER BackupFolder
    Optional. The path to store backup files. If not specified but BackupOriginals is enabled,
    a "Backup" subfolder will be created in the source folder.

.EXAMPLE
    .\SP404SampleConverter.ps1 -FolderPath "C:\Music\Samples"
    Scans the specified folder for WAV files and converts any non-compliant files to 16-bit 44.1kHz format.

.EXAMPLE
    .\SP404SampleConverter.ps1 -FolderPath "C:\Music\Samples" -Recursive
    Recursively scans the specified folder and all subfolders for WAV files and converts any non-compliant files.

.EXAMPLE
    .\SP404SampleConverter.ps1 -FolderPath "C:\Music\Samples" -OutputFolder "D:\Converted" -BackupOriginals
    Scans for WAV files, creates backups of non-compliant files before converting them, and stores converted
    files in the specified output folder.
#>

param(
    [Parameter(Mandatory=$true, HelpMessage="Path to the folder containing WAV files")]
    [string]$FolderPath,
    
    [Parameter(Mandatory=$false, HelpMessage="Scan subfolders recursively")]
    [switch]$Recursive,
    
    [Parameter(Mandatory=$false, HelpMessage="Path to store converted files")]
    [string]$OutputFolder = "",
    
    [Parameter(Mandatory=$false, HelpMessage="Create backup of original files before conversion")]
    [switch]$BackupOriginals,
    
    [Parameter(Mandatory=$false, HelpMessage="Path to store backup files")]
    [string]$BackupFolder = ""
)

function Get-WavProperties {
    param([string]$FilePath)
    
    try {
        $bytes = [System.IO.File]::ReadAllBytes($FilePath)
        
        # Check for valid WAV format
        $riffHeader = [System.Text.Encoding]::ASCII.GetString($bytes[0..3])
        if ($riffHeader -ne "RIFF") {
            Write-Error "$FilePath is not a valid WAV file (missing RIFF header)"
            return $null
        }
        
        $waveHeader = [System.Text.Encoding]::ASCII.GetString($bytes[8..11])
        if ($waveHeader -ne "WAVE") {
            Write-Error "$FilePath is not a valid WAV file (missing WAVE format)"
            return $null
        }
        
        # Find 'fmt ' chunk
        $fmtOffset = -1
        for ($i = 12; $i -lt $bytes.Length - 4; $i++) {
            if ([System.Text.Encoding]::ASCII.GetString($bytes[$i..($i+3)]) -eq "fmt ") {
                $fmtOffset = $i
                break
            }
        }
        
        if ($fmtOffset -eq -1) {
            Write-Error "$FilePath is missing the 'fmt ' chunk"
            return $null
        }
        
        # Skip the chunk ID (4 bytes) and chunk size (4 bytes)
        $fmtOffset += 8
        
        # Audio format (2 bytes)
        $audioFormat = [System.BitConverter]::ToUInt16($bytes[$fmtOffset..($fmtOffset+1)], 0)
        
        # Number of channels (2 bytes)
        $numChannels = [System.BitConverter]::ToUInt16($bytes[($fmtOffset+2)..($fmtOffset+3)], 0)
        
        # Sample rate (4 bytes)
        $sampleRate = [System.BitConverter]::ToUInt32($bytes[($fmtOffset+4)..($fmtOffset+7)], 0)
        
        # Byte rate (4 bytes)
        $byteRate = [System.BitConverter]::ToUInt32($bytes[($fmtOffset+8)..($fmtOffset+11)], 0)
        
        # Block align (2 bytes)
        $blockAlign = [System.BitConverter]::ToUInt16($bytes[($fmtOffset+12)..($fmtOffset+13)], 0)
        
        # Bits per sample (2 bytes)
        $bitsPerSample = [System.BitConverter]::ToUInt16($bytes[($fmtOffset+14)..($fmtOffset+15)], 0)
        
        return @{
            AudioFormat = $audioFormat
            NumChannels = $numChannels
            SampleRate = $sampleRate
            ByteRate = $byteRate
            BlockAlign = $blockAlign
            BitsPerSample = $bitsPerSample
            FilePath = $FilePath
        }
    }
    catch {
        Write-Error "Error processing $FilePath : $_"
        return $null
    }
}

function BackupFile {
    param(
        [string]$SourceFile,
        [string]$BackupPath
    )
    
    try {
        $destFile = Join-Path $BackupPath (Split-Path $SourceFile -Leaf)
        Write-Host "Creating backup: $destFile" -ForegroundColor Blue
        Copy-Item -Path $SourceFile -Destination $destFile -Force
        
        if (Test-Path $destFile) {
            return $true
        } else {
            Write-Error "Failed to create backup of file: $SourceFile"
            return $false
        }
    }
    catch {
        Write-Error "Error during backup of $SourceFile : $_"
        return $false
    }
}

function ConvertWavFile {
    param(
        [string]$InputFile,
        [string]$OutputFile
    )
    
    try {
        $ffmpegCmd = "ffmpeg -y -i `"$InputFile`" -acodec pcm_s16le -ar 44100 `"$OutputFile`""
        
        Write-Host "Converting $InputFile to 16-bit 44.1kHz..." -ForegroundColor Yellow
        $result = Invoke-Expression $ffmpegCmd 2>&1
        
        if (Test-Path $OutputFile) {
            Write-Host "Successfully converted: $OutputFile" -ForegroundColor Green
            return $true
        } else {
            Write-Error "Failed to convert file: $InputFile"
            Write-Error $result
            return $false
        }
    }
    catch {
        Write-Error "Error during conversion of $InputFile : $_"
        return $false
    }
}

try {
    $ffmpegVersion = Invoke-Expression "ffmpeg -version" 2>&1
    if ($ffmpegVersion -match "ffmpeg version") {
        Write-Host "FFmpeg detected: $($ffmpegVersion -split '\n' | Select-Object -First 1)" -ForegroundColor Green
    } else {
        Write-Error "FFmpeg not found. Please install FFmpeg and make sure it's available in your PATH."
        exit 1
    }
}
catch {
    Write-Error "FFmpeg not found. Please install FFmpeg and make sure it's available in your PATH."
    exit 1
}

if (-not (Test-Path -Path $FolderPath -PathType Container)) {
    Write-Error "The specified folder does not exist: $FolderPath"
    exit 1
}

if ($OutputFolder -eq "") {
    $OutputFolder = Join-Path $FolderPath "Converted"
}

if (-not (Test-Path -Path $OutputFolder -PathType Container)) {
    Write-Host "Creating output folder: $OutputFolder" -ForegroundColor Yellow
    New-Item -Path $OutputFolder -ItemType Directory | Out-Null
}

if ($BackupOriginals) {
    if ($BackupFolder -eq "") {
        $BackupFolder = Join-Path $FolderPath "Backup"
    }
    
    if (-not (Test-Path -Path $BackupFolder -PathType Container)) {
        Write-Host "Creating backup folder: $BackupFolder" -ForegroundColor Yellow
        New-Item -Path $BackupFolder -ItemType Directory | Out-Null
    }
}

if ($Recursive) {
    $wavFiles = Get-ChildItem -Path $FolderPath -Filter "*.wav" -Recurse
} else {
    $wavFiles = Get-ChildItem -Path $FolderPath -Filter "*.wav"
}

Write-Host "Found $($wavFiles.Count) WAV files to analyze" -ForegroundColor Cyan

$filesToConvert = @()
$compliantFiles = @()

foreach ($file in $wavFiles) {
    Write-Host "Analyzing $($file.FullName)..." -ForegroundColor Cyan
    $properties = Get-WavProperties -FilePath $file.FullName
    
    if ($properties -ne $null) {
        $summary = "$($file.Name) - $($properties.BitsPerSample)-bit, $($properties.SampleRate)Hz, $($properties.NumChannels) channels"
        
        if ($properties.BitsPerSample -eq 16 -and $properties.SampleRate -eq 44100) {
            Write-Host "✓ $summary (compliant)" -ForegroundColor Green
            $compliantFiles += $file
        } else {
            Write-Host "✗ $summary (needs conversion)" -ForegroundColor Yellow
            $filesToConvert += $file
        }
    }
}

Write-Host "`nSummary:" -ForegroundColor Cyan
Write-Host "- Compliant files: $($compliantFiles.Count)" -ForegroundColor Green
Write-Host "- Files needing conversion: $($filesToConvert.Count)" -ForegroundColor Yellow

if ($filesToConvert.Count -gt 0) {
    Write-Host "`nStarting conversion process..." -ForegroundColor Cyan
    
    $convertedCount = 0
    $failedCount = 0
    $backupCount = 0
    $backupFailedCount = 0
    
    foreach ($file in $filesToConvert) {
        if ($Recursive) {
            $relativePath = $file.FullName.Substring($FolderPath.Length)
            $relativePath = $relativePath.TrimStart('\', '/')
            
            $destinationFolder = Split-Path -Path (Join-Path $OutputFolder $relativePath) -Parent
            if (-not (Test-Path -Path $destinationFolder -PathType Container)) {
                New-Item -Path $destinationFolder -ItemType Directory -Force | Out-Null
            }
            
            if ($BackupOriginals) {
                $backupDestFolder = Split-Path -Path (Join-Path $BackupFolder $relativePath) -Parent
                if (-not (Test-Path -Path $backupDestFolder -PathType Container)) {
                    New-Item -Path $backupDestFolder -ItemType Directory -Force | Out-Null
                }
                $backupFile = Join-Path $BackupFolder $relativePath
            }
            
            $outputFile = Join-Path $OutputFolder $relativePath
        } else {
            $outputFile = Join-Path $OutputFolder $file.Name
            
            if ($BackupOriginals) {
                $backupFile = Join-Path $BackupFolder $file.Name
            }
        }
        
        # Backup original files before conversion
        $backupSuccess = $true
        if ($BackupOriginals) {
            $backupSuccess = BackupFile -SourceFile $file.FullName -BackupPath (Split-Path $backupFile -Parent)
            if ($backupSuccess) {
                $backupCount++
            } else {
                $backupFailedCount++
                Write-Warning "Skipping conversion of $($file.Name) due to backup failure."
                continue
            }
        }
        
        $result = ConvertWavFile -InputFile $file.FullName -OutputFile $outputFile
        
        if ($result) {
            $convertedCount++
        } else {
            $failedCount++
        }
    }
    
    Write-Host "`nConversion complete:" -ForegroundColor Cyan
    Write-Host "- Successfully converted: $convertedCount" -ForegroundColor Green
    Write-Host "- Failed conversions: $failedCount" -ForegroundColor Red
    
    if ($BackupOriginals) {
        Write-Host "`nBackup results:" -ForegroundColor Cyan
        Write-Host "- Successfully backed up: $backupCount" -ForegroundColor Green
        Write-Host "- Failed backups: $backupFailedCount" -ForegroundColor Red
        Write-Host "- Backup location: $BackupFolder" -ForegroundColor Cyan
    }
    
    Write-Host "`nOutput location: $OutputFolder" -ForegroundColor Cyan
} else {
    Write-Host "`nAll files are already 16-bit 44.1kHz. No conversion needed." -ForegroundColor Green
}
