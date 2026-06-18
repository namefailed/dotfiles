# Tangle all literate configuration files automatically.
# Uses vanilla Emacs batch mode — org-babel-tangle needs no Doom hooks.
# Usage:
#   .\tangle-configs.ps1              # Tangle all configs
#   .\tangle-configs.ps1 -DryRun      # Preview what would be tangled
#   .\tangle-configs.ps1 -Validate   # Tangle and validate generated files

param(
    [Parameter(Mandatory = $false)]
    [string]$ConfigDir = "$env:USERPROFILE\.config",

    [Parameter(Mandatory = $false)]
    [switch]$DryRun = $false,

    [Parameter(Mandatory = $false)]
    [switch]$Validate = $false
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot '..\_lib\config-paths.ps1')

$emacsExe = Get-EmacsExecutable -Name emacs
if (-not $emacsExe) {
    Write-Error 'Emacs not found. Install Emacs or ensure it is on PATH.'
    exit 1
}
Write-Host "Using Emacs: $emacsExe" -ForegroundColor Green

# ── Find tangleable org files ──────────────────────────────────────────────────
# Exclude ~/.config/emacs entirely — Doom's internal directory contains hundreds
# of package README.org files that must never be tangled.
# Also exclude git internals and archived scripts.
$escapedConfig  = [regex]::Escape($ConfigDir)
$excludePattern = "$escapedConfig\\emacs\\|\\\.git\\|\\archive\\"
$tanglePattern  = '(?m)^\s*#\+PROPERTY:.*:tangle\s+(?!no\b)\S|^\s*:header-args(?::[A-Za-z0-9_-]+)?:.*:tangle\s+(?!no\b)\S|^\s*#\+begin_src\s[^\n]+:tangle\s+(?!no\b)\S'

$orgFiles = Get-ChildItem -Path $ConfigDir -Filter '*.org' -Recurse -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch $excludePattern } |
    Where-Object {
        $c = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
        # Match files with:
        #   - a global #+PROPERTY tangle header
        #   - a subtree :header-args...: drawer entry (e.g. kanata.org)
        #   - a src block with an explicit :tangle target
        # All variants ignore `:tangle no`.
        $c -match $tanglePattern
    }

if (-not $orgFiles) {
    Write-Warning "No .org files with :tangle found in $ConfigDir"
    exit 0
}

$label = if ($orgFiles.Count -eq 1) { '1 file' } else { "$($orgFiles.Count) files" }
Write-Host "Found $label to tangle:" -ForegroundColor Cyan
$orgFiles | ForEach-Object { Write-Host "  - $($_.FullName.Replace($ConfigDir, '~/.config'))" }
Write-Host ''

if ($DryRun) {
    Write-Host 'Dry run — no files were changed.' -ForegroundColor Yellow
    exit 0
}

# ── Tangle ─────────────────────────────────────────────────────────────────────
$successCount = 0
$failCount    = 0

foreach ($file in $orgFiles) {
    $rel = $file.FullName.Replace($ConfigDir, '~/.config')
    Write-Host "Tangling $rel..." -NoNewline

    $outputStr = Invoke-EmacsOrgTangle -EmacsExe $emacsExe -OrgPath $file.FullName
    $hasSuccess = $outputStr -match "Tangled \d+ code block"
    
    if ($hasSuccess) {
        if ($file.Name -eq 'kanata.org') {
            Repair-KanataTangledFiles -KanataDir (Split-Path $file.FullName -Parent)
        }
        Write-Host ' OK' -ForegroundColor Green
        $successCount++
    } elseif ($file.Name -eq 'qutebrowser.org' -and $outputStr -match "Tangled 0 code blocks") {
        # Emacs batch tangle fails for qutebrowser.org (org 9.7 parser bug).
        # Use PowerShell fallback extractor instead.
        Write-Host ' fallback...' -NoNewline -ForegroundColor Yellow
        $fallbackScript = Join-Path $PSScriptRoot 'tangle-fallback.ps1'
        $fallbackOut = & $fallbackScript -OrgFile $file.FullName -ConfigRoot $ConfigDir 2>&1
        if ($LASTEXITCODE -eq 0 -or -not $LASTEXITCODE) {
            Write-Host ' OK (fallback)' -ForegroundColor Cyan
            $successCount++
        } else {
            Write-Host " FAILED" -ForegroundColor Red
            $fallbackOut | Where-Object { $_ } | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkRed }
            $failCount++
        }
    } else {
        Write-Host " FAILED" -ForegroundColor Red
        $outputStr | Where-Object { $_ } | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkRed }
        $failCount++
    }
}

# ── Validate (optional) ────────────────────────────────────────────────────────
function Test-ConfigFile {
    param([string]$FilePath)

    $ext = [System.IO.Path]::GetExtension($FilePath).ToLower()
    $fileName = [System.IO.Path]::GetFileName($FilePath)

    switch ($ext) {
        '.kbd' {
            # Kanata syntax check
            $kanata = Get-Command kanata -ErrorAction SilentlyContinue
            if ($kanata) {
                $output = & kanata --debug -c $FilePath 2>&1
                if ($LASTEXITCODE -eq 0) { return $true }
                else {
                    Write-Host "    Kanata validation failed:" -ForegroundColor Red
                    $output | ForEach-Object { Write-Host "      $_" -ForegroundColor DarkRed }
                    return $false
                }
            } else {
                Write-Host "    ⚠ kanata not found, skipping validation" -ForegroundColor DarkYellow
                return $true
            }
        }
        '.ps1' {
            # PowerShell syntax check - use parser for better results
            $parseErrors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseFile($FilePath, [ref]$null, [ref]$parseErrors)
            if ($parseErrors.Count -eq 0) {
                # Also try PSScriptAnalyzer if available
                $pssa = Get-Module PSScriptAnalyzer -ListAvailable -ErrorAction SilentlyContinue
                if ($pssa) {
                    $issues = Invoke-ScriptAnalyzer -Path $FilePath -Severity Error -ErrorAction SilentlyContinue
                    if ($issues) {
                        Write-Host "    PSScriptAnalyzer found $($issues.Count) error(s)" -ForegroundColor Yellow
                        $issues | Select-Object -First 3 | ForEach-Object {
                            Write-Host "      Line $($_.Line): $($_.Message)" -ForegroundColor DarkYellow
                        }
                    }
                }
                return $true
            } else {
                Write-Host "    PowerShell parse errors:" -ForegroundColor Red
                $parseErrors | Select-Object -First 3 | ForEach-Object {
                    Write-Host "      Line $($_.Extent.StartLineNumber): $($_.Message)" -ForegroundColor DarkRed
                }
                return $false
            }
        }
        '.json' {
            # JSON syntax check with comment handling for jsonc files
            $content = Get-Content $FilePath -Raw
            
            # Check if it's a JSONC file (JSON with comments)
            if ($fileName -match '\.jsonc$' -or $content -match '^\s*//') {
                # Strip comments for validation
                $jsonContent = $content -replace '//.*$', '' -replace '/\*.*?\*/', ''
                try {
                    $jsonContent | ConvertFrom-Json | Out-Null
                    return $true
                } catch {
                    Write-Host "    JSONC parse error: $_" -ForegroundColor Red
                    return $false
                }
            } else {
                try {
                    $content | ConvertFrom-Json | Out-Null
                    return $true
                } catch {
                    Write-Host "    JSON parse error: $_" -ForegroundColor Red
                    return $false
                }
            }
        }
        '.toml' {
            # TOML validation - check for balanced brackets and basic structure
            $content = Get-Content $FilePath -Raw
            $lines = $content -split "`n"
            
            # Check for basic TOML patterns
            $hasTable = $content -match '^\s*\[.+\]'
            $hasKeyValue = $content -match '^\s*\w+\s*='
            
            if (-not $hasTable -and -not $hasKeyValue) {
                Write-Host "    ⚠ No TOML tables or key-value pairs found" -ForegroundColor DarkYellow
                return $true  # Warn but don't fail
            }
            
            # Check for bracket balance in table headers
            $tableHeaders = $lines | Where-Object { $_ -match '^\s*\[' }
            foreach ($header in $tableHeaders) {
                $open = ($header -match '\[').Count
                $close = ($header -match '\]').Count
                if ($open -ne $close) {
                    Write-Host "    Unbalanced brackets in: $header" -ForegroundColor Red
                    return $false
                }
            }
            
            return $true
        }
        default { return $true }  # Unknown extension, skip validation
    }
}

if ($Validate -and $successCount -gt 0) {
    Write-Host ''
    Write-Host 'Validating generated files...' -ForegroundColor Cyan

    # Find all files that were tangled (look for them in the same directories as .org files)
    $generatedFiles = $orgFiles | ForEach-Object {
        $dir = $_.DirectoryName
        # Look for common generated file patterns
        Get-ChildItem -Path $dir -File | Where-Object {
            $_.Extension -in @('.kbd', '.ps1', '.json', '.toml') -and
            $_.Name -notmatch '\.org$'
        }
    } | Select-Object -Unique

    $validCount = 0
    $invalidCount = 0

    foreach ($file in $generatedFiles) {
        Write-Host "  Validating $($file.Name)..." -NoNewline
        if (Test-ConfigFile $file.FullName) {
            Write-Host ' OK' -ForegroundColor Green
            $validCount++
        } else {
            Write-Host ' FAILED' -ForegroundColor Red
            $invalidCount++
        }
    }

    Write-Host ''
    Write-Host "Validation: $validCount passed, $invalidCount failed." -ForegroundColor $(if ($invalidCount -eq 0) { 'Green' } else { 'Yellow' })
}

Write-Host ''
$colour = if ($failCount -eq 0) { 'Green' } else { 'Yellow' }
Write-Host "Done: $successCount succeeded, $failCount failed." -ForegroundColor $colour
if ($failCount -gt 0) { exit 1 }
