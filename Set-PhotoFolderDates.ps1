param (
    [Parameter(Mandatory)]
    [string]$Directory,
    [switch]$Recurse
)

# Validate that the directory exists
if (-Not (Test-Path $Directory)) {
    Write-Host "The specified directory '$Directory' does not exist. Please check the path." -ForegroundColor Red
    exit
}

Write-Host "`nProcessing folder: $(Split-Path $Directory -Leaf)" -ForegroundColor Cyan

# Get first jpg/jpeg file in the directory
$firstPhoto = Get-ChildItem -Path $Directory -Filter "*.jp*g" -File | Select-Object -First 1

if ($firstPhoto) {
    # Get the EXIF DateTimeOriginal using ExifTool
    $dateTaken = & exiftool -d "%Y-%m-%d %H:%M:%S" -DateTimeOriginal -S -s $firstPhoto.FullName
    
    if ($dateTaken -match "\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}") {
        $date = [DateTime]::ParseExact($dateTaken, "yyyy-MM-dd HH:mm:ss", $null)

        # Update folder's creation date
        Set-ItemProperty -Path $Directory -Name CreationTime -Value $date

        Write-Host "Folder: $(Split-Path $Directory -Leaf)" -ForegroundColor Green
        Write-Host "Setting date to: $date (from $(Split-Path $firstPhoto.FullName -Leaf))" -ForegroundColor Green
        Write-Host "✔️ Successfully updated folder timestamp" -ForegroundColor Green
    } else {
        Write-Host "❌ No valid EXIF DateTimeOriginal found in $(Split-Path $firstPhoto.FullName -Leaf)" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ No JPEG files found in $(Split-Path $Directory -Leaf)" -ForegroundColor Yellow
}

# If recursive flag is set, process all subfolders
if ($Recurse) {
    Get-ChildItem -Path $Directory -Directory | ForEach-Object {
        & $PSCommandPath -Directory $_.FullName -Recurse
    }
}
