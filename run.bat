@echo off
setlocal

set "GODOT=%~dp0..\godot.exe"

"%GODOT%" --headless --path "%~dp0." --script "res://core/run/main.gd" -- %*

exit /b %ERRORLEVEL%
