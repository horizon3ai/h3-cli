<#
.SYNOPSIS
    Wrapper to run the h3 bash CLI on Windows.
#>
$ScriptPath = Join-Path $PSScriptRoot "h3"
$ScriptPath = $ScriptPath.Replace("\", "/")

$BashPath = "bash"
if (Test-Path "$env:ProgramFiles\Git\bin\bash.exe") {
    $BashPath = "$env:ProgramFiles\Git\bin\bash.exe"
} elseif (Test-Path "$env:ProgramFiles(x86)\Git\bin\bash.exe") {
    $BashPath = "$env:ProgramFiles(x86)\Git\bin\bash.exe"
} elseif (-not (Get-Command bash -ErrorAction SilentlyContinue)) {
    Write-Error "bash.exe not found. Please install Git Bash."
    exit 1
}

& "$BashPath" "$ScriptPath" @args
exit $LASTEXITCODE
