@echo off
setlocal

git add .
git commit

exit /b %ERRORLEVEL%
