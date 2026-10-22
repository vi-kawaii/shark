@echo off
setlocal

for /r "%~1" %%f in (*.gd *.pln) do (
    echo %%f
    type "%%f"
)
