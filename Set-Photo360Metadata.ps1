param (
    [Parameter(Mandatory=$true)]
    [string]$PhotoPath,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

# Validate photo exists
if (-Not (Test-Path $PhotoPath)) {
    Write-Host "❌ The specified photo '$PhotoPath' does not exist." -ForegroundColor Red
    exit 1
}

Write-Host "Converting $(Split-Path $PhotoPath -Leaf) to 360° panorama..." -ForegroundColor Cyan

# Get image dimensions using ExifTool
$width = & exiftool -b -ImageWidth "$PhotoPath"
$height = & exiftool -b -ImageHeight "$PhotoPath"

if (-not ($width -and $height)) {
    Write-Host "❌ Failed to get image dimensions" -ForegroundColor Red
    exit 1
}

# Build exiftool arguments for 360° metadata
$exifArgs = @(
    "-ProjectionType=equirectangular",
    "-UsePanoramaViewer=True",
    "-Make=DJI",
    "-Model=FC1102",
    "-CroppedAreaImageWidthPixels=$width",
    "-CroppedAreaImageHeightPixels=$height",
    "-FullPanoWidthPixels=$width",
    "-FullPanoHeightPixels=$height",
    "-CroppedAreaLeftPixels=0",
    "-CroppedAreaTopPixels=0"
)

if ($Force) {
    $exifArgs += "-overwrite_original"
}

# Apply 360° metadata
Write-Host "Setting 360° metadata..." -ForegroundColor Cyan
Write-Host "Image dimensions: ${width}x${height}" -ForegroundColor Yellow

try {
    $result = & exiftool $exifArgs "$PhotoPath"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✔️ Successfully converted to 360° panorama" -ForegroundColor Green
        Write-Host "Original file saved as: $(Split-Path $PhotoPath -Leaf)_original" -ForegroundColor Yellow
    } else {
        Write-Host "❌ Failed to set 360° metadata" -ForegroundColor Red
        Write-Host $result -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
}
