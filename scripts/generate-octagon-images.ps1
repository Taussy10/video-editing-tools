param(
    [string]$InputImage = "",
    [int]$Size = 400,
    [int]$BorderWidth = 10,
    [string]$BorderColor = "white"
)

Write-Host "=== Octagon Image Generator ===" -ForegroundColor Cyan

function Generate-Octagon($path) {
    if (-not (Test-Path $path)) {
        Write-Host "File not found: $path" -ForegroundColor Red
        return
    }
    
    $OutputImage = [System.IO.Path]::ChangeExtension($path, "_octagon.png")
    
    $cut = [math]::Round($Size * 0.29289)
    $rem = $Size - $cut
    $poly = "polygon $cut,0 $rem,0 $Size,$cut $Size,$rem $rem,$Size $cut,$Size 0,$rem 0,$cut"

    $args = @(
        $path,
        "-resize", "$($Size)x$($Size)^",
        "-gravity", "center",
        "-crop", "$($Size)x$($Size)+0+0",
        "+repage",
        "(", "-size", "$($Size)x$($Size)", "xc:none", "-fill", "white", "-draw", $poly, ")",
        "-alpha", "off",
        "-compose", "CopyOpacity", "-composite",
        "-stroke", $BorderColor,
        "-strokewidth", $BorderWidth,
        "-fill", "none",
        "-draw", $poly,
        $OutputImage
    )

    & magick @args

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Success: Saved to $OutputImage" -ForegroundColor Green
    } else {
        Write-Host "Failed to process image." -ForegroundColor Red
    }
}

$firstRun = $true
while ($true) {
    if ($firstRun -and $InputImage) {
        $path = $InputImage
    } else {
        if ($firstRun) {
            $path = Read-Host "`nEnter image path"
        } else {
            $path = Read-Host "`nEnter next image path"
        }
        $path = $path.Trim('"').Trim("'")
    }
    
    if ($path) {
        Generate-Octagon $path
    }
    
    $firstRun = $false
    
    $choice = Read-Host "`nProcess another image? (Type 'y' for more, 'exit' to quit)"
    if ($choice -match "^(exit|n|no|quit)$") { break }
    if ($choice -notmatch "^(y|yes)$") { break }
}
