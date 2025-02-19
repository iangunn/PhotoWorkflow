param (
    [Parameter(Mandatory=$true)]
    [string]$Directory,
    
    [string]$ConfigFile = "$PSScriptRoot\PhotoExif.config.json"
)

# Validate directory exists
if (-Not (Test-Path $Directory)) {
    Write-Host "The specified directory '$Directory' does not exist." -ForegroundColor Red
    exit 1
}

# Validate config file exists
if (-Not (Test-Path $ConfigFile)) {
    Write-Host "Configuration file '$ConfigFile' not found." -ForegroundColor Red
    exit 1
}

# Read configuration
try {
    $config = Get-Content -Path $ConfigFile -Raw | ConvertFrom-Json
    Write-Host "Loaded configuration from $ConfigFile" -ForegroundColor Cyan
} catch {
    Write-Host "Error reading configuration file: $_" -ForegroundColor Red
    exit 1
}

# Build exiftool arguments
$exifArgs = @(
    "-Artist=$($config.Artist)",
    "-Copyright=$($config.Copyright)",
    "-XMP-iptcCore:CreatorWorkTelephone=$($config.Phone)",
    "-XMP-iptcCore:CreatorWorkEmail=$($config.Email)",
    "-overwrite_original"
)

# Process all JPG and JPEG files
Get-ChildItem -Path $Directory -Filter "*.jp*g" -File | ForEach-Object {
    $file = $_.FullName.Replace('/', '\')  # Ensure Windows path format
    $fileName = Split-Path $file -Leaf
    
    Write-Host "`nProcessing: $fileName" -ForegroundColor Cyan
    
    # Apply EXIF data (escape backslashes in path)
    $result = & exiftool $exifArgs ($file -replace '\\', '\\\\')
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✔️ Successfully updated EXIF data" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to update EXIF data" -ForegroundColor Red
        Write-Host $result -ForegroundColor Red
    }
}

Write-Host "`nProcessing complete!" -ForegroundColor Green
