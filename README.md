# Photo Workflow Scripts

A collection of PowerShell scripts for managing, organizing, and processing photos. These scripts help automate common photo management tasks including date-based organization, geotagging, EXIF data management, and optimization.

## Prerequisites

- Windows PowerShell 5.1 or later
- [ExifTool](https://exiftool.org/)
- [FileOptimizer](https://nikkhokkho.sourceforge.io/static.php?page=FileOptimizer)

- [GeoSetter](https://geosetter.de/en/main-en/) (optional, for manual manipulation afterwards)

## Scripts Overview

### Core Scripts

- **Sort-PhotosByDate.ps1**: Groups photos into folders based on their capture date
- **Rename-PhotosByDate.ps1**: Renames photos using their capture date and time
- **Set-PhotoExif.ps1**: Applies EXIF metadata (artist, copyright, contact info)
- **Set-PhotoGeoLocation.ps1**: Geotags photos using GPX tracks
- **Optimize-Photos.ps1**: Compresses photos using FileOptimizer

### Utility Scripts

- **Set-PhotoFileDates.ps1**: Updates file system dates to match photo capture dates
- **Set-PhotoFolderDates.ps1**: Sets folder dates based on contained photos
- **Fix-GeoSetterExifTool.ps1**: Updates GeoSetter's ExifTool installation
- **Set-Photo360Metadata.ps1**: Converts photos to 360° panoramas by setting appropriate metadata

## Configuration

1. Copy `PhotoExif.template.json` to `PhotoExif.config.json`
2. Edit `PhotoExif.config.json` with your personal information:
   ```json
   {
       "Artist": "Your Name",
       "Copyright": "Copyright © YEAR Your Name All Rights Reserved",
       "Phone": "Your Phone",
       "Email": "Your Email"
   }
   ```

## Usage Examples

### Organizing Photos by Date
```powershell
.\Sort-PhotosByDate.ps1 -Directory "C:\Photos" -IncludeDescription
```

### Geotagging Photos
```powershell
.\Set-PhotoGeoLocation.ps1 -Directory "C:\Photos\Vacation" -GpxBaseDirectory "C:\GPX\Tracks"
```

### Applying EXIF Data
```powershell
.\Set-PhotoExif.ps1 -Directory "C:\Photos\Event"
```

### Optimizing Photos
```powershell
.\Optimize-Photos.ps1 -Directory "C:\Photos\ToOptimize"
```

### Converting to 360° Panorama
```powershell
# Basic usage
.\Set-Photo360Metadata.ps1 -PhotoPath "C:\Photos\panorama.jpg"

# Force overwrite without backup
.\Set-Photo360Metadata.ps1 -PhotoPath "C:\Photos\panorama.jpg" -Force
```

## Notes

- All scripts include error handling and progress feedback
- Scripts use color-coded console output for better visibility
- Most scripts can process both JPG and JPEG file extensions
- All operations preserve original EXIF data unless explicitly modified

## License

This project is licensed under the MIT License - see the LICENSE file for details.