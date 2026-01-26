# Array of packages to install
$packages = @(
    "OliverBetz.ExifTool",
    "Nikkho.FileOptimizer"
    # Add more packages as needed
)

Write-Host "🔍 Checking package status..." -ForegroundColor Cyan

# Function to install or update a package
function Install-WingetPackage {
    param (
        [string]$packageId
    )
    
    Write-Host "`n📦 Processing $packageId... " -ForegroundColor White -NoNewline
    
    # Check if package is installed
    $checkResult = winget list --id $packageId --accept-source-agreements 2>$null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Installed" -ForegroundColor Green
        Write-Host "   🔄 Checking for updates..." -ForegroundColor Cyan
        
        # Try to upgrade
        winget upgrade --id $packageId --accept-source-agreements 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ✅ Update successful!" -ForegroundColor Green
        } elseif ($LASTEXITCODE -eq -1978335189) {
            # This specific exit code means "No available upgrade found"
            Write-Host "   ✨ Already up to date!" -ForegroundColor Green
        } else {
            Write-Host "   ❌ Update failed" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ Not installed" -ForegroundColor Red
        Write-Host "   📥 Installing package..." -ForegroundColor Cyan
        winget install --id $packageId --accept-source-agreements
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ✅ Installation successful!" -ForegroundColor Green
        } else {
            Write-Host "   ❌ Installation failed" -ForegroundColor Red
        }
    }
}

# Process each package
foreach ($package in $packages) {
    Install-WingetPackage -packageId $package
}

Write-Host "`n✨ Package management process completed! ✨" -ForegroundColor Green