@echo off
setlocal

git add .
git commit
git push

exit /b %ERRORLEVEL%
