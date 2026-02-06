<#
.SYNOPSIS
    Installs or upgrades h3-cli on Windows.

.DESCRIPTION
    This script downloads h3-cli and configures the environment.
    It installs jq, sets up the profile, and adds the bin directory to the PATH.

.PARAMETER ApiKey
    The Horizon3 API Key.

.PARAMETER RunnerName
    The name of the NodeZero Runner to start (optional).

.PARAMETER H3Env
    The Horizon3 environment (e.g., prod, prod_eu).

.PARAMETER H3DownloadUrl
    Custom URL to download the h3-cli zip.

.EXAMPLE
    .\easy_install.ps1 -ApiKey "your-api-key"
#>

param(
    [string]$ApiKey,
    [string]$RunnerName,
    [string]$H3Env,
    [string]$H3DownloadUrl
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$Timestamp] $Message"
}

function Write-ErrorLog {
    param([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Error "[$Timestamp] $Message"
}

# --- Configuration ---

# Determine H3_CLI_HOME
if ($env:H3_CLI_HOME) {
    $H3CliHome = $env:H3_CLI_HOME
}
else {
    $H3CliHome = Join-Path $env:USERPROFILE "h3-cli"
}

$H3GlobalEnv = Join-Path $env:USERPROFILE ".h3\__global__.env"
$H3Dir = Join-Path $env:USERPROFILE ".h3"

# Ensure .h3 directory exists
if (-not (Test-Path $H3Dir)) {
    New-Item -ItemType Directory -Path $H3Dir -Force | Out-Null
}

# Handle H3DownloadUrl persistence
if ($H3DownloadUrl) {
    $env:H3_CLI_DOWNLOAD_URL = $H3DownloadUrl
    "H3_CLI_DOWNLOAD_URL=$H3DownloadUrl" | Out-File -FilePath $H3GlobalEnv -Encoding utf8
}
elseif (Test-Path $H3GlobalEnv) {
    # Load existing config
    Get-Content $H3GlobalEnv | ForEach-Object {
        if ($_ -match "^(.*?)=(.*)$") {
            Set-Item -Path "env:$($matches[1])" -Value $matches[2]
        }
    }
}

# --- Download h3-cli ---

Write-Log "INFO: Installing h3-cli into $H3CliHome ..."

if (-not (Test-Path $H3CliHome)) {
    New-Item -ItemType Directory -Path $H3CliHome -Force | Out-Null
}

$Downloaded = $false

# Method 1: Custom Download URL (Zip)
if ($env:H3_CLI_DOWNLOAD_URL) {
    Write-Log "INFO: Downloading via custom URL: $($env:H3_CLI_DOWNLOAD_URL)"
    $ZipPath = Join-Path $env:TEMP "h3-cli.zip"
    try {
        Invoke-WebRequest -Uri $env:H3_CLI_DOWNLOAD_URL -OutFile $ZipPath
        Expand-Archive -Path $ZipPath -DestinationPath $H3CliHome -Force
        # Handle potential subfolder from zip
        $SubItems = Get-ChildItem -Path $H3CliHome -Directory
        if ($SubItems.Count -eq 1 -and (Test-Path (Join-Path $SubItems[0].FullName "bin"))) {
            Move-Item -Path (Join-Path $SubItems[0].FullName "*") -Destination $H3CliHome -Force
            Remove-Item -Path $SubItems[0].FullName -Recurse -Force
        }
        $Downloaded = $true
    }
    catch {
        Write-ErrorLog "ERROR: Failed to download from $($env:H3_CLI_DOWNLOAD_URL)"
        exit 1
    }
}

# Method 2: Git
if (-not $Downloaded) {
    if (Get-Command git -ErrorAction SilentlyContinue) {
        if (Test-Path (Join-Path $H3CliHome ".git")) {
            Write-Log "INFO: Updating via git pull..."
            Push-Location $H3CliHome
            git pull
            Pop-Location
            $Downloaded = $true
        }
        else {
            # Try cloning if empty or not a repo
            if ((Get-ChildItem $H3CliHome).Count -eq 0) {
                Write-Log "INFO: Cloning via git..."
                git clone https://github.com/horizon3ai/h3-cli.git $H3CliHome
                $Downloaded = $true
            }
        }
    }
}

# Method 3: Public Zip Fallback
if (-not $Downloaded) {
    Write-Log "INFO: Downloading public release zip..."
    $ZipUrl = "https://github.com/horizon3ai/h3-cli/archive/refs/heads/public.zip"
    $ZipPath = Join-Path $env:TEMP "h3-cli-public.zip"
    try {
        Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipPath
        # Expand to temp first to handle folder structure
        $TempExtract = Join-Path $env:TEMP "h3-cli-extract"
        if (Test-Path $TempExtract) { Remove-Item $TempExtract -Recurse -Force }
        Expand-Archive -Path $ZipPath -DestinationPath $TempExtract -Force
        
        # Move contents
        $SourceDir = Join-Path $TempExtract "h3-cli-public"
        Copy-Item -Path (Join-Path $SourceDir "*") -Destination $H3CliHome -Recurse -Force
        
        Remove-Item $TempExtract -Recurse -Force
        Remove-Item $ZipPath -Force
        $Downloaded = $true
    }
    catch {
        Write-ErrorLog "ERROR: Failed to download public zip."
        exit 1
    }
}

# --- Install Dependencies (jq) ---

$BinDir = Join-Path $H3CliHome "bin"
if (-not (Test-Path $BinDir)) { New-Item -ItemType Directory -Path $BinDir -Force | Out-Null }

Write-Log "INFO: Checking for jq..."
$JqPath = Join-Path $BinDir "jq.exe"
if (-not (Test-Path $JqPath)) {
    Write-Log "INFO: Downloading jq for Windows..."
    $JqUrl = "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-win64.exe"
    try {
        Invoke-WebRequest -Uri $JqUrl -OutFile $JqPath
    } catch {
        Write-ErrorLog "ERROR: Failed to download jq."
        Write-Host "Please install jq manually and place it in $BinDir"
    }
}

# --- Create Windows Wrappers ---
Write-Log "INFO: Creating Windows wrappers..."

$H3CmdPath = Join-Path $BinDir "h3.cmd"
$H3CmdContent = @"
@echo off
setlocal

REM Try to find Git Bash in standard locations
if exist "%ProgramFiles%\Git\bin\bash.exe" (
    set "BASH=%ProgramFiles%\Git\bin\bash.exe"
    goto :Found
)
if exist "%ProgramFiles(x86)%\Git\bin\bash.exe" (
    set "BASH=%ProgramFiles(x86)%\Git\bin\bash.exe"
    goto :Found
)

REM Fallback to PATH bash
WHERE bash >nul 2>nul
IF %ERRORLEVEL% EQU 0 (
    set "BASH=bash"
    goto :Found
)

ECHO bash.exe not found. Please install Git Bash.
EXIT /B 1

:Found
SET "SCRIPT_DIR=%~dp0"
SET "SCRIPT_PATH=%SCRIPT_DIR%h3"
SET "SCRIPT_PATH=%SCRIPT_PATH:\=/%"

"%BASH%" "%SCRIPT_PATH%" %*
EXIT /B %ERRORLEVEL%
"@
$H3CmdContent | Out-File -FilePath $H3CmdPath -Encoding ascii -Force

$H3Ps1Path = Join-Path $BinDir "h3.ps1"
$H3Ps1Content = @"
<#
.SYNOPSIS
    Wrapper to run the h3 bash CLI on Windows.
#>
`$ScriptPath = Join-Path `$PSScriptRoot "h3"
`$ScriptPath = `$ScriptPath.Replace("\", "/")

`$BashPath = "bash"
if (Test-Path "`$env:ProgramFiles\Git\bin\bash.exe") {
    `$BashPath = "`$env:ProgramFiles\Git\bin\bash.exe"
} elseif (Test-Path "`$env:ProgramFiles(x86)\Git\bin\bash.exe") {
    `$BashPath = "`$env:ProgramFiles(x86)\Git\bin\bash.exe"
} elseif (-not (Get-Command bash -ErrorAction SilentlyContinue)) {
    Write-Error "bash.exe not found. Please install Git Bash."
    exit 1
}

& "`$BashPath" "`$ScriptPath" @args
exit `$LASTEXITCODE
"@
$H3Ps1Content | Out-File -FilePath $H3Ps1Path -Encoding utf8 -Force

# --- Configuration (Profile) ---

if ($ApiKey) {
    $ProfileName = if ($env:H3_CLI_PROFILE) { $env:H3_CLI_PROFILE } else { "default" }
    $ProfileFile = Join-Path $H3Dir "$ProfileName.env"
    
    Write-Log "INFO: Configuring profile '$ProfileName'..."
    
$ConfigContent = @("H3_API_KEY=$ApiKey")
    
# Determine URLs based on Env
$AuthUrl = ""
$GqlUrl = ""
    
if ($H3Env) {
    switch ($H3Env) {
        "prod" {
            $AuthUrl = "https://api.horizon3ai.com/v1/auth"
            $GqlUrl = "https://api.horizon3ai.com/v1/graphql"
        }
        "prod_eu" {
            $AuthUrl = "https://api.horizon3ai.eu/v1/auth"
            $GqlUrl = "https://api.horizon3ai.eu/v1/graphql"
        }
        "fh-prod" {
            $AuthUrl = "https://api.gov-horizon3ai.com/v1/auth"
            $GqlUrl = "https://api.gov-horizon3ai.com/v1/graphql"
        }
        "us" {
            $AuthUrl = "https://api.gateway.horizon3ai.com/v1/auth"
            $GqlUrl = "https://api.gateway.horizon3ai.com/v1/graphql"
        }
        "eu" {
            $AuthUrl = "https://api.gateway.horizon3ai.eu/v1/auth"
            $GqlUrl = "https://api.gateway.horizon3ai.eu/v1/graphql"
        }
        "fed-fh" {
            $AuthUrl = "https://api.gov-horizon3ai.com/v1/auth"
            $GqlUrl = "https://api.gov-horizon3ai.com/v1/graphql"
        }
        Default {
            if ($H3Env -like "https://api*") {
                $CleanEnv = $H3Env.TrimEnd('/')
                $AuthUrl = "$CleanEnv/v1/auth"
                $GqlUrl = "$CleanEnv/v1/graphql"
            }
        }
    }
}
    
if ($AuthUrl) { $ConfigContent += "H3_AUTH_URL=$AuthUrl" }
if ($GqlUrl) { $ConfigContent += "H3_GQL_URL=$GqlUrl" }
    
$ConfigContent | Out-File -FilePath $ProfileFile -Encoding utf8
}
elseif (-not (Test-Path (Join-Path $H3Dir "default.env"))) {
    Write-Host "`n[!] ACTION REQUIRED: No API Key provided."
    Write-Host "    Run: .\easy_install.ps1 -ApiKey <YOUR_KEY>"
}

# --- Path Configuration ---

$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($UserPath -notlike "*$BinDir*") {
    Write-Log "INFO: Adding $BinDir to User PATH..."
    [Environment]::SetEnvironmentVariable("Path", "$UserPath;$BinDir", "User")
    $env:Path += ";$BinDir"
    Write-Host "    NOTE: You may need to restart your terminal for PATH changes to take effect."
}

# --- Verification ---

Write-Log "INFO: Installation complete. Verifying..."
try {
    $H3Cmd = Join-Path $BinDir "h3.cmd"
    if (Test-Path $H3Cmd) {
        & $H3Cmd version
        Write-Log "INFO: Verification successful!"
    }
    else {
        Write-ErrorLog "WARNING: h3.cmd not found in $BinDir"
    }
}
catch {
    Write-ErrorLog "WARNING: Verification failed. You may need to restart your terminal."
    Write-ErrorLog $_.Exception.Message
}

Write-Host "`n[!] IMPORTANT: You must restart your terminal (or reload your profile) to use the 'h3' command."

if ($RunnerName) {
    Write-Log "INFO: Starting runner '$RunnerName'..."
    # Call h3 start-runner logic here
    # & h3 start-runner "$RunnerName"
    Write-Host "    Runner start logic to be implemented depending on h3 windows support."
}
