@echo off
setlocal

set GRAMMAR=D:\godot\shark\zed\plain\grammars\plain
set REPO=D:\godot\shark
set TREE_SITTER=D:\godot\shark\tree-sitter.exe

set MSG=%~1
if "%MSG%"=="" set MSG=update plain grammar

cd /d "%GRAMMAR%" || (echo [ERR] cd %GRAMMAR% & exit /b 1)

echo === tree-sitter generate ===
%TREE_SITTER% generate
if errorlevel 1 (echo [ERR] generate failed & exit /b 1)

echo === git commit ===
cd /d "%REPO%" || (echo [ERR] cd %REPO% & exit /b 1)
git add -A
git diff --cached --quiet && (echo nothing to commit & goto :done)

git commit -m "%MSG%"
if errorlevel 1 (echo [ERR] commit failed & exit /b 1)
git push

:done
endlocal
