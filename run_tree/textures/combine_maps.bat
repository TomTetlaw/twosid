@echo off
:: Check if the correct number of arguments is provided
if "%~5"=="" (
    echo Usage: pack_textures.bat roughness metallic ao height output
    exit /b 1
)

:: Assign input images and output filename to variables
set "roughness=%~1"
set "metallic=%~2"
set "ao=%~3"
set "height=%~4"
set "output=%~5"

:: Run ImageMagick with the provided images
magick ^
    ( "%roughness%" -colorspace RGB -channel R -separate ) ^
    ( "%metallic%" -colorspace RGB -channel R -separate ) ^
    ( "%ao%" -colorspace RGB -channel R -separate ) ^
    ( "%height%" -colorspace RGB -channel R -separate ) ^
    -combine ^
    "%output%"