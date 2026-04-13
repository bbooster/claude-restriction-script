@echo off
setlocal enabledelayedexpansion

net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -Command "Start-Process cmd -ArgumentList '/k \"%~f0\"' -Verb RunAs -Wait"
    exit /b
)

set HOSTS=C:\Windows\System32\drivers\etc\hosts
set BACKUP_DIR=C:\hosts_backups
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

for /f "delims=" %%I in ('powershell -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set DT=%%I

copy "%HOSTS%" "%BACKUP_DIR%\hosts.%DT%" >nul
if %errorLevel% neq 0 (
    echo ERROR: failed to backup hosts
    pause
    exit /b 1
)
echo Backup: %BACKUP_DIR%\hosts.%DT%

set ADDED=0
set SKIPPED=0

for %%D in (claude.ai www.claude.ai api.claude.ai anthropic.com www.anthropic.com api.anthropic.com console.anthropic.com cdn.anthropic.com statsig.anthropic.com sentry.anthropic.com amplitude.anthropic.com) do (
    findstr /i /r /c:"[	 ]%%D$" /c:"[	 ]%%D " "%HOSTS%" >nul 2>&1
    if !errorLevel! equ 0 (
        set /a SKIPPED+=1
        echo SKIP: %%D
    ) else (
        echo 192.0.2.1 %%D>>"%HOSTS%"
        set /a ADDED+=1
        echo ADD:  %%D
    )
)

ipconfig /flushdns >nul 2>&1

echo.
echo Done. Added: %ADDED%, skipped: %SKIPPED%
echo.
pause