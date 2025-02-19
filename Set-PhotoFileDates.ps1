param (
    [string]$Directory
)

# Validate that the directory exists
if (-Not (Test-Path $Directory)) {
    Write-Host "The specified directory '$Directory' does not exist. Please check the path." -ForegroundColor Red
    exit
}

# Process all JPG and JPEG files in the directory
Get-ChildItem -Path $Directory -Filter "*.jp*g" -File | ForEach-Object {
    $file = $_.FullName
    Write-Host "`nProcessing file: $(Split-Path $file -Leaf)" -ForegroundColor Cyan

    # Get the EXIF DateTimeOriginal using ExifTool (output in correct format directly)
    $dateTaken = & exiftool -d "%Y-%m-%d %H:%M:%S" -DateTimeOriginal -S -s "$file"
    
    if ($dateTaken -match "\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}") {
        $date = [DateTime]::ParseExact($dateTaken, "yyyy-MM-dd HH:mm:ss", $null)

        # Update file's Created, Accessed, and Modified dates
        Set-ItemProperty -Path $file -Name CreationTime -Value $date
        Set-ItemProperty -Path $file -Name LastAccessTime -Value $date
        Set-ItemProperty -Path $file -Name LastWriteTime -Value $date

        Write-Host "File: $(Split-Path $file -Leaf)" -ForegroundColor Green
        Write-Host "Setting dates to: $date" -ForegroundColor Green
        Write-Host "✔️ Successfully updated timestamps" -ForegroundColor Green
    } else {
        Write-Host "File: $(Split-Path $file -Leaf)" -ForegroundColor Yellow
        Write-Host "❌ No valid EXIF DateTimeOriginal found" -ForegroundColor Yellow
    }
}