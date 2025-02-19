param (
    [Parameter(Mandatory=$true)]
    [string]$Directory = "C:\TEMP\ToProcess",
    [string]$GpxBaseDirectory = "C:\Users\$env:USERNAME\Dropbox\Maps\_Tracks\Garmin"
)

# Define the processing steps
$processingSteps = @(
    @(0, "Update-Packages.ps1", "Update packages", ""),
    @(1, "Set-PhotoExif.ps1", "Set EXIF metadata", "-Directory `"$Directory`""),
    @(2, "Set-PhotoGeoLocation.ps1", "Set location data", "-Directory `"$Directory`" -GpxBaseDirectory `"$GpxBaseDirectory`""),
    @(3, "Rename-PhotosByDate.ps1", "Rename files", "-Directory `"$Directory`""),
    @(4, "Optimize-Photos.ps1", "Optimize photos", "-Directory `"$Directory`""),
    @(5, "Set-PhotoFileDates.ps1", "Set file dates", "-Directory `"$Directory`""),
    @(6, "Sort-PhotosByDate.ps1", "Organise Photos", "-Directory `"$Directory`" -IncludeDescription"),
    @(7, "Set-PhotoFolderDates.ps1", "Set folder dates", "-Directory `"$Directory`" -Recurse")
)

# Function to run a script and handle errors
function Run-Script {
    param (
        [int]$index,
        [string]$scriptName,
        [string]$description,
        [string]$parameters
    )
    
    Write-Host "`n=====================================================" -ForegroundColor Cyan
    Write-Host "Step $index : $description" -ForegroundColor Cyan
    Write-Host "Running: $scriptName $parameters" -ForegroundColor Cyan
    Write-Host "=====================================================" -ForegroundColor Cyan
    
    $scriptPath = Join-Path $PSScriptRoot $scriptName
    if (Test-Path $scriptPath) {
        $command = "$scriptPath $parameters"
        try {
            Invoke-Expression $command
            Write-Host "✔️ Step $index complete" -ForegroundColor Green
            return $true
        } catch {
            Write-Host "❌ Error in step $index : $_" -ForegroundColor Red
            return $false
        }
    } else {
        Write-Host "❌ Script not found: $scriptPath" -ForegroundColor Red
        return $false
    }
}

# Process all steps
$failedSteps = @()

foreach ($step in $processingSteps) {
    $success = Run-Script -index $step[0] -scriptName $step[1] -description $step[2] -parameters $step[3]
    if (-not $success) {
        $failedSteps += $step[1]
    }
}

# Final status report
Write-Host "`n=====================================================" -ForegroundColor Cyan
Write-Host "Processing Complete!" -ForegroundColor Cyan
if ($failedSteps.Count -gt 0) {
    Write-Host "`nWarning: The following steps failed:" -ForegroundColor Yellow
    foreach ($fail in $failedSteps) {
        Write-Host "- $fail" -ForegroundColor Yellow
    }
}
Write-Host "=====================================================" -ForegroundColor Cyan
