@ECHO OFF

ECHO Converting %1 to 360 Panorama

REM Get Image Width
exiftool -b -ImageWidth %1 > %TEMP%\tmpFileW 
set /p width= < %TEMP%\tmpFileW
del %TEMP%\tmpFileW

REM Get Image Height
exiftool -b -ImageHeight %1  > %TEMP%\tmpFileH 
set /p height= < %TEMP%\tmpFileH
del %TEMP%\tmpFileH

REM Write EXIF/XMP Data
exiftool -v -ProjectionType="equirectangular" %1
exiftool -v -UsePanoramaViewer="True" %1
exiftool -v -Make="DJI" -Model="FC1102" %1

exiftool -v -CroppedAreaImageWidthPixels=%width% %1
exiftool -v -CroppedAreaImageHeightPixels=%height% %1
exiftool -v -FullPanoWidthPixels=%width% %1
exiftool -v -FullPanoHeightPixels=%height% %1
exiftool -v -CroppedAreaLeftPixels=0 %1
exiftool -v -CroppedAreaTopPixels=0 %1

PAUSE
