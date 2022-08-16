$path = 'C:\Program Files (x86)\DeskDirector Portal'
if (Test-Path -Path $path) {
    Remove-Item -Path $path -Recurse -Force
    $users = Get-ChildItem -Path "C:\Users"
    $users | ForEach-Object {
        Remove-Item -Path "C:\Users\$($_.Name)\AppData\Local\deskdirectorportal" -Recurse -Force
        Remove-Item -Path "C:\Users\$($_.Name)\AppData\roaming\DeskDirector Portal" -Recurse -Force
    }
    else {
        throw "DeskDirector folder not found" ; return
    }
}
