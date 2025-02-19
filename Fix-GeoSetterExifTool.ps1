param (
    [Parameter(Mandatory=$false)]
    [string]$SourcePath = "C:\Users\$env:USERNAME\AppData\Local\Programs\ExifTool",
    
    [Parameter(Mandatory=$false)]
    [string]$DestinationPath = "C:\Users\$env:USERNAME\AppData\Roaming\GeoSetter_beta\tools",

    [Parameter(Mandatory=$false)]
    [string]$PackageName = "OliverBetz.ExifTool"
)

# Check if ExifTool is installed
$exifToolCheck = winget list --id $PackageName --accept-source-agreements
if ($LASTEXITCODE -eq 0) {
    Write-Host "ExifTool is installed. Checking for updates..." -ForegroundColor Cyan
    # Upgrade ExifTool if updates are available
    winget upgrade --id $PackageName --accept-source-agreements
} else {
    Write-Host "ExifTool not found. Installing..." -ForegroundColor Yellow
    # Install ExifTool
    winget install --id $PackageName --accept-source-agreements
}

# Check if source and destination directories exist
if ((Test-Path $SourcePath) -and (Test-Path $DestinationPath)) {
    # Copy files from source to destination
    Copy-Item -Path "$SourcePath\*" -Destination $DestinationPath -Force
    Write-Host "Files copied successfully from '$SourcePath' to '$DestinationPath'." -ForegroundColor Green
} else {
    Write-Host "Either source or destination directory does not exist. Please verify the paths:" -ForegroundColor Red
    Write-Host "Source: $SourcePath" -ForegroundColor Yellow
    Write-Host "Destination: $DestinationPath" -ForegroundColor Yellow
}