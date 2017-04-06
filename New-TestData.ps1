param(
    [Parameter(Mandatory = $true)]
    [string]
    $Path
)

function New-RandomNumberOfFilesInDir {
        for ($i = 1; $i -le (Get-Random -Minimum 10 -Maximum 20); $i++) {
                fsutil.exe file createnew ("File$($i).txt") (Get-Random -Minimum 1024 -Maximum 819200)
            }
}

function New-TestData {
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Path
    )
    Push-Location
    1..10 | ForEach-Object {
        $dirName = [guid]::NewGuid().ToString("N")
        Set-Location -Path (New-Item -ItemType directory -Path "$Path\$dirName").FullName -ErrorAction SilentlyContinue
        Push-Location
        for ($h = 1; $h -le (Get-Random -Minimum 0 -Maximum 6); $h++) {
            Set-Location -Path (New-Item -ItemType Directory -Path "$Path\$dirName\$([guid]::NewGuid().ToString('N'))").FullName
            Push-Location
            New-RandomNumberOfFilesInDir
            Pop-Location
        }
        Pop-Location
        New-RandomNumberOfFilesInDir
        Pop-Location
    }
    Pop-Location
}

New-TestData -Path $Path