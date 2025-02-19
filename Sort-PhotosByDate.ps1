param (
    [Parameter(Mandatory=$true)]
    [string]$Directory,
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeDescription
)

# Validate directory exists
if (-Not (Test-Path $Directory)) {
    Write-Host "The specified directory '$Directory' does not exist." -ForegroundColor Red
    exit 1
}

# Get all photos and videos and group them by date
$photos = Get-ChildItem -Path $Directory -File | 
    Where-Object { ($_.Extension -match '^\.(jpg|jpeg|mp4)$') -and ($_.Name -match "^(\d{4}-\d{2}-\d{2})") } |
    Group-Object { $_.Name.Substring(0, 10) }

foreach ($dateGroup in $photos) {
    $date = $dateGroup.Name
    $files = $dateGroup.Group

    # Only process groups with multiple files
    if ($files.Count -gt 1) {
        $folderName = $date
        
        # If -IncludeDescription flag is present, prompt for description
        if ($IncludeDescription) {
            $description = Read-Host "Enter description for photos from $date (press Enter to skip)"
            if ($description) {
                $folderName = "$date - $description"
            }
        }

        $folderPath = Join-Path $Directory $folderName
        Write-Host "`nProcessing date: $date (${files.Count} photos)" -ForegroundColor Cyan

        # Create folder if it doesn't exist
        if (-Not (Test-Path $folderPath)) {
            New-Item -Path $folderPath -ItemType Directory | Out-Null
            Write-Host "Created folder: $folderName" -ForegroundColor Yellow
        }

        # Move files to the folder
        foreach ($file in $files) {
            $destPath = Join-Path $folderPath $file.Name
            try {
                Move-Item -Path $file.FullName -Destination $destPath -ErrorAction Stop
                Write-Host "✔️ Moved: $($file.Name)" -ForegroundColor Green
            }
            catch {
                Write-Host "❌ Failed to move $($file.Name): $_" -ForegroundColor Red
            }
        }
    }
}

Write-Host "`nGrouping complete!" -ForegroundColor Green
