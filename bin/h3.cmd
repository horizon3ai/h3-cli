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
