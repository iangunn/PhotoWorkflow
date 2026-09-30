param(
    [Parameter(Mandatory=$true)]
    [string]$InputFile,
    
    [Parameter(Mandatory=$false)]
    [int]$TrimStart = 0,
    
    [Parameter(Mandatory=$false)]
    [int]$TrimEnd = 0
)

# Verify file exists
if (-not (Test-Path $InputFile)) {
    Write-Error "❌ Input file does not exist: $InputFile"
    exit 1
}

# Get the base filename without extension
$baseFileName = [System.IO.Path]::GetFileNameWithoutExtension($InputFile)
$extension = [System.IO.Path]::GetExtension($InputFile)
$directory = [System.IO.Path]::GetDirectoryName($InputFile)

# Try to parse the filename as datetime
try {
    $dateTime = [DateTime]::ParseExact($baseFileName, "yyyy-MM-dd HH.mm.ss", [System.Globalization.CultureInfo]::InvariantCulture)
} catch {
    Write-Error "❌ Filename must be in format 'yyyy-MM-dd HH.mm.ss'"
    exit 1
}

# Calculate new filename if trimming from start
if ($TrimStart -gt 0) {
    $newDateTime = $dateTime.AddSeconds($TrimStart) 
    $newFileName = $newDateTime.ToString("yyyy-MM-dd HH.mm.ss")
} else {
    $newFileName = $baseFileName
}

# Build the output path
$outputFile = Join-Path $directory "$newFileName$extension"

# Build ffmpeg command
$ffmpegArgs = @()

if ($TrimStart -gt 0) {
    # Put -ss before input for faster seeking
    $ffmpegArgs += "-ss", $TrimStart
}

$ffmpegArgs += "-i", "`"$InputFile`""

if ($TrimEnd -gt 0) {
    # Get video duration using ffprobe
    $duration = ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$InputFile"
    $newDuration = [math]::Round([double]$duration - $TrimEnd - $TrimStart, 2)
    $ffmpegArgs += "-t", $newDuration
}

# Add avoid_negative_ts to prevent timestamp issues
$ffmpegArgs += "-avoid_negative_ts", "1", "-c", "copy", "`"$outputFile`""

# Build and execute ffmpeg command
$ffmpegCommand = "ffmpeg " + ($ffmpegArgs -join " ")
Write-Host "🎬 Executing: $ffmpegCommand"
Invoke-Expression $ffmpegCommand

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Video trimmed successfully: $outputFile"
    
    # Set file timestamps to match filename datetime
    $fileTime = $newDateTime.ToUniversalTime()
    (Get-Item $outputFile).CreationTimeUtc = $fileTime
    (Get-Item $outputFile).LastWriteTimeUtc = $fileTime
    (Get-Item $outputFile).LastAccessTimeUtc = $fileTime
    
} else {
    Write-Error "❌ Failed to trim video"
    exit 1
}
