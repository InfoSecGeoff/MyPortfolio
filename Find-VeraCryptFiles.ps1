# Set the path to search for VeraCrypt containers
$PathToSearch = "C:\"

# Set the filename pattern to match VeraCrypt container files
$FilenamePattern = "*.hc"

# Get all files in the directory with the specified filename pattern
$VeraCryptFiles = Get-ChildItem -Path $PathToSearch -Filter $FilenamePattern -Recurse

# Check if any VeraCrypt files were found
if ($VeraCryptFiles.Count -eq 0) {
    Write-Host "No VeraCrypt containers found."
} else {
    Write-Host "VeraCrypt containers found:"
    foreach ($file in $VeraCryptFiles) {
        Write-Host $file.FullName
    }
}
