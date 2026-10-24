cls
setlocal

set "ROOT=%~dp0"

for /R "%ROOT%src" %%F in (*) do (
    echo %%F
    type "%%F"
    echo.
)

endlocal
