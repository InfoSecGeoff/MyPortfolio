# Finds and removes all ESET and LabTechAD folders in registry. N-Central and other RMM solutions use the Uninstall folder in registry to pull installed software data which can cause a false positive for old AV that was inefficiently cleaned.

$folders = ('HKLM:\Software\ESET', 'HKLM:\Software\ESET DEM PLUGIN', 'HKLM:\Software\LabTech')

foreach ($folder in $folders) {
    try {
        Remove-Item -Path $folder -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Removed folder: $folder"
    }
    catch {
        throw "An error has occurred removing registry folder for $folder" ; return
    }
}

Remove-Item -Path 'HKLM:\Software\ESET' -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path 'HKLM:\Software\ESET DEM PLUGIN' -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path 'HKLM:\Software\LabTech' -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path 'C:\Program Files\ESET'-Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path 'C:\ProgramData\ESET' -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path 'C:\ProgramData\LabTech' -Recurse -Force -ErrorAction SilentlyContinue
