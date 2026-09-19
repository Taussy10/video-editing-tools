param(
    [string]$InputImage = "",
    [int]$BorderWidth = 15,
    [int]$ShadowOpacity = 50,
    [int]$ShadowSigma = 15
)

Write-Host "=== Stacked Image Generator ===" -ForegroundColor Cyan

function Generate-Stacked($path) {
    if (-not (Test-Path $path)) {
        Write-Host "File not found: $path" -ForegroundColor Red
        return
    }
    
    $OutputImage = [System.IO.Path]::ChangeExtension($path, "_stacked.png")

    $args = @(
        $path,
        "-bordercolor", "white",
        "-border", $BorderWidth,
        "(", "+clone", "-background", "black", "-shadow", "$($ShadowOpacity)x$($ShadowSigma)+0+15", ")",
        "+swap",
        "-background", "none",
        "-layers", "merge",
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
        Generate-Stacked $path
    }
    
    $firstRun = $false
    
    $choice = Read-Host "`nProcess another image? (Type 'y' for more, 'exit' to quit)"
    if ($choice -match "^(exit|n|no|quit)$") { break }
    if ($choice -notmatch "^(y|yes)$") { break }
}
