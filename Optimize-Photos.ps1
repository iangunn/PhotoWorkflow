param (
    [Parameter(Mandatory=$true)]
    [string]$Directory,
    
    [string]$FileOptimizerPath = "C:\Program Files\FileOptimizer\FileOptimizer64.exe"
)

# Validate FileOptimizer exists
if (-Not (Test-Path $FileOptimizerPath)) {
    Write-Host "❌ FileOptimizer not found at: $FileOptimizerPath" -ForegroundColor Red
    exit 1
}

# Validate directory exists
if (-Not (Test-Path $Directory)) {
    Write-Host "❌ Directory does not exist: $Directory" -ForegroundColor Red
    exit 1
}

# Get initial sizes for comparison
$beforeSizes = @{}
$files = Get-ChildItem -Path "$Directory\*" -Include *.jpg, *.jpeg -File
$files | ForEach-Object {
    $beforeSizes[$_.FullName] = $_.Length
}

$totalFiles = $beforeSizes.Count
if ($totalFiles -eq 0) {
    Write-Host "No JPEG files found in directory" -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $totalFiles files to process..." -ForegroundColor Cyan

# Build arguments list - each file as a separate quoted argument
$arguments = $beforeSizes.Keys | ForEach-Object { "`"$_`"" }

# Process all files at once
Write-Host "`nStarting FileOptimizer..." -ForegroundColor Cyan
Start-Process -FilePath $FileOptimizerPath -ArgumentList $arguments -Wait -WindowStyle Minimized

# Calculate results for each file
Write-Host "`nCalculating results..." -ForegroundColor Cyan
$totalSaved = 0

$beforeSizes.Keys | ForEach-Object {
    $file = $_
    $fileName = Split-Path $file -Leaf
    
    # Calculate savings
    $newSize = (Get-Item $file).Length
    $oldSize = $beforeSizes[$file]
    $savings = $oldSize - $newSize
    $savingsPercent = [math]::Round(($savings / $oldSize) * 100, 2)
    $totalSaved += $savings
    
    if ($savings -gt 0) {
        Write-Host "✔️ Optimized: $fileName" -ForegroundColor Green
        Write-Host "   Reduced from $([math]::Round($oldSize/1KB,2))KB to $([math]::Round($newSize/1KB,2))KB (saved $savingsPercent%)" -ForegroundColor Green
    } else {
        Write-Host "ℹ️ No optimization possible for: $fileName" -ForegroundColor Yellow
    }
}

Write-Host "`nOptimization complete!" -ForegroundColor Green
Write-Host "Total space saved: $([math]::Round($totalSaved/1MB,2))MB" -ForegroundColor Green