param (
    [Parameter(Mandatory=$true)]
    [string]$Directory,
    
    [Parameter(Mandatory=$true)]
    [string]$GpxBaseDirectory,

    # The demo account has a global daily limit shared by all users
    # Sign up for your own account at https://www.geonames.org/login
    [Parameter(Mandatory=$false)]
    [string]$GeoNamesUsername = "demo"
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

# Cache for alpha-2 -> alpha-3 country code lookups to avoid redundant API calls
$countryCodeCache = @{}

function Get-GpxDates {
    param ([string]$GpxFile)
    try {
        [xml]$gpxContent = Get-Content $GpxFile
        $timestamps = $gpxContent.gpx.trk.trkseg.trkpt.time
        if ($timestamps) {
            return $timestamps | ForEach-Object { ([datetime]$_).ToString('yyyy-MM-dd') } | Select-Object -Unique
        }
    } catch {
        Write-Host "⚠️ Error reading GPX file: $GpxFile" -ForegroundColor Yellow
    }
    return @()
}

# Process all JPG and JPEG files
Get-ChildItem -Path $Directory -Filter "*.jp*g" -File | ForEach-Object {
    $photoFile = $_.FullName
    Write-Host "`nProcessing photo: $(Split-Path $photoFile -Leaf)" -ForegroundColor Cyan

    $dateTaken = & exiftool -d "%Y-%m-%d" -DateTimeOriginal -S -s "$photoFile"
    
    if ($dateTaken -match "\d{4}-\d{2}-\d{2}") {
        $year = $dateTaken.Substring(0, 4)
        $gpxFolder = Join-Path $GpxBaseDirectory $year

        if (Test-Path $gpxFolder) {
            $matchingGpxFiles = Get-ChildItem -Path $gpxFolder -Filter "*.gpx" | Where-Object {
                (Get-GpxDates $_.FullName) -contains $dateTaken
            }

            if ($matchingGpxFiles.Count -gt 0) {
                $geotagArgs = $matchingGpxFiles | ForEach-Object { "-geotag `"$($_.FullName)`"" }
                $exifCommand = "exiftool -overwrite_original $($geotagArgs -join ' ') `"$photoFile`""
                Invoke-Expression $exifCommand
                Write-Host "✔️ Geotagged using $(($matchingGpxFiles | Select-Object -ExpandProperty Name) -join ', ')" -ForegroundColor Green
            }

            $gpsLatitude  = & exiftool -GPSLatitude  -n -s -s -s "$photoFile"
            $gpsLongitude = & exiftool -GPSLongitude -n -s -s -s "$photoFile"

            if ($gpsLatitude -and $gpsLongitude) {
                try {
                    # --- Timezone ---
                    $tzUrl = "http://api.geonames.org/timezoneJSON?lat=$gpsLatitude&lng=$gpsLongitude&username=$GeoNamesUsername"
                    $tzResponse = Invoke-RestMethod -Uri $tzUrl -Method Get

                    if ($tzResponse.status) {
                        Write-Host "❌ GeoNames TZ API Error: $($tzResponse.status.message) (Code: $($tzResponse.status.value))" -ForegroundColor Red
                        throw "GeoNames API Error: $($tzResponse.status.message)"
                    }

                    if ($tzResponse.timezoneId) {
                        # ExifTool OffsetTime* tags require a UTC offset string (+HH:MM / -HH:MM), not an IANA ID.
                        # GeoNames returns gmtOffset (standard) and dstOffset (DST). Use rawOffset which reflects
                        # the actual offset at query time (i.e. accounts for DST). Fall back to gmtOffset if absent.
                        $rawOffset = if ($null -ne $tzResponse.rawOffset) { $tzResponse.rawOffset } else { $tzResponse.gmtOffset }
                        $offsetHours   = [Math]::Truncate($rawOffset)
                        $offsetMinutes = [Math]::Abs(($rawOffset - $offsetHours) * 60)
                        $sign          = if ($rawOffset -ge 0) { "+" } else { "-" }
                        $offsetString  = "$sign$([Math]::Abs($offsetHours).ToString().PadLeft(2,'0')):$($offsetMinutes.ToString().PadLeft(2,'0'))"

                        # Set all three offset tags so DateTimeOriginal, CreateDate, and ModifyDate all get the TZ
                        & exiftool -overwrite_original `
                            "-OffsetTimeOriginal=$offsetString" `
                            "-OffsetTimeDigitized=$offsetString" `
                            "-OffsetTime=$offsetString" `
                            "$photoFile"

                        Write-Host "✔️ Added timezone: $($tzResponse.timezoneId) → $offsetString" -ForegroundColor Green
                    }

                    # --- Location ---
                    $geoUrl = "http://api.geonames.org/extendedFindNearbyJSON?lat=$gpsLatitude&lng=$gpsLongitude&username=$GeoNamesUsername"
                    $geoResponse = Invoke-RestMethod -Uri $geoUrl -Method Get

                    if ($geoResponse.status) {
                        Write-Host "❌ GeoNames Geo API Error: $($geoResponse.status.message) (Code: $($geoResponse.status.value))" -ForegroundColor Red
                        throw "GeoNames API Error: $($geoResponse.status.message)"
                    }

                    if ($geoResponse.geonames) {
                        $country = $geoResponse.geonames | Where-Object { $_.fcode -eq 'PCLI' }  | Select-Object -First 1
                        $admin1  = $geoResponse.geonames | Where-Object { $_.fcode -eq 'ADM1' }  | Select-Object -First 1
                        $city    = $geoResponse.geonames | Where-Object { $_.fcode -match '^PPL' } | Select-Object -First 1

                        # Sublocation: try progressively finer admin levels
                        $subloc  = $geoResponse.geonames | Where-Object { $_.fcode -eq 'PPLX' }  | Select-Object -First 1
                        if (-not $subloc) {
                            $subloc = $geoResponse.geonames | Where-Object { $_.fcode -eq 'PPLA3' -or $_.fcode -eq 'PPLA4' } | Select-Object -First 1
                        }
                        if (-not $subloc) {
                            $subloc = $geoResponse.geonames | Where-Object { $_.fcode -eq 'ADM3' -or $_.fcode -eq 'ADM4' } | Select-Object -First 1
                        }

                        # Build exiftool args — use explicit IPTC and XMP tag names for reliable writing
                        $exifArgs = @("-overwrite_original")

                        if ($country) {
                            # Fetch ISO 3166-1 alpha-3 code — IPTC:Country-PrimaryLocationCode requires 3 chars
                            # GeoNames extendedFindNearby only returns alpha-2; countryInfoJSON returns isoAlpha3
                            $alpha3 = $country.countryCode  # fallback
                            if ($countryCodeCache.ContainsKey($country.countryCode)) {
                                $alpha3 = $countryCodeCache[$country.countryCode]
                            } else {
                                try {
                                    $ciUrl = "http://api.geonames.org/countryInfoJSON?country=$($country.countryCode)&username=$GeoNamesUsername"
                                    $ciResponse = Invoke-RestMethod -Uri $ciUrl -Method Get
                                    if ($ciResponse.geonames -and $ciResponse.geonames[0].isoAlpha3) {
                                        $alpha3 = $ciResponse.geonames[0].isoAlpha3
                                        $countryCodeCache[$country.countryCode] = $alpha3
                                    }
                                } catch {
                                    Write-Host "⚠️ Could not fetch alpha-3 country code, falling back to alpha-2" -ForegroundColor Yellow
                                }
                            }

                            $exifArgs += "-IPTC:Country-PrimaryLocationCode=$alpha3"
                            $exifArgs += "-IPTC:Country-PrimaryLocationName=$($country.name)"
                            $exifArgs += "-XMP-photoshop:Country=$($country.name)"
                            $exifArgs += "-XMP-iptcCore:CountryCode=$alpha3"
                        }
                        if ($admin1) {
                            $exifArgs += "-IPTC:Province-State=$($admin1.name)"
                            $exifArgs += "-XMP-photoshop:State=$($admin1.name)"
                        }
                        if ($city) {
                            $exifArgs += "-IPTC:City=$($city.name)"
                            $exifArgs += "-XMP-photoshop:City=$($city.name)"
                        }
                        if ($subloc) {
                            # IPTC:Sub-location is the correct tag name (hyphenated)
                            $exifArgs += "-IPTC:Sub-location=$($subloc.name)"
                            $exifArgs += "-XMP-iptcCore:Location=$($subloc.name)"
                        }

                        $exifArgs += $photoFile
                        & exiftool @exifArgs

                        $locParts = @(
                            if ($subloc)  { "sublocation=$($subloc.name)" }
                            if ($city)    { "city=$($city.name)" }
                            if ($admin1)  { "state=$($admin1.name)" }
                            if ($country) { "country=$($country.name) [$($country.countryCode)]" }
                        )

                        if ($LASTEXITCODE -ne 0) {
                            Write-Host "❌ Failed to write location tags for $(Split-Path $photoFile -Leaf)" -ForegroundColor Red
                        } else {
                            Write-Host "✔️ Added location: $($locParts -join ', ')" -ForegroundColor Green
                        }
                    }

                } catch {
                    Write-Host "⚠️ Failed to get location/timezone information: $_" -ForegroundColor Yellow
                }
            } else {
                Write-Host "⚠️ No GPS coordinates found in photo" -ForegroundColor Yellow
            }
        } else {
            Write-Host "⚠️ No GPX folder found for year: $year" -ForegroundColor Yellow
        }
    } else {
        Write-Host "❌ No valid date found in photo" -ForegroundColor Red
    }
}

Write-Host "`nProcessing complete!" -ForegroundColor Green