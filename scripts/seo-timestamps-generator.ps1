# ============================================================
#  seo-timestamps-generator.ps1  —  AI SEO Timestamps Generator
#  Part of Custom-Capcut scripts collection
#  Usage: Right-click → Run with PowerShell
# ============================================================

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "      SEO Timestamps Generator (AI Based)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$jsonPath = Read-Host "Enter path to timestamp-audio.json (or drag & drop)"
$jsonPath = $jsonPath.Trim('"')

if (-not (Test-Path $jsonPath)) {
    Write-Host "[-] File not found: $jsonPath" -ForegroundColor Red
    pause
    exit 1
}

$apiKey = $env:GEMINI_API_KEY
if ([string]::IsNullOrWhiteSpace($apiKey)) {
    $apiKey = Read-Host "Enter your Gemini API Key (or set GEMINI_API_KEY env var)"
    if ([string]::IsNullOrWhiteSpace($apiKey)) {
        Write-Host "[-] API Key is required!" -ForegroundColor Red
        pause
        exit 1
    }
}

Write-Host "`n[*] Reading JSON and constructing transcript for AI..." -ForegroundColor Yellow
$json = Get-Content $jsonPath -Raw | ConvertFrom-Json

# Construct transcript with periodic timestamps
$transcript = ""
$currentTime = 0

foreach ($wordObj in $json.words) {
    if ($transcript -eq "") {
        $transcript += "[0:00] "
    }
    
    # Insert a timestamp every 15 seconds to give the AI context of time
    if (($wordObj.start - $currentTime) -ge 15) {
        $minutes = [math]::Floor($wordObj.start / 60)
        $seconds = [math]::Floor($wordObj.start % 60)
        $transcript += "`n[$minutes:$($seconds.ToString('00'))] "
        $currentTime = $wordObj.start
    }
    
    $transcript += $wordObj.word + " "
}

$prompt = @"
You are an expert YouTube SEO specialist. I will provide you with a video transcript that has timestamp markers [m:ss] periodically. 
Your task is to generate title-based, SEO-friendly YouTube chapters (timestamps) for this video.

Rules:
1. The format MUST be exactly `mm:ss - Chapter Title`
2. You MUST start with `00:00 - Intro`.
3. You MUST end with a chapter for `Outro`.
4. Create around 6-12 chapters depending on the length of the transcript.
5. The titles should be topic-based and engaging (e.g., 'Economy & Wealth', 'The Himalayas'), not just a summary of facts.
6. DO NOT output any other text or markdown, just the timestamps.

Transcript:
$transcript
"@

Write-Host "[*] Calling Gemini API..." -ForegroundColor Yellow

$body = @{
    contents = @(
        @{
            parts = @(
                @{ text = $prompt }
            )
        }
    )
    generationConfig = @{
        temperature = 0.7
    }
} | ConvertTo-Json -Depth 10

$uri = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey"

try {
    # Specify TLS 1.2 just in case
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    $response = Invoke-RestMethod -Uri $uri -Method Post -Body $body -ContentType "application/json"
    $generatedText = $response.candidates[0].content.parts[0].text.Trim()
    
    Write-Host "`n============================================" -ForegroundColor Green
    Write-Host "         Generated SEO Timestamps" -ForegroundColor Green
    Write-Host "============================================`n"
    
    Write-Host $generatedText -ForegroundColor White
    
    $outPath = Join-Path (Split-Path $jsonPath) "seo-timestamps.txt"
    $generatedText | Set-Content $outPath -Encoding UTF8
    Write-Host "`n[*] Saved successfully to: $outPath" -ForegroundColor Cyan
}
catch {
    Write-Host "`n[-] API request failed!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    if ($_.ErrorDetails) {
        Write-Host $_.ErrorDetails.Message -ForegroundColor Red
    }
}

Write-Host ""
pause
