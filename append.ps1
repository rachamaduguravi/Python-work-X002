<#
.SYNOPSIS
    Appends system clipboard content into a target Markdown file in GitHub Flavored Markdown format.
    Scans for the first Markdown heading (# / ## / ###) and deletes all preceding lines before appending.
.PARAMETER TargetPath
    Path to the destination Markdown file.
.EXAMPLE
    .\append.ps1 -TargetPath "c:\raviWork\USBs\ravi07\Work\Python-work\R003\algotrader-backtest\antigravity.md"
#>
param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$TargetPath
)

# Ensure absolute path resolution
$resolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($TargetPath)
$parentDir = Split-Path -Path $resolvedPath -Parent

if (-not (Test-Path -Path $parentDir)) {
    New-Item -ItemType Directory -Force -Path $parentDir | Out-Null
}

# Fetch Clipboard Content
$clipLines = Get-Clipboard
if (-not $clipLines -or $clipLines.Count -eq 0) {
    Write-Warning "Clipboard is empty. Nothing to append."
    exit 0
}

# Find index of the first Markdown heading line starting with # (e.g. ### / ## / #)
$headingIndex = -1
for ($i = 0; $i -lt $clipLines.Count; $i++) {
    [string]$line = "$($clipLines[$i])".Trim()
    if ($line -match '^\s*#{1,6}\s+') {
        $headingIndex = $i
        break
    }
}

$startIndex = 0
if ($headingIndex -ge 0) {
    $startIndex = $headingIndex
    Write-Host "Found Markdown section header at line $($headingIndex + 1). Trimming all preceding lines." -ForegroundColor Cyan
} else {
    # Fallback: Filter out initial noise lines if no # heading found
    $noisePatterns = @(
        '^Viewed\s+', '^Ran command:', '^Used tool:', '^Command:', '^CWD:',
        '^The command exited with code', '^Output:', '^Created At:',
        '^Total Lines:', '^Total Bytes:', '^File Path:', '^\s*$'
    )
    for ($i = 0; $i -lt $clipLines.Count; $i++) {
        [string]$line = "$($clipLines[$i])".Trim()
        $isNoise = $false
        foreach ($pattern in $noisePatterns) {
            if ($line -match $pattern) {
                $isNoise = $true
                break
            }
        }
        if (-not $isNoise) {
            $startIndex = $i
            break
        }
    }
}

# Extract clean lines starting from the first section / markdown line
$cleanLines = @()
if ($startIndex -lt $clipLines.Count) {
    $cleanLines = $clipLines[$startIndex..($clipLines.Count - 1)]
}

function Sanitize-MermaidBlock {
    param ([string]$markdownText)

    $lines = $markdownText -split "\r?\n"
    $inMermaid = $false
    $outLines = @()
    $sgIndex = 1

    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        if ($trimmed -match '^```\s*mermaid') {
            $inMermaid = $true
            $outLines += $line
            continue
        }
        if ($inMermaid -and $trimmed -match '^```') {
            $inMermaid = $false
            $outLines += $line
            continue
        }

        if ($inMermaid) {
            $fixed = $line

            # 1. Fix subgraph headers with spaces, parentheses, or & symbols
            if ($fixed -match '^\s*subgraph\s+([^"\[\n]+)$') {
                $rawTitle = $matches[1].Trim()
                if ($rawTitle -and $rawTitle -notmatch '^\S+\s+\[') {
                    $fixed = $line -replace 'subgraph\s+.*', "subgraph sg_$sgIndex [`"$rawTitle`"]"
                    $sgIndex++
                }
            }

            # 2. Replace unsupported <-->|label| or <--> with clean --- operator
            $fixed = $fixed -replace '<-->\|[^|]*\|', '---'
            $fixed = $fixed -replace '<-->', '---'

            $outLines += $fixed
        } else {
            $outLines += $line
        }
    }

    return ($outLines -join "`n")
}

$cleanText = ($cleanLines -join "`n").Trim()

# Auto-sanitize Mermaid diagram syntax for Mermaid 9.4.0 compatibility
$cleanText = Sanitize-MermaidBlock -markdownText $cleanText

if ([string]::IsNullOrWhiteSpace($cleanText)) {
    Write-Warning "Clipboard contained no valid Markdown content after cleaning."
    exit 0
}

# Prepare GitHub Flavored Markdown Section Block (single divider)
$mdAppendBlock = "`n`n---`n`n" + $cleanText + "`n"

# Append to File (create if doesn't exist)
Add-Content -Path $resolvedPath -Value $mdAppendBlock -Encoding UTF8

Write-Host "Successfully cleaned and appended clipboard content to: $resolvedPath" -ForegroundColor Green
