@echo off
echo Building and running MedMinder in the Connect IQ simulator...
powershell -ExecutionPolicy Bypass -File "%~dp0build.ps1" -Run
pause
