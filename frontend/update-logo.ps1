# PowerShell script to convert and resize app logo for web deployment
Add-Type -AssemblyName System.Drawing

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourcePath = Join-Path $scriptDir "assets\images\app_logo.jpg"
$outputDir = Join-Path $scriptDir "web"

# Function to resize and save image
function Resize-Image {
    param(
        [System.Drawing.Image]$image,
        [string]$outputPath,
        [int]$width,
        [int]$height
    )
    
    # Ensure directory exists
    $dir = Split-Path -Parent $outputPath
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    
    $newImage = New-Object System.Drawing.Bitmap($width, $height)
    $graphics = [System.Drawing.Graphics]::FromImage($newImage)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.DrawImage($image, 0, 0, $width, $height)
    
    try {
        $newImage.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
        Write-Host "Created: $outputPath"
    } catch {
        Write-Host "Error saving: $outputPath - $_"
    } finally {
        $graphics.Dispose()
        $newImage.Dispose()
    }
}

# Load source image
if (-not (Test-Path $sourcePath)) {
    Write-Error "Source image not found: $sourcePath"
    exit 1
}

$sourceImage = [System.Drawing.Image]::FromFile($sourcePath)

Write-Host "Creating favicon.png..."
Resize-Image -image $sourceImage -outputPath (Join-Path $outputDir "favicon.png") -width 32 -height 32

Write-Host "Creating Icon-192.png..."
Resize-Image -image $sourceImage -outputPath (Join-Path $outputDir "icons\Icon-192.png") -width 192 -height 192

Write-Host "Creating Icon-512.png..."
Resize-Image -image $sourceImage -outputPath (Join-Path $outputDir "icons\Icon-512.png") -width 512 -height 512

Write-Host "Creating Icon-maskable-192.png..."
Resize-Image -image $sourceImage -outputPath (Join-Path $outputDir "icons\Icon-maskable-192.png") -width 192 -height 192

Write-Host "Creating Icon-maskable-512.png..."
Resize-Image -image $sourceImage -outputPath (Join-Path $outputDir "icons\Icon-maskable-512.png") -width 512 -height 512

$sourceImage.Dispose()
Write-Host "`nAll icons created successfully!"
