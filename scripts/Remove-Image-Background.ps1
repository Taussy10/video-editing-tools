# ============================================================
#  Remove-Background.ps1  —  Auto AI Background Remover
#  Part of Custom-Capcut scripts collection
#  Usage: Right-click → Run with PowerShell
# ============================================================

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "       Auto AI Background Remover" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# -- Check dependencies ------------------------------------------------------
Write-Host "Checking for 'rembg' AI library..." -ForegroundColor Gray
$pythonCheck = python -c "import rembg" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Installing rembg (AI background removal tool)..." -ForegroundColor Yellow
    Write-Host "This might take a minute on the first run as it downloads the model." -ForegroundColor Gray
    pip install rembg[cli] --quiet
    Write-Host "Installed successfully!" -ForegroundColor Green
} else {
    Write-Host "rembg is already installed." -ForegroundColor Green
}
Write-Host ""

while ($true) {
    # -- Step 1: Get Image path --------------------------------------------------
    $imagePath = Read-Host "Enter your IMAGE path (or drag & drop)"
    $imagePath = $imagePath.Trim('"')

    if (-not (Test-Path $imagePath)) {
        Write-Host "[-] Image File not found: $imagePath" -ForegroundColor Red
    } else {
        $directory = Split-Path $imagePath -Parent
        $filename = [System.IO.Path]::GetFileNameWithoutExtension($imagePath)
        $outputPath = Join-Path $directory "$($filename)_nobg.png"

        Write-Host ""
        Write-Host "Input     : $imagePath" -ForegroundColor Gray
        Write-Host "Output    : $outputPath" -ForegroundColor Gray
        Write-Host ""

        # -- Step 2: Run AI background removal ---------------------------------------
        Write-Host "Removing background using AI... Please wait." -ForegroundColor Yellow

        # Use rembg cli
        $rembgArgs = @("i", $imagePath, $outputPath)
        & rembg @rembgArgs

        if ($LASTEXITCODE -eq 0 -and (Test-Path $outputPath)) {
            Write-Host ""
            $aggressive = Read-Host "Do you want to apply aggressive silhouette cleanup? (Removes fringes, turns shape solid black) [y/N]"
            if ($aggressive -eq 'y' -or $aggressive -eq 'Y') {
                Write-Host "Applying aggressive cleanup..." -ForegroundColor Yellow
                $pyScript = @"
import sys
try:
    from PIL import Image
    img = Image.open(r'$outputPath').convert('RGBA')
    data = img.getdata()
    new_data = []
    for item in data:
        # If it's already transparent, keep it
        if item[3] == 0:
            new_data.append(item)
            continue
        brightness = (item[0] + item[1] + item[2]) / 3
        if brightness > 150:
            new_data.append((255, 255, 255, 0))
        else:
            new_data.append((0, 0, 0, 255))
    img.putdata(new_data)
    img.save(r'$outputPath')
except Exception as e:
    print('Cleanup Error:', e)
"@
                python -c $pyScript
                Write-Host "Aggressive cleanup applied!" -ForegroundColor Green
            }

            Write-Host "============================================" -ForegroundColor Green
            Write-Host "   SUCCESS!" -ForegroundColor Green
            Write-Host "============================================" -ForegroundColor Green
            Write-Host ""
            Write-Host "Background removed successfully!" -ForegroundColor White
            Write-Host "Output saved to: $outputPath" -ForegroundColor Cyan
            Write-Host ""
        } else {
            Write-Host "Failed to remove background." -ForegroundColor Red
        }
    }

    Write-Host ""
    $continueChoice = Read-Host "Do you want to process another image? (y/N)"
    if ($continueChoice -notmatch "^[yY]$") {
        break
    }
}
