param (
    [Parameter(Mandatory=$true)]
    [string]$Directory,
    
    [Parameter(Mandatory=$true)]
    [string]$GpxBaseDirectory
)

# Validate directories exist
if (-Not (Test-Path $Directory)) {
    Write-Host "Photos directory '$Directory' does not exist." -ForegroundColor Red
    exit 1
}
if (-Not (Test-Path $GpxBaseDirectory)) {
    Write-Host "GPX base directory '$GpxBaseDirectory' does not exist." -ForegroundColor Red
    exit 1
}

# Process all JPG and JPEG files
Get-ChildItem -Path $Directory -Filter "*.jp*g" -File | ForEach-Object {
    $photoFile = $_.FullName
    Write-Host "`nProcessing photo: $(Split-Path $photoFile -Leaf)" -ForegroundColor Cyan

    # Get photo date using ExifTool
    $dateTaken = & exiftool -d "%Y-%m-%d" -DateTimeOriginal -S -s "$photoFile"
    
    if ($dateTaken -match "\d{4}-\d{2}-\d{2}") {
        $year = $dateTaken.Substring(0, 4)
        $gpxFolder = Join-Path $GpxBaseDirectory $year

        function Get-GpxDates {
            param (
                [string]$GpxFile
            )
            
            try {
                [xml]$gpxContent = Get-Content $GpxFile
                $timestamps = $gpxContent.gpx.trk.trkseg.trkpt.time
                if ($timestamps) {
                    $dates = $timestamps | ForEach-Object { 
                        ([datetime]$_).ToString('yyyy-MM-dd')
                    } | Select-Object -Unique
                    return $dates
                }
            } catch {
                Write-Host "⚠️ Error reading GPX file: $GpxFile" -ForegroundColor Yellow
            }
            return @()
        }

        if (Test-Path $gpxFolder) {
            # Get all GPX files and check their content for matching dates
            $matchingGpxFiles = Get-ChildItem -Path $gpxFolder -Filter "*.gpx" | Where-Object {
                $gpxDates = Get-GpxDates $_.FullName
                $gpxDates -contains $dateTaken
            }

            if ($matchingGpxFiles.Count -gt 0) {
                # Create a list of -geotag arguments for exiftool
                $geotagArgs = $matchingGpxFiles | ForEach-Object { "-geotag `"$($_.FullName)`"" }
                
                # Geotag the photo using all matching GPX files
                $exifCommand = "exiftool -overwrite_original $($geotagArgs -join ' ') `"$photoFile`""
                Invoke-Expression $exifCommand
                
                Write-Host "✔️ Geotagged using $(($matchingGpxFiles | Select-Object -ExpandProperty Name) -join ', ')" -ForegroundColor Green
            } else {
                Write-Host "⚠️ No GPX files found containing tracks for date: $dateTaken" -ForegroundColor Yellow
            }
        } else {
            Write-Host "⚠️ No GPX folder found for year: $year" -ForegroundColor Yellow
        }
    } else {
        Write-Host "❌ No valid date found in photo" -ForegroundColor Red
    }
}

Write-Host "`nProcessing complete!" -ForegroundColor Green
