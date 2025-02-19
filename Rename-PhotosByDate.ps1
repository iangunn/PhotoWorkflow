param (
    [Parameter(Mandatory=$true)]
    [string]$Directory
)

# Validate directory exists
if (-Not (Test-Path $Directory)) {
    Write-Host "The specified directory '$Directory' does not exist." -ForegroundColor Red
    exit 1
}

# Process all JPG and JPEG files
Get-ChildItem -Path $Directory -Filter "*.jp*g" -File | ForEach-Object {
    $file = $_.FullName
    $fileName = Split-Path $file -Leaf
    
    Write-Host "`nProcessing: $fileName" -ForegroundColor Cyan
    
    # Get photo date using ExifTool
    $dateTaken = & exiftool -d "%Y-%m-%d %H.%M.%S" -DateTimeOriginal -S -s "$file"
    
    if ($dateTaken -match "\d{4}-\d{2}-\d{2} \d{2}\.\d{2}\.\d{2}") {
        $extension = $_.Extension.ToLower()
        $newBaseName = $dateTaken
        $newName = "$newBaseName$extension"
        
        # Skip if the file already has the correct name
        if ($fileName -eq $newName) {
            Write-Host "✔️ File already has correct name: $fileName" -ForegroundColor Green
        }
        else {
            $counter = 1

            # Check for naming conflicts and append number if needed
            while (Test-Path (Join-Path $Directory $newName)) {
                $newName = "$newBaseName-$counter$extension"
                $counter++
            }
            
            # Rename the file
            $newPath = Join-Path $Directory $newName
            try {
                Rename-Item -Path $file -NewName $newName -ErrorAction Stop
                Write-Host "✔️ Renamed to: $newName" -ForegroundColor Green
            } catch {
                Write-Host "❌ Failed to rename: $_" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "❌ No valid date found in: $fileName" -ForegroundColor Red
    }
}

Write-Host "`nRenaming complete!" -ForegroundColor Green
