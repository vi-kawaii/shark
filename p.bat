cls
set "GODOT=%~dp0..\godot.exe"
"%GODOT%" --headless --path "%~dp0." --script "%~dp0p.gd"
exit /b %ERRORLEVEL%