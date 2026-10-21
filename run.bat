@echo off
setlocal

set "GODOT=%~dp0..\godot.exe"

"%GODOT%" --path "%~dp0."

exit /b %ERRORLEVEL%
