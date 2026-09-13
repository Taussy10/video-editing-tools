# ============================================================
#  remove_silence.ps1  —  Remove Silence from Audio
#  Part of Custom-Capcut scripts collection
#  Usage: Right-click → Run with PowerShell
# ============================================================

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "         Remove Silence from Audio" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# -- Step 1: Get audio path --------------------------------------------------
$audioPath = Read-Host "Enter your audio file path (or drag & drop)"
$audioPath = $audioPath.Trim('"')

if (-not (Test-Path $audioPath)) {
    Write-Host "[-] File not found: $audioPath" -ForegroundColor Red
    pause
    exit 1
}

# -- Step 2: Optional parameters ---------------------------------------------
Write-Host ""
Write-Host "Optional settings (press Enter to use defaults):" -ForegroundColor Gray

$minSilenceInput = Read-Host "  Min silence length in ms      (default: 500)"
$minSilenceInput = $minSilenceInput.Trim()
if ($minSilenceInput -eq "") { $minSilence = 500 } else { $minSilence = [int]$minSilenceInput }

$thresholdInput = Read-Host "  Silence threshold in dBFS      (default: -40)"
$thresholdInput = $thresholdInput.Trim()
if ($thresholdInput -eq "") { $threshold = -40 } else { $threshold = [int]$thresholdInput }

$keepSilenceInput = Read-Host "  Silence to keep at edges in ms (default: 150)"
$keepSilenceInput = $keepSilenceInput.Trim()
if ($keepSilenceInput -eq "") { $keepSilence = 150 } else { $keepSilence = [int]$keepSilenceInput }

# -- Step 3: Build output path -----------------------------------------------
$audioDir  = Split-Path $audioPath -Parent
$audioFile = Split-Path $audioPath -Leaf
$basename  = [System.IO.Path]::GetFileNameWithoutExtension($audioFile)
$extension = [System.IO.Path]::GetExtension($audioFile)
$outputPath = Join-Path $audioDir "${basename}-rs${extension}"

Write-Host ""
Write-Host "File      : $audioPath"     -ForegroundColor Gray
Write-Host "Output    : $outputPath"    -ForegroundColor Gray
Write-Host "Min Silence: ${minSilence}ms"  -ForegroundColor Gray
Write-Host "Threshold : ${threshold} dBFS" -ForegroundColor Gray
Write-Host "Keep Silence: ${keepSilence}ms" -ForegroundColor Gray
Write-Host ""

# -- Step 4: Run the Python script -------------------------------------------
Write-Host "Processing audio..." -ForegroundColor Yellow

$scriptPath = Join-Path $PSScriptRoot "remove_silence.py"
$pythonExe = "E:\Tausif\Python\python.exe"

if (Test-Path $pythonExe) {
    & $pythonExe "$scriptPath" "$audioPath" "$outputPath" --min_silence $minSilence --threshold $threshold --keep_silence $keepSilence
} else {
    python "$scriptPath" "$audioPath" "$outputPath" --min_silence $minSilence --threshold $threshold --keep_silence $keepSilence
}

Write-Host ""
if ($LASTEXITCODE -eq 0) {
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "   SUCCESS!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Output saved to:" -ForegroundColor White
    Write-Host "   $outputPath" -ForegroundColor Cyan
} else {
    Write-Host "============================================" -ForegroundColor Red
    Write-Host "   ERROR: Something went wrong." -ForegroundColor Red
    Write-Host "============================================" -ForegroundColor Red
    Write-Host "Make sure 'pydub' and 'ffmpeg' are installed:" -ForegroundColor Yellow
    Write-Host "   pip install pydub" -ForegroundColor Yellow
    Write-Host "   winget install ffmpeg   (or add ffmpeg to PATH)" -ForegroundColor Yellow
}

Write-Host ""
pause
